module Server.Dispatch
  ( processCommand
  ) where

import Control.Monad.State (State, state)
import Data.Map.Strict qualified as Map
import System.Random (StdGen)
import System.Random.Stateful (uniform)

import Core.Logic.Deck qualified as Logic
import Core.Logic.Planning qualified as Logic
import Core.Logic.Status qualified as Logic
import Core.Primitives (ActorId)
import Core.State
  ( ActiveChallenge (..)
  , ActorState (..)
  , ChallengeSource (..)
  , PlannedAction (PPass)
  )
import Server.ChatParser (ChallengeDetails (..), ChatCommand (..), parseChatCommand)
import Server.Engine (autoPlanForNPCs, concludeRound, revealPlannedActions, runActorAction)
import Server.Presenter (eventToLogs)
import Server.Types
  ( ActorGameEvent (..)
  , GameState (..)
  , LogEntry (..)
  , LogPayload (..)
  , LogSender (..)
  , Phase (..)
  , StateUpdate (..)
  )

import Api.Request (ApiRequest (..))

mkLogEntry :: LogSender -> LogPayload -> State StdGen LogEntry
mkLogEntry sender payload = do
  logId <- state uniform
  return $
    LogEntry
      { id = logId
      , sender = sender
      , payload = payload
      }

processCommand
  :: ApiRequest a
  -> GameState
  -> State StdGen (GameState, a, [ActorGameEvent], [LogEntry])
processCommand cmd game =
  case cmd of
    StartResolution -> do
      (newGame, events) <- revealPlannedActions game
      let newGameWithPhase = newGame{phase = Resolution}
      let payloads =
            concatMap
              (\(ActorGameEvent aid evt) -> eventToLogs aid evt newGameWithPhase)
              events
      newLogs <- mapM (\(p, aid) -> mkLogEntry (resolveSender aid game) p) payloads
      let finalGame = newGameWithPhase{history = game.history ++ newLogs}
      return (finalGame, Right [], events, newLogs)
    EndRound -> do
      (newGame, updates, roundEvents) <- concludeRound game
      (gameWithPlan, planEvents) <- autoPlanForNPCs newGame
      let newGameWithPhase = gameWithPlan{phase = Planning}
      let payloads =
            concatMap
              (\(ActorGameEvent aid evt) -> eventToLogs aid evt newGame)
              roundEvents
      newLogs <- mapM (\(p, aid) -> mkLogEntry (resolveSender aid game) p) payloads
      let finalGame = newGameWithPhase{history = game.history ++ newLogs}
      return (finalGame, Right updates, planEvents ++ roundEvents, newLogs)
    SendChat maybeAid content -> do
      case parseChatCommand content of
        CmdChallenge (ChallengeDetails color val name desc) -> do
          -- Generate ID for ad-hoc challenge
          cid <- state uniform

          -- Ad-hoc challenge Logic
          let challenge =
                ActiveChallenge
                  { id = cid
                  , source = CSAdHoc name desc
                  , challengeStrength = val
                  , challengeColor = color
                  }
          let logPayload =
                LogChallenge
                  { challenge = challenge
                  , plannedAction = PPass
                  }

          let sender = resolveSender maybeAid game
          logEntry <- mkLogEntry sender logPayload

          let newGame = game{phase = Resolution, history = game.history ++ [logEntry]}
          return (newGame, (), [], [logEntry])
        CmdText _ -> do
          -- Normal Chat
          let sender = resolveSender maybeAid game
          logEntry <- mkLogEntry sender (LogChat content)
          let newLogs = [logEntry]
          let finalGame = game{history = game.history ++ newLogs}
          return (finalGame, (), [], newLogs)
    Join _ -> error "Join is handled by the connection layer" -- Should never be called here
    DrawCards tid -> runStandard tid Logic.drawCard
    Defend tid cid -> do
      let findChallenge [] = Nothing
          findChallenge (logEntry : rest) = case logEntry.payload of
            LogChallenge activeChallenge _ ->
              if activeChallenge.id == cid
                then Just activeChallenge
                else findChallenge rest
            _ -> findChallenge rest

          maybeChallenge = findChallenge game.history
      case maybeChallenge of
        Just challenge -> runStandard tid (Logic.flipCardToDefense challenge)
        Nothing -> runStandard tid (return ())
    EndDefense tid -> runStandard tid Logic.endDefense
    PlanMove tid x y -> runStandard tid (Logic.planMove x y)
    PlanAction tid actionId resourceIds ->
      runStandard
        tid
        ( Logic.planAction
            actionId
            resourceIds
        )
    PlanNarrative tid cardIds color ->
      runStandard
        tid
        ( Logic.planNarrative
            cardIds
            color
        )
    CancelPlan tid -> runStandard tid Logic.cancelPlan
    Reshuffle tid -> runStandard tid Logic.reshuffleDeck
    AddStatus tid st dest -> runStandard tid (Logic.addStatus st dest)
    DestroyStatus tid st cid -> runStandard tid (Logic.destroyStatus st cid)
    AddConsequence tid sev -> runStandard tid (Logic.addConsequence sev)
    DestroyConsequence tid cid -> runStandard tid (Logic.destroyConsequence cid)
    ReturnToDeck tid cids -> runStandard tid (Logic.returnCardsToDeck cids)
    Pass tid -> runStandard tid Logic.passAction
    DiscardCards tid cids -> runStandard tid (Logic.discardCards cids)
  where
    runStandard targetId action = do
      (maybeEvents, newGame) <- runActorAction targetId action game
      case maybeEvents of
        Nothing -> return (game, Right [], [], []) -- Actor missing or no action
        Just events -> do
          let
            updatedActorState = case Map.lookup targetId newGame.actors of
              Just a -> a
              Nothing -> error "Actor missing after update"

            actorEvents = map (ActorGameEvent targetId) events
            stateUpdates = [StateUpdate targetId updatedActorState]

            payloads = concatMap (\evt -> eventToLogs targetId evt newGame) events

          newLogs <- mapM (\(p, aid) -> mkLogEntry (resolveSender aid game) p) payloads

          let finalGame = newGame{history = game.history ++ newLogs}

          return (finalGame, Right stateUpdates, actorEvents, newLogs)

resolveSender :: Maybe ActorId -> GameState -> LogSender
resolveSender Nothing _ = SenderGM -- Default to GM
resolveSender (Just aid) game =
  case Map.lookup aid game.actors of
    Just ActorState{name = n} -> SenderActor aid n
    Nothing -> SenderActor aid "Unknown"
