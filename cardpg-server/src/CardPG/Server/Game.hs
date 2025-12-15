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

import Control.Monad (foldM)
import Control.Monad.RWS (runRWST)
import Control.Monad.State (State, runState, get, put)
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

emptyGame :: GameEnv -> GameState
emptyGame env =
  GameState
    { env = env
    , actors = Map.empty
    , phase = Planning
    }

addActor :: ActorId -> ActorState -> GameState -> GameState
addActor tid state game = game{actors = Map.insert tid state game.actors}

runActorAction :: ActorId -> GameM StdGen a -> GameState -> State StdGen (Maybe [GameEvent], GameState)
runActorAction tid action game =
  case Map.lookup tid game.actors of
    Nothing -> return (Nothing, game)
    Just actorState -> do
      rng <- get
      let ((_, newState, events), newRng) = runState (runRWST (runGameM action) game.env actorState) rng
      put newRng
      let newGame = game{actors = Map.insert tid newState game.actors}
      return (Just events, newGame)

processCommand ::
  Command -> GameState -> State StdGen (GameState, [StateUpdate], [ActorGameEvent])
processCommand cmd game =
  case cmd of
    StartResolutionIntent tid -> do
      (newGame, events) <- revealPlannedActions game
      let newGameWithPhase = newGame{phase = Resolution}
      return (newGameWithPhase, [], events)
    EndRoundIntent _ -> do
      (newGame, updates) <- concludeRound game
      (gameWithPlan, planEvents) <- autoPlanForNPCs newGame
      let newGameWithPhase = gameWithPlan{phase = Planning}
      return (newGameWithPhase, updates, planEvents)
    _ -> do
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
      (maybeEvents, newGame) <- runActorAction targetId action game
      case maybeEvents of
        Nothing -> return (game, [], []) -- Actor missing or no action
        Just events -> do
          let
            -- Retrieve updated actor state safely
            updatedActorState = case Map.lookup targetId newGame.actors of
              Just a -> a
              Nothing -> error "Actor missing after update"

            actorEvents = map (ActorGameEvent targetId) events
            stateUpdates = [StateUpdate targetId updatedActorState]
          
          return (newGame, stateUpdates, actorEvents)

concludeRound :: GameState -> State StdGen (GameState, [StateUpdate])
concludeRound game = foldM step (game, []) (Map.keys game.actors)
  where
    step (g, updates) actorId = do
      -- 1. End Defense (new)
      (maybeDefenseEvents, gAfterDefense) <- runActorAction actorId Logic.endDefense g
      -- 2. Apply Planned Move (existing)
      (maybeMoveEvents, gAfterMove) <- runActorAction actorId Logic.applyPlannedMove gAfterDefense
      -- 3. Discard Planned Actions (existing)
      (maybeDiscardEvents, gAfterDiscard) <- runActorAction actorId Logic.discardPlannedActions gAfterMove

      -- 4. Draw Cards (new)
      (maybeDrawEvents, gAfterDraw) <-
        case Map.lookup actorId gAfterDiscard.actors of
          Just actor | not (checkDefeated actor) ->
             runActorAction actorId (Logic.drawCard >> Logic.drawCard) gAfterDiscard
          _ -> return (Nothing, gAfterDiscard)

      -- Combine logic for updates (if any changed state, we should send update)
      let hasUpdates =
            isJust maybeDefenseEvents
              || isJust maybeMoveEvents
              || isJust maybeDiscardEvents
              || isJust maybeDrawEvents

      if hasUpdates
        then case Map.lookup actorId gAfterDraw.actors of
          Just actor -> return (gAfterDraw, updates ++ [StateUpdate actorId actor])
          Nothing -> return (gAfterDraw, updates)
        else return (gAfterDraw, updates)

    checkDefeated :: ActorState -> Bool
    checkDefeated actor =
      let registry = actor.tableState.consequenceRegistry
          isSev3 cid = case Map.lookup cid registry of
            Just card -> card.severity >= 3
            Nothing -> False
       in any isSev3 (actor.tableState.consequences)


revealPlannedActions :: GameState -> State StdGen (GameState, [ActorGameEvent])
revealPlannedActions game = foldM step (game, []) (Map.keys game.actors)
  where
    step (g, currentEvents) actorId = do
      (maybeEvents, newG) <- runActorAction actorId Logic.revealPlannedActions g
      case maybeEvents of
        Nothing -> return (newG, currentEvents)
        Just events -> do
          let newEvents = map (ActorGameEvent actorId) events
          return (newG, currentEvents ++ newEvents)

autoPlanForNPCs :: GameState -> State StdGen (GameState, [ActorGameEvent])
autoPlanForNPCs game = foldM step (game, []) (Map.keys game.actors)
  where
    step (g, currentEvents) actorId =
      case Map.lookup actorId g.actors of
        Nothing -> return (g, currentEvents)
        Just actor ->
          if actor.actorType /= "PC" && isNothing actor.coreState.planned
            then do
              (maybeEvents, newG) <- runActorAction actorId Logic.planBestAvailableAction g
              case maybeEvents of
                Nothing -> return (newG, currentEvents)
                Just events -> do
                  let newEvents = map (ActorGameEvent actorId) events
                  return (newG, currentEvents ++ newEvents)
            else return (g, currentEvents)
