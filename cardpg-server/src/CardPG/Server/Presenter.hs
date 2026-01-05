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
import CardPG.Core.Card qualified as CoreCard
import CardPG.Core.Logic.Combat (computeDefenseDetails)
import CardPG.Core.NonEmptyText (getRawText)
import CardPG.Core.Primitives (ActorId (..))
import CardPG.Core.State
  ( ActiveChallenge (..)
  , ActiveDefense (..)
  , ActorState (..)
  , CoreCardState (..)
  , RevealedEffect (..)
  )
import CardPG.Core.Stats (ResourceType (..), Stats (..))
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
        CardDefended challenge _ ->
          -- Lookup current defense state to show live progress
          let maybeDefense = do
                actorState <- Map.lookup actorId game.actors
                activeDefense <- actorState.coreState.defending
                -- Ensure we are defending against this specific challenge
                if activeDefense.activeChallenge.id == challenge.id
                  then Just (activeDefense, actorState)
                  else Nothing

              (details, logCards) = case maybeDefense of
                Just (ActiveDefense _ cards, actorState) ->
                  let d = Frontend.toDefenseDetails $ computeDefenseDetails actorState
                      c =
                        [ Frontend.LogCard
                            { name = getRawText cName
                            , color = challenge.challengeColor
                            , power = 0
                            }
                        | Identified _ CoreCard.CoreCard{name = cName} <- cards
                        ]
                   in (Just d, Just c)
                Nothing -> (Nothing, Nothing)
           in [mkSystemLog (LogDefense actorId challenge.id details logCards False)]
        DefenseEnded (Frontend.ActiveDefense challenge cards) details ->
          let logCards =
                [ Frontend.LogCard
                    { name = getRawText cName
                    , color = challenge.challengeColor
                    , power = 0 -- We don't have easy access to power without rule logic here.
                    }
                | Frontend.CoreCard{name = cName} <- cards
                ]
           in -- Let's improve this. We have CoreCard.
              -- But we really probably just want names for now because computing power requires `Combat.hs` logic which IS imported in `Frontend` but we are in `Presenter`.
              -- Actually `DefenseDetails` has the aggregates!
              -- So maybe we don't need per-card power in the log yet?
              -- If LogCard requires it, I'll put 0 or fix LogCard.
              -- Re-reading my LogCard definition: { name :: Text, color :: ResourceType, power :: Int }
              -- I'll use 0 for now to unblock.
              [mkSystemLog (LogDefense actorId challenge.id (Just details) (Just logCards) True)]
        DeckShuffled -> [mkSystemLog (LogInfo $ actorName <> " reshuffled their deck.")]
        ConsequenceAdded _ -> [mkSystemLog (LogInfo $ actorName <> " gained a consequence.")]
        ConsequenceRemoved _ -> [mkSystemLog (LogInfo $ actorName <> " removed consequence.")]
        StatusAdded st dest ->
          [mkSystemLog (LogInfo $ actorName <> " added status " <> st <> " to " <> T.pack (show dest))]
        StatusRemoved st dest -> [mkSystemLog (LogInfo $ actorName <> " removed status " <> st <> " from " <> dest)]
        PlanCanceled _ -> [mkSystemLog (LogInfo $ actorName <> " canceled their plan.")]
        ActorMoved _ -> [mkSystemLog (LogInfo $ actorName <> " moved.")]
        _ -> []
