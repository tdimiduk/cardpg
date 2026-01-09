module Server.Dispatch
  ( processCommand
  ) where

import Control.Monad (replicateM)
import Control.Monad.State (State, state)
import Data.Map.Strict qualified as Map
import Data.Text (Text)
import Data.Text qualified as T
import System.Random (StdGen)
import System.Random.Stateful (Uniform (..), uniform, uniformM)

import Api.Frontend qualified as Frontend
import Core.Logic.Deck qualified as Logic
import Core.Logic.Planning qualified as Logic
import Core.Logic.Status qualified as Logic
import Core.Primitives
  ( ActorId
  , CardInstanceId
  , CardLocation
  , ChallengeId
  )
import Core.State
  ( ActiveChallenge (..)
  , ActorState (..)
  , ChallengeSource (..)
  , PlannedAction (PPass)
  )
import Core.Stats (ResourceType (..))
import Server.ChatParser (ChallengeDetails (..), ChatCommand (..), parseChatCommand)
import Server.Engine (autoPlanForNPCs, concludeRound, revealPlannedActions, runActorAction)
import Server.Presenter (eventToLogs)
import Server.Types
  ( ActorGameEvent (..)
  , Command (..)
  , GameState (..)
  , LogEntry (..)
  , LogId (..)
  , LogPayload (..)
  , Phase (..)
  , StateUpdate (..)
  )

mkLogEntry :: Int -> Text -> Maybe ActorId -> LogPayload -> State StdGen LogEntry
mkLogEntry ts senderName senderId payload = do
  logId <- state uniform
  return $
    LogEntry
      { id = logId
      , timestamp = ts
      , sender = senderName
      , senderId = senderId
      , payload = payload
      }

processCommand
  :: Command -> Int -> GameState -> State StdGen (GameState, [StateUpdate], [ActorGameEvent], [LogEntry])
processCommand cmd ts game =
  case cmd of
    StartResolutionIntent tid -> do
      (newGame, events) <- revealPlannedActions game
      let newGameWithPhase = newGame{phase = Resolution}
      let payloads =
            concatMap
              (\(ActorGameEvent aid evt) -> eventToLogs aid evt newGameWithPhase)
              events
      newLogs <- mapM (\(p, aid) -> mkLogEntry ts "System" aid p) payloads
      let finalGame = newGameWithPhase{history = game.history ++ newLogs}
      return (finalGame, [], events, newLogs)
    EndRoundIntent _ -> do
      (newGame, updates, roundEvents) <- concludeRound game
      (gameWithPlan, planEvents) <- autoPlanForNPCs newGame
      let newGameWithPhase = gameWithPlan{phase = Planning}
      let payloads =
            concatMap
              (\(ActorGameEvent aid evt) -> eventToLogs aid evt newGame)
              roundEvents
      newLogs <- mapM (\(p, aid) -> mkLogEntry ts "System" aid p) payloads
      let finalGame = newGameWithPhase{history = game.history ++ newLogs}
      return (finalGame, updates, planEvents ++ roundEvents, newLogs)
    ChatIntent maybeAid content -> do
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
                  , plannedAction = Frontend.PPass
                  }

          let senderName = case maybeAid of
                Just aid -> case Map.lookup aid game.actors of
                  Just a -> a.name
                  Nothing -> "Unknown"
                Nothing -> "GM"

          logEntry <- mkLogEntry ts senderName maybeAid logPayload

          let newGame = game{phase = Resolution, history = game.history ++ [logEntry]}
          return (newGame, [], [], [logEntry])
        CmdText _ -> do
          -- Normal Chat
          let senderName = case maybeAid of
                Just aid -> case Map.lookup aid game.actors of
                  Just a -> a.name
                  Nothing -> "Unknown"
                Nothing -> "GM"
          logEntry <- mkLogEntry ts senderName maybeAid (LogChat content)
          let newLogs = [logEntry]
          let finalGame = game{history = game.history ++ newLogs}
          return (finalGame, [], [], newLogs)
    _ -> do
      let (targetId, action) = case cmd of
            DrawIntent tid -> (tid, Logic.drawCard)
            DefendIntent tid cid ->
              -- Lookup the challenge in history
              let findChallenge [] = Nothing
                  findChallenge (logEntry : rest) = case logEntry.payload of
                    LogChallenge activeChallenge _ ->
                      if activeChallenge.id == cid
                        then Just activeChallenge
                        else findChallenge rest
                    _ -> findChallenge rest

                  maybeChallenge = findChallenge game.history
               in case maybeChallenge of
                    Just challenge -> (tid, Logic.flipCardToDefense challenge)
                    Nothing -> (tid, return ()) -- If challenge not found, do nothing (client handles error via lack of response/log, or we could add explicit log)
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

            actorEvents = map (ActorGameEvent targetId . Frontend.toGameEvent) events
            stateUpdates = [StateUpdate targetId (Frontend.toActorState updatedActorState)]

            payloads = concatMap (\evt -> eventToLogs targetId (Frontend.toGameEvent evt) newGame) events

          newLogs <- mapM (\(p, aid) -> mkLogEntry ts "System" aid p) payloads

          let finalGame = newGame{history = game.history ++ newLogs}

          return (finalGame, stateUpdates, actorEvents, newLogs)
