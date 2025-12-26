{-# LANGUAGE OverloadedRecordDot #-}

module CardPG.Server.Presenter
  ( eventToLogs
  , mkChatLog
  ) where

import Data.Map qualified as Map
import Data.Maybe (fromMaybe)
import Data.Text (Text)
import Data.Text qualified as T
import Data.UUID (toText)

import CardPG.Api.Frontend
  ( ActionStack (..)
  , GameEvent (..)
  , PlannedAction (..)
  )
import CardPG.Api.Frontend qualified as Frontend
import CardPG.Core.Card (Identified (..))
import CardPG.Core.NonEmptyText (getRawText)
import CardPG.Core.Primitives (ActorId (..))
import CardPG.Core.State
  ( ActorState (..)
  , CoreCardState (..)
  , RevealedEffect (..)
  )
import CardPG.Server.Types
  ( GameState (..)
  , LogEntry (..)
  , LogPayload (..)
  )

mkChatLog :: Int -> Int -> Maybe ActorId -> Text -> Text -> LogEntry
mkChatLog ts seqNum senderId senderName content =
  LogEntry
    { id = T.pack $ show ts <> "-chat-" <> show seqNum
    , timestamp = ts
    , sender = senderName
    , senderId = senderId
    , payload = LogChat content
    }

eventToLogs :: Int -> Int -> ActorId -> GameEvent -> GameState -> [LogEntry]
eventToLogs ts idx actorId event game =
  let actorName = case Map.lookup actorId game.actors of
        Just a -> a.name
        Nothing -> "Unknown"

      mkId suffix = T.pack $ show ts <> "-" <> T.unpack (toText (let ActorId uid = actorId in uid)) <> "-idx" <> show idx <> "-" <> suffix

      mkLog suffix payload =
        LogEntry
          { id = mkId suffix
          , timestamp = ts
          , sender = "System"
          , senderId = Just actorId
          , payload = payload
          }
   in case event of
        ActionRevealed plan effect -> case effect of
          REChallenge challenge ->
            [mkLog "challenge" (LogChallenge challenge plan)]
          REPass -> [mkLog "pass" (LogInfo $ actorName <> " passed.")]
          REInvalid msg -> [mkLog "invalid" (LogInfo $ "Invalid Action for " <> actorName <> ": " <> msg)]
        IllegalAction _ (Just reason) -> [mkLog "illegal" (LogInfo $ "Illegal Action for " <> actorName <> ": " <> reason)]
        CardDrawn _ -> [mkLog "draw" (LogInfo $ actorName <> " drew a card.")]
        CardDefended _ ->
          [mkLog "defend" (LogDefense actorId False Nothing)]
        DefenseEnded stack ->
          let names = [getRawText c.name | c <- stack]
           in [mkLog "end-defend" (LogDefense actorId True (Just names))]
        DeckShuffled -> [mkLog "shuffle" (LogInfo $ actorName <> " reshuffled their deck.")]
        ConsequenceAdded _ -> [mkLog "cons-add" (LogInfo $ actorName <> " gained a consequence.")]
        ConsequenceRemoved _ -> [mkLog "cons-rem" (LogInfo $ actorName <> " removed consequence.")]
        StatusAdded st dest ->
          [mkLog "stat-add" (LogInfo $ actorName <> " added status " <> st <> " to " <> T.pack (show dest))]
        StatusRemoved st dest -> [mkLog "stat-rem" (LogInfo $ actorName <> " removed status " <> st <> " from " <> dest)]
        PlanCanceled _ -> [mkLog "cancel" (LogInfo $ actorName <> " canceled their plan.")]
        ActorMoved _ -> [mkLog "move" (LogInfo $ actorName <> " moved.")]
        _ -> []
