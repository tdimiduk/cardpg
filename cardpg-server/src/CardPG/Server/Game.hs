{-# LANGUAGE OverloadedRecordDot #-}

module CardPG.Server.Game
  ( GameState (..)
  , emptyGame
  , addActor
  , runActorAction
  , processCommand
  , concludeRound
  , revealPlannedActions
  , eventsToBroadcastActions
  ) where

import Control.Monad.RWS (runRWST)
import Control.Monad.State (runState)
import Data.Map.Strict (Map)
import Data.Map.Strict qualified as Map
import Data.Text (Text)
import Data.Text qualified as T
import Data.UUID (toText)
import System.Random (StdGen)

import CardPG.Core.Card (CoreCard)
import CardPG.Core.Logic (GameM, runGameM)
import CardPG.Core.Logic qualified as Logic
import CardPG.Core.Primitives (CardInstanceId (..), ResourceType (..), ActorId (..))
import CardPG.Core.State (ActorState (..), GameEnv, GameEvent (..), ActionStack (..), CardRegistry (..), materializeStack, CoreCardState (..))
import CardPG.Server.Types (BroadcastAction (..), Command (..), GameState (..), StateUpdate (..))

emptyGame :: GameEnv -> StdGen -> GameState
emptyGame env rng =
  GameState
    { env = env
    , rng = rng
    , actors = Map.empty
    }

addActor :: ActorId -> ActorState -> GameState -> GameState
addActor tid state game = game{actors = Map.insert tid state (game.actors)}

runActorAction :: ActorId -> GameM StdGen a -> GameState -> (Maybe [GameEvent], GameState)
runActorAction tid action game =
  case Map.lookup tid (game.actors) of
    Nothing -> (Nothing, game)
    Just actorState ->
      let ((_, newState, events), newRng) = runState (runRWST (runGameM action) (game.env) actorState) (game.rng)
          newGame = game{rng = newRng, actors = Map.insert tid newState (game.actors)}
       in (Just events, newGame)

processCommand ::
  Command -> GameState -> (GameState, Maybe (ActorId, [BroadcastAction], ActorState))
processCommand cmd game =
  case cmd of
    StartResolutionIntent tid ->
      let (newGame, broadcasts) = revealPlannedActions game
          updatedActorState = Map.lookup tid (newGame.actors)
       in ( newGame
          , Just (tid, StartResolutionPhase : broadcasts, maybe (error "Actor missing after update") id updatedActorState)
          )
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
            CancelPlanIntent tid -> (tid, Logic.cancelPlan)


          (maybeEvents, newGame) = runActorAction targetId action game
       in case maybeEvents of
            Nothing -> (game, Nothing)
            Just events ->
              let
                  -- Retrieve updated actor state safely
                  updatedActorState = case Map.lookup targetId (newGame.actors) of
                    Just a -> a
                    Nothing -> error "Actor missing after update"

                  -- Registry is on the actor
                  registry = updatedActorState.coreState.registry
                  broadcastActions = eventsToBroadcastActions registry targetId events

               in ( newGame
                  , Just (targetId, broadcastActions, updatedActorState)
                  )

concludeRound :: GameState -> (GameState, [StateUpdate])
concludeRound game = foldl step (game, []) (Map.keys (game.actors))
  where
    step (g, updates) actorId =
      -- 1. End Defense (new)
      let (maybeDefenseEvents, gAfterDefense) = runActorAction actorId Logic.endDefense g
          -- 2. Apply Planned Move (existing)
          (maybeMoveEvents, gAfterMove) = runActorAction actorId Logic.applyPlannedMove gAfterDefense
          -- 3. Discard Planned Actions (existing)
          (maybeDiscardEvents, gAfterDiscard) = runActorAction actorId Logic.discardPlannedActions gAfterMove

          -- Combine logic for updates (if any changed state, we should send update)
          hasUpdates =
            maybe False (const True) maybeDefenseEvents
              || maybe False (const True) maybeMoveEvents
              || maybe False (const True) maybeDiscardEvents
       in if hasUpdates
            then case Map.lookup actorId (gAfterDiscard.actors) of
              Just actor -> (gAfterDiscard, updates ++ [StateUpdate actorId actor])
              Nothing -> (gAfterDiscard, updates)
            else (gAfterDiscard, updates)

revealPlannedActions :: GameState -> (GameState, [BroadcastAction])
revealPlannedActions game = foldl step (game, []) (Map.keys (game.actors))
  where
    step (g, broadcasts) actorId =
      let (maybeEvents, newG) = runActorAction actorId Logic.revealPlannedActions g
       in case maybeEvents of
            Nothing -> (newG, broadcasts)
            Just events ->
               let actorState = case Map.lookup actorId (newG.actors) of
                      Just a -> a
                      Nothing -> error "Actor missing logic error"
                   registry = actorState.coreState.registry
                   newBroadcasts = eventsToBroadcastActions registry actorId events
               in (newG, broadcasts ++ newBroadcasts)

-- | Helper to map internal GameEvents to Protocol BroadcastActions
eventsToBroadcastActions :: CardRegistry CoreCard -> ActorId -> [GameEvent] -> [BroadcastAction]
eventsToBroadcastActions registry actorId events = concatMap toAction events
  where
    toAction (CardDrawn _) = [DrawCards actorId 1]
    toAction (CardDefended _) = [Defend actorId]
    toAction DeckShuffled = [Reshuffle actorId]
    toAction (DefenseEnded _) = [ClearDefense actorId]
    toAction (CardsCreated _) = [] -- No visual action for creating cards
    toAction (MovePlanned _) = [] -- State update handles ghost
    toAction (ActorMoved _) = [] -- State update handles position
    toAction (ActionPlanned _) = [] -- Secret until revealed
    toAction (PlanCanceled _) = [] -- State update handles hand restoration
    toAction (ActionRevealed wireAction) = case materializeStack registry wireAction of
      Nothing -> [InvalidAction actorId "you don't have all these cards"]
      Just action -> case Logic.attackAction action of
        Left err -> [InvalidAction actorId err]
        Right attack -> [AttackAction actorId attack]