{-# LANGUAGE OverloadedRecordDot #-}

module CardPG.Server.Game
  ( GameState (..)
  , emptyGame
  , addActor
  , runActorAction
  , processCommand
  , concludeRound
  , revealPlannedActions
  , autoPlanForNPCs
  ) where

import Control.Monad.RWS (runRWST)
import Control.Monad.State (runState)
import Data.Map.Strict (Map)
import Data.Map.Strict qualified as Map
import Data.Maybe (isJust, isNothing)
import Data.Text (Text)
import Data.Text qualified as T
import Data.UUID (toText)
import System.Random (StdGen)

import CardPG.Core.Card (ConsequenceCard, ConsequenceCardT (..), CoreCard)
import CardPG.Core.Logic (GameM, runGameM)
import CardPG.Core.Logic qualified as Logic
import CardPG.Core.Primitives (ActorId (..), CardInstanceId (..), ResourceType (..))
import CardPG.Core.State
  ( ActionStack (..)
  , ActorState (..)
  , CardRegistry (..)
  , CoreCardState (..)
  , GameEnv
  , GameEvent (..)
  , PlannedActionMaterialized (..)
  , TableState (..)
  , materializePlannedAction
  )
import CardPG.Server.Types
  ( ActorGameEvent (..)
  , Command (..)
  , GameState (..)
  , Phase (..)
  , StateUpdate (..)
  )

emptyGame :: GameEnv -> StdGen -> GameState
emptyGame env rng =
  GameState
    { env = env
    , rng = rng
    , actors = Map.empty
    , phase = Planning
    }

addActor :: ActorId -> ActorState -> GameState -> GameState
addActor tid state game = game{actors = Map.insert tid state game.actors}

runActorAction :: ActorId -> GameM StdGen a -> GameState -> (Maybe [GameEvent], GameState)
runActorAction tid action game =
  case Map.lookup tid game.actors of
    Nothing -> (Nothing, game)
    Just actorState ->
      let ((_, newState, events), newRng) = runState (runRWST (runGameM action) game.env actorState) game.rng
          newGame = game{rng = newRng, actors = Map.insert tid newState game.actors}
       in (Just events, newGame)

processCommand ::
  Command -> GameState -> (GameState, [StateUpdate], [ActorGameEvent])
processCommand cmd game =
  case cmd of
    StartResolutionIntent tid ->
      let (newGame, events) = revealPlannedActions game
          newGameWithPhase = newGame{phase = Resolution}
       in (newGameWithPhase, [], events)
    EndRoundIntent _ ->
      let (newGame, updates) = concludeRound game
          (gameWithPlan, planEvents) = autoPlanForNPCs newGame
          newGameWithPhase = gameWithPlan{phase = Planning}
       in (newGameWithPhase, updates, planEvents)
    _ ->
      let (targetId, action) = case cmd of
            DrawIntent tid -> (tid, Logic.drawCard)
            DefendIntent tid -> (tid, Logic.flipCardToDefense)
            EndDefenseIntent tid -> (tid, Logic.endDefense)
            PlanMove tid x y -> (tid, Logic.planMove x y)
            PlanAction tid actionId resourceIds ->
              ( tid
              , Logic.planAction
                  (CardInstanceId . read $ T.unpack actionId)
                  (map (CardInstanceId . read . T.unpack) resourceIds)
              )
            PlanNarrative tid cardIds color ->
              ( tid
              , Logic.planNarrative
                  (map (CardInstanceId . read . T.unpack) cardIds)
                  color
              )
            CancelPlanIntent tid -> (tid, Logic.cancelPlan)
            ReshuffleIntent tid -> (tid, Logic.reshuffleDeck)
            AddStatusIntent tid st dest -> (tid, Logic.addStatus st dest)
            RemoveStatusIntent tid st cid -> (tid, Logic.removeStatus st cid)
            AddConsequenceIntent tid sev -> (tid, Logic.addConsequence sev)
            RemoveConsequenceIntent tid cid -> (tid, Logic.removeConsequence cid)
            DiscardCardsIntent tid cids -> (tid, Logic.discardCards cids)
            ReturnToDeckIntent tid cids -> (tid, Logic.returnCardsToDeck cids)
            PassIntent tid -> (tid, Logic.passAction)
          (maybeEvents, newGame) = runActorAction targetId action game
       in case maybeEvents of
            Nothing -> (game, [], []) -- Actor missing or no action
            Just events ->
              let
                -- Retrieve updated actor state safely
                updatedActorState = case Map.lookup targetId newGame.actors of
                  Just a -> a
                  Nothing -> error "Actor missing after update"

                actorEvents = map (ActorGameEvent targetId) events
                stateUpdates = [StateUpdate targetId updatedActorState]
               in
                (newGame, stateUpdates, actorEvents)

concludeRound :: GameState -> (GameState, [StateUpdate])
concludeRound game = foldl step (game, []) (Map.keys game.actors)
  where
    step (g, updates) actorId =
      -- 1. End Defense (new)
      let (maybeDefenseEvents, gAfterDefense) = runActorAction actorId Logic.endDefense g
          -- 2. Apply Planned Move (existing)
          (maybeMoveEvents, gAfterMove) = runActorAction actorId Logic.applyPlannedMove gAfterDefense
          -- 3. Discard Planned Actions (existing)
          (maybeDiscardEvents, gAfterDiscard) = runActorAction actorId Logic.discardPlannedActions gAfterMove

          -- 4. Draw Cards (new)
          (maybeDrawEvents, gAfterDraw) =
            case Map.lookup actorId gAfterDiscard.actors of
              Just actor | not (checkDefeated actor) ->
                 runActorAction actorId (Logic.drawCard >> Logic.drawCard) gAfterDiscard
              _ -> (Nothing, gAfterDiscard)

          -- Combine logic for updates (if any changed state, we should send update)
          hasUpdates =
            isJust maybeDefenseEvents
              || isJust maybeMoveEvents
              || isJust maybeDiscardEvents
              || isJust maybeDrawEvents
       in if hasUpdates
            then case Map.lookup actorId gAfterDraw.actors of
              Just actor -> (gAfterDraw, updates ++ [StateUpdate actorId actor])
              Nothing -> (gAfterDraw, updates)
            else (gAfterDraw, updates)

    checkDefeated :: ActorState -> Bool
    checkDefeated actor =
      let registry = actor.tableState.consequenceRegistry
          isSev3 cid = case Map.lookup cid registry of
            Just card -> card.severity >= 3
            Nothing -> False
       in any isSev3 (actor.tableState.consequences)


revealPlannedActions :: GameState -> (GameState, [ActorGameEvent])
revealPlannedActions game = foldl step (game, []) (Map.keys game.actors)
  where
    step (g, currentEvents) actorId =
      let (maybeEvents, newG) = runActorAction actorId Logic.revealPlannedActions g
       in case maybeEvents of
            Nothing -> (newG, currentEvents)
            Just events ->
              let newEvents = map (ActorGameEvent actorId) events
               in (newG, currentEvents ++ newEvents)

autoPlanForNPCs :: GameState -> (GameState, [ActorGameEvent])
autoPlanForNPCs game = foldl step (game, []) (Map.keys game.actors)
  where
    step (g, currentEvents) actorId =
      case Map.lookup actorId g.actors of
        Nothing -> (g, currentEvents)
        Just actor ->
          if actor.actorType /= "PC" && isNothing actor.coreState.planned
            then
              let (maybeEvents, newG) = runActorAction actorId Logic.planBestAvailableAction g
               in case maybeEvents of
                    Nothing -> (newG, currentEvents)
                    Just events ->
                      let newEvents = map (ActorGameEvent actorId) events
                       in (newG, currentEvents ++ newEvents)
            else (g, currentEvents)
