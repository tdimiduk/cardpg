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
import CardPG.Core.Primitives (ActorId (..), CardInstanceId (..), ResourceType (..))
import CardPG.Core.State
  ( ActionStack (..)
  , ActorState (..)
  , CardRegistry (..)
  , CoreCardState (..)
  , GameEnv
  , GameEvent (..)
  , materializePlannedAction
  )
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
  Command -> GameState -> (GameState, [StateUpdate], [BroadcastAction])
processCommand cmd game =
  case cmd of
    StartResolutionIntent tid ->
      let (newGame, broadcasts) = revealPlannedActions game
          -- We also need to send the 'StartResolution' signal itself
          allBroadcasts = StartResolutionPhase : broadcasts
       in (newGame, [], allBroadcasts)
    EndRoundIntent _ ->
      let (newGame, updates) = concludeRound game
          -- We need to send 'EndRound' signal?
          -- Legacy broadcast sent EndRound.
          -- If we make EndRoundIntent a command, should we broadcast it?
          -- The client might expect it to trigger animations.
          -- But StateUpdates should handle the movement.
          -- Let's broadcast EndRound as well for clients to clear logs etc.
          allBroadcasts = [EndRound]
       in (newGame, updates, allBroadcasts)
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
            _ -> error "Unreachable" -- Handled above
          (maybeEvents, newGame) = runActorAction targetId action game
       in case maybeEvents of
            Nothing -> (game, [], []) -- Actor missing or no action
            Just events ->
              let
                -- Retrieve updated actor state safely
                updatedActorState = case Map.lookup targetId (newGame.actors) of
                  Just a -> a
                  Nothing -> error "Actor missing after update"

                -- Registry is on the actor
                registry = updatedActorState.coreState.registry
                logicBroadcasts = eventsToBroadcastActions registry targetId events
                
                -- Augment broadcasts based on Intent
                extraBroadcasts = case cmd of
                  AddConsequenceIntent _ _ -> [AddConsequence targetId]
                  RemoveConsequenceIntent _ cid -> [RemoveConsequence targetId cid]
                  AddStatusIntent _ st dest -> [AddStatus targetId st dest]
                  RemoveStatusIntent _ st _ -> [RemoveStatus targetId st "unknown"] -- "destination" is unknown here, maybe fix later or safe to ignore?
                  _ -> []

                broadcastActions = logicBroadcasts ++ extraBroadcasts

                stateUpdates = [StateUpdate targetId updatedActorState]
               in
                (newGame, stateUpdates, broadcastActions)

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
    toAction (ActionRevealed wireAction) = case materializePlannedAction registry wireAction of
      Nothing -> [InvalidAction actorId "you don't have all these cards"]
      Just action -> case Logic.attackAction action of
        Left err -> [InvalidAction actorId err]
        Right attack -> [AttackAction actorId attack]
