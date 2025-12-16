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
import Control.Monad.State (State, get, put, runState)
import Data.Aeson (Value (..), object, (.=))
import Data.Map.Strict (Map)
import Data.Map.Strict qualified as Map
import Data.Maybe (isJust, isNothing)
import Data.Text (Text)
import Data.Text qualified as T
import Data.UUID (toText)
import System.Random (StdGen)

import CardPG.Core.Card (ConsequenceCard, ConsequenceCardT (..), CoreCard, CoreCardT (..))
import CardPG.Core.Logic (GameM, runGameM)
import CardPG.Core.Logic qualified as Logic
import CardPG.Core.NonEmptyText (getRawText)
import CardPG.Core.Primitives (ActorId (..), CardInstanceId (..), ResourceType (..))
import CardPG.Core.State
  ( ActionStack (..)
  , ActorState (..)
  , CardRegistry (..)
  , CoreCardState (..)
  , GameEnv
  , GameEvent (..)
  , PlannedAction (..)
  , PlannedActionMaterialized (..)
  , RealizedAttack (..)
  , RevealedEffect (..)
  , TableState (..)
  , materializePlannedAction
  )
import CardPG.Server.Presenter (eventToLogs, mkChatLog)
import CardPG.Server.Types
  ( ActorGameEvent (..)
  , Command (..)
  , GameState (..)
  , LogEntry (..)
  , LogPayload (..)
  , Phase (..)
  , StateUpdate (..)
  )

emptyGame :: GameEnv -> GameState
emptyGame env =
  GameState
    { env = env
    , actors = Map.empty
    , phase = Planning
    , history = []
    }

addActor :: ActorId -> ActorState -> GameState -> GameState
addActor tid state game = game{actors = Map.insert tid state game.actors}

runActorAction ::
  ActorId -> GameM StdGen a -> GameState -> State StdGen (Maybe [GameEvent], GameState)
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
  Command -> Int -> GameState -> State StdGen (GameState, [StateUpdate], [ActorGameEvent], [LogEntry])
processCommand cmd ts game =
  case cmd of
    StartResolutionIntent tid -> do
      (newGame, events) <- revealPlannedActions game
      let newGameWithPhase = newGame{phase = Resolution}
      let newLogs = concatMap (\(ActorGameEvent aid evt) -> eventToLogs ts aid evt newGameWithPhase) events
      let finalGame = newGameWithPhase{history = game.history ++ newLogs}
      return (finalGame, [], events, newLogs)
    EndRoundIntent _ -> do
      (newGame, updates, roundEvents) <- concludeRound game
      (gameWithPlan, planEvents) <- autoPlanForNPCs newGame
      let newGameWithPhase = gameWithPlan{phase = Planning}
      let newLogs = concatMap (\(ActorGameEvent aid evt) -> eventToLogs ts aid evt newGame) roundEvents
      let finalGame = newGameWithPhase{history = game.history ++ newLogs}
      return (finalGame, updates, planEvents ++ roundEvents, newLogs)
    ChatIntent maybeAid content -> do
      let senderName = case maybeAid of
            Just aid -> case Map.lookup aid game.actors of
              Just a -> a.name
              Nothing -> "Unknown"
            Nothing -> "GM"
      let logEntry = mkChatLog ts (length game.history) maybeAid senderName content
      let newLogs = [logEntry]
      let finalGame = game{history = game.history ++ newLogs}
      return (finalGame, [], [], newLogs)
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
            _ -> error "Impossible: unhandled command pattern in actor action block"

      (maybeEvents, newGame) <- runActorAction targetId action game
      case maybeEvents of
        Nothing -> return (game, [], [], []) -- Actor missing or no action
        Just events -> do
          let
            -- Retrieve updated actor state safely
            updatedActorState = case Map.lookup targetId newGame.actors of
              Just a -> a
              Nothing -> error "Actor missing after update"

            actorEvents = map (ActorGameEvent targetId) events
            stateUpdates = [StateUpdate targetId updatedActorState]
            newLogs = concatMap (\evt -> eventToLogs ts targetId evt newGame) events
            finalGame = newGame{history = game.history ++ newLogs}

          return (finalGame, stateUpdates, actorEvents, newLogs)

concludeRound :: GameState -> State StdGen (GameState, [StateUpdate], [ActorGameEvent])
concludeRound game = foldM step (game, [], []) (Map.keys game.actors)
  where
    step (g, updates, events) actorId = do
      -- 1. End Defense (new)
      (maybeDefenseEvents, gAfterDefense) <- runActorAction actorId Logic.endDefense g
      let defEvents = maybe [] (map (ActorGameEvent actorId)) maybeDefenseEvents

      -- 2. Apply Planned Move (existing)
      (maybeMoveEvents, gAfterMove) <- runActorAction actorId Logic.applyPlannedMove gAfterDefense
      let movEvents = maybe [] (map (ActorGameEvent actorId)) maybeMoveEvents

      -- 3. Discard Planned Actions (existing)
      (maybeDiscardEvents, gAfterDiscard) <- runActorAction actorId Logic.discardPlannedActions gAfterMove
      let disEvents = maybe [] (map (ActorGameEvent actorId)) maybeDiscardEvents

      -- 4. Draw Cards (new)
      (maybeDrawEvents, gAfterDraw) <-
        case Map.lookup actorId gAfterDiscard.actors of
          Just actor
            | not (Logic.isDefeated actor) ->
                runActorAction actorId (Logic.drawCard >> Logic.drawCard) gAfterDiscard
          _ -> return (Nothing, gAfterDiscard)
      let drwEvents = maybe [] (map (ActorGameEvent actorId)) maybeDrawEvents

      -- Combine logic for updates (if any changed state, we should send update)
      let hasUpdates =
            isJust maybeDefenseEvents
              || isJust maybeMoveEvents
              || isJust maybeDiscardEvents
              || isJust maybeDrawEvents

      let allEvents = events ++ defEvents ++ movEvents ++ disEvents ++ drwEvents

      if hasUpdates
        then case Map.lookup actorId gAfterDraw.actors of
          Just actor -> return (gAfterDraw, updates ++ [StateUpdate actorId actor], allEvents)
          Nothing -> return (gAfterDraw, updates, allEvents)
        else return (gAfterDraw, updates, allEvents)

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
