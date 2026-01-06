{-# LANGUAGE OverloadedRecordDot #-}

module Server.Engine
  ( runActorAction
  , concludeRound
  , revealPlannedActions
  , autoPlanForNPCs
  ) where

import Control.Monad (foldM)
import Control.Monad.RWS (runRWST)
import Control.Monad.State (State, get, put, runState)
import Data.Map.Strict qualified as Map
import Data.Maybe (isJust, isNothing)
import Optics ((%~), (&))
import System.Random (StdGen)

import Api.Frontend qualified as Frontend
import Core.Logic.Bot qualified as Logic
import Core.Logic.Deck qualified as Logic
import Core.Logic.Monad (GameM, runGameM)
import Core.Logic.Planning qualified as Logic
import Core.Logic.Status qualified as Logic
import Core.Primitives (ActorId)
import Core.State (ActorState (..), CoreCardState (..), GameEvent)
import Server.Types (ActorGameEvent (..), GameState (..), StateUpdate (..))

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

concludeRound :: GameState -> State StdGen (GameState, [StateUpdate], [ActorGameEvent])
concludeRound game = foldM step (game, [], []) (Map.keys game.actors)
  where
    step (g, updates, events) actorId = do
      -- 1. End Defense (new)
      (maybeDefenseEvents, gAfterDefense) <- runActorAction actorId Logic.endDefense g
      let defEvents = maybe [] (map (ActorGameEvent actorId . Frontend.toGameEvent)) maybeDefenseEvents

      -- 2. Apply Planned Move (existing)
      (maybeMoveEvents, gAfterMove) <- runActorAction actorId Logic.applyPlannedMove gAfterDefense
      let movEvents = maybe [] (map (ActorGameEvent actorId . Frontend.toGameEvent)) maybeMoveEvents

      -- 3. Discard Planned Actions (existing)
      (maybeDiscardEvents, gAfterDiscard) <- runActorAction actorId Logic.discardPlannedActions gAfterMove
      let disEvents = maybe [] (map (ActorGameEvent actorId . Frontend.toGameEvent)) maybeDiscardEvents

      -- 4. Draw Cards (new)
      (maybeDrawEvents, gAfterDraw) <-
        case Map.lookup actorId gAfterDiscard.actors of
          Just actor
            | not (Logic.isDefeated actor) ->
                runActorAction actorId (Logic.drawCard >> Logic.drawCard) gAfterDiscard
          _ -> return (Nothing, gAfterDiscard)
      let drwEvents = maybe [] (map (ActorGameEvent actorId . Frontend.toGameEvent)) maybeDrawEvents

      -- Combine logic for updates (if any changed state, we should send update)
      let hasUpdates =
            isJust maybeDefenseEvents
              || isJust maybeMoveEvents
              || isJust maybeDiscardEvents
              || isJust maybeDrawEvents

      let allEvents = events ++ defEvents ++ movEvents ++ disEvents ++ drwEvents

      if hasUpdates
        then case Map.lookup actorId gAfterDraw.actors of
          Just actor -> return (gAfterDraw, updates ++ [StateUpdate actorId (Frontend.toActorState actor)], allEvents)
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
          let newEvents = map (ActorGameEvent actorId . Frontend.toGameEvent) events
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
                  let newEvents = map (ActorGameEvent actorId . Frontend.toGameEvent) events
                  return (newG, currentEvents ++ newEvents)
            else return (g, currentEvents)
