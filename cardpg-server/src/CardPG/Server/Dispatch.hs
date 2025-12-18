module CardPG.Server.Dispatch
  ( processCommand
  ) where

import Control.Monad.State (State)
import Data.Map.Strict qualified as Map
import Data.Text (Text)
import System.Random (StdGen)

import CardPG.Core.Logic.Deck qualified as Logic
import CardPG.Core.Logic.Planning qualified as Logic
import CardPG.Core.Logic.Status qualified as Logic
import CardPG.Core.Primitives (ActorId, CardInstanceId, CardLocation, ResourceType)
import CardPG.Core.State (ActorState (..))
import CardPG.Server.Engine (autoPlanForNPCs, concludeRound, revealPlannedActions, runActorAction)
import CardPG.Server.Presenter (eventToLogs, mkChatLog)
import CardPG.Server.Types
  ( ActorGameEvent (..)
  , Command (..)
  , GameState (..)
  , LogEntry (..)
  , Phase (..)
  , StateUpdate (..)
  )
import CardPG.Server.Types.Wire qualified as Wire

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
                  actionId
                  resourceIds
              )
            PlanNarrative tid cardIds color ->
              ( tid
              , Logic.planNarrative
                  cardIds
                  color
              )
            CancelPlanIntent tid -> (tid, Logic.cancelPlan)
            ReshuffleIntent tid -> (tid, Logic.reshuffleDeck)
            AddStatusIntent tid st dest -> (tid, Logic.addStatus st dest)
            DestroyStatusIntent tid st cid -> (tid, Logic.destroyStatus st cid)
            AddConsequenceIntent tid sev -> (tid, Logic.addConsequence sev)
            DestroyConsequenceIntent tid cid -> (tid, Logic.destroyConsequence cid)
            DiscardCardsIntent tid cids -> (tid, Logic.discardCards cids)
            ReturnToDeckIntent tid cids -> (tid, Logic.returnCardsToDeck cids)
            PassIntent tid -> (tid, Logic.passAction)

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
            stateUpdates = [StateUpdate targetId (Wire.toActorState updatedActorState)]
            newLogs = concatMap (\evt -> eventToLogs ts targetId evt newGame) events
            finalGame = newGame{history = game.history ++ newLogs}

          return (finalGame, stateUpdates, actorEvents, newLogs)
