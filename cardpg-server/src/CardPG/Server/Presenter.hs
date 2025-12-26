{-# LANGUAGE OverloadedRecordDot #-}

module CardPG.Server.Presenter
  ( eventToLogs
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

eventToLogs :: ActorId -> GameEvent -> GameState -> [(LogPayload, Maybe ActorId)]
eventToLogs actorId event game =
  let actorName = case Map.lookup actorId game.actors of
        Just a -> a.name
        Nothing -> "Unknown"

      mkSystemLog payload = (payload, Just actorId)
   in case event of
        ActionRevealed plan effect -> case effect of
          REChallenge challenge ->
            [mkSystemLog (LogChallenge challenge plan)]
          REPass -> [mkSystemLog (LogInfo $ actorName <> " passed.")]
          REInvalid msg -> [mkSystemLog (LogInfo $ "Invalid Action for " <> actorName <> ": " <> msg)]
        IllegalAction (Frontend.IllegalActionDetails _ (Just reason)) -> [mkSystemLog (LogError $ "Illegal Action for " <> actorName <> ": " <> reason)]
        CardDrawn _ -> [mkSystemLog (LogInfo $ actorName <> " drew a card.")]
        CardDefended _ ->
          [mkSystemLog (LogDefense actorId False Nothing)]
        DefenseEnded stack ->
          let names = [getRawText c.name | c <- stack]
           in [mkSystemLog (LogDefense actorId True (Just names))]
        DeckShuffled -> [mkSystemLog (LogInfo $ actorName <> " reshuffled their deck.")]
        ConsequenceAdded _ -> [mkSystemLog (LogInfo $ actorName <> " gained a consequence.")]
        ConsequenceRemoved _ -> [mkSystemLog (LogInfo $ actorName <> " removed consequence.")]
        StatusAdded st dest ->
          [mkSystemLog (LogInfo $ actorName <> " added status " <> st <> " to " <> T.pack (show dest))]
        StatusRemoved st dest -> [mkSystemLog (LogInfo $ actorName <> " removed status " <> st <> " from " <> dest)]
        PlanCanceled _ -> [mkSystemLog (LogInfo $ actorName <> " canceled their plan.")]
        ActorMoved _ -> [mkSystemLog (LogInfo $ actorName <> " moved.")]
        _ -> []
