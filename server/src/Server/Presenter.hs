{-# LANGUAGE OverloadedRecordDot #-}

module Server.Presenter
  ( eventToLogs
  ) where

import Data.Map qualified as Map
import Data.Text qualified as T

import Core.Logic.Combat (computeDefenseDetails)
import Core.Primitives (ActorId (..))
import Core.State
  ( ActiveChallenge (..)
  , ActiveDefense (..)
  , ActorState (..)
  , BattleRank (..)
  , CoreCardState (..)
  , GameEvent (..)
  , IllegalActionDetails (..)
  , RevealedEffect (..)
  )
import Server.Types
  ( GameState (..)
  , LogPayload (..)
  )

eventToLogs :: Maybe ActorId -> GameEvent -> GameState -> [(LogPayload, Maybe ActorId)]
eventToLogs maybeActorId event game =
  let actorName = case maybeActorId >>= flip Map.lookup game.actors of
        Just a -> a.name
        Nothing -> "Unknown"

      mkSystemLog payload = (payload, maybeActorId)
   in case event of
        ActionRevealed plan effect -> case effect of
          REChallenge challenge ->
            [mkSystemLog (LogChallenge challenge plan)]
          REPass -> [mkSystemLog (LogInfo $ actorName <> " passed.")]
          REInvalid msg -> [mkSystemLog (LogInfo $ "Invalid Action for " <> actorName <> ": " <> msg)]
        IllegalAction (IllegalActionDetails _ (Just reason)) -> [mkSystemLog (LogError $ "Illegal Action for " <> actorName <> ": " <> reason)]
        CardDrawn card -> case maybeActorId of
          Just actorId -> [mkSystemLog (LogCardDrawn actorId card)]
          Nothing -> [mkSystemLog (LogInfo "A card was drawn.")]
        CardDefended challenge _ -> case maybeActorId of
          Just actorId ->
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
                    let d = computeDefenseDetails actorState
                     in (Just d, Just cards)
                  Nothing -> (Nothing, Nothing)
             in [mkSystemLog (LogDefense actorId challenge.id details logCards False)]
          Nothing -> []
        DefenseEnded (ActiveDefense challenge cards) details -> case maybeActorId of
          Just actorId ->
            [mkSystemLog (LogDefense actorId challenge.id (Just details) (Just cards) True)]
          Nothing -> []
        DeckShuffled -> [mkSystemLog (LogInfo $ actorName <> " reshuffled their deck.")]
        ConsequenceAdded consequence -> case maybeActorId of
          Just actorId ->
            let maybeChallengeId = do
                  actorState <- Map.lookup actorId game.actors
                  activeDefense <- actorState.coreState.defending
                  Just activeDefense.activeChallenge.id
             in [mkSystemLog (LogConsequence actorId maybeChallengeId consequence)]
          Nothing -> [mkSystemLog (LogInfo "A consequence was gained.")]
        ConsequenceRemoved _ -> [mkSystemLog (LogInfo $ actorName <> " removed consequence.")]
        StatusAdded st dest ->
          [mkSystemLog (LogInfo $ actorName <> " added status " <> st <> " to " <> T.pack (show dest))]
        StatusRemoved st dest -> [mkSystemLog (LogInfo $ actorName <> " removed status " <> st <> " from " <> dest)]
        PlanCanceled _ -> [mkSystemLog (LogInfo $ actorName <> " canceled their plan.")]
        ActorMoved _ -> [mkSystemLog (LogInfo $ actorName <> " moved.")]
        ActorRankMoved rank ->
          let friendlyRank FrontRank = "front rank"
              friendlyRank BackRank = "back rank"
           in [mkSystemLog (LogInfo $ actorName <> " moved to the " <> friendlyRank rank <> ".")]
        RoundStarted roundNum ->
          [mkSystemLog (LogInfo $ "Round " <> T.pack (show roundNum) <> " started.")]
        _ -> []
