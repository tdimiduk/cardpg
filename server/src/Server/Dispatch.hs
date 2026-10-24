{-# LANGUAGE DuplicateRecordFields #-}
{-# LANGUAGE OverloadedRecordDot #-}

module Server.Dispatch
  ( processCommand
  ) where

import Control.Lens ((%~), (&), (.~), (?~))
import Control.Monad (void)
import Control.Monad.State (State, state)
import Data.Bifunctor (first)
import Data.Generics.Labels ()
import Data.Map.Strict qualified as Map
import Data.Maybe (fromMaybe, isJust)
import System.Random (StdGen)
import System.Random.Stateful (uniform)

import Api.Types (PlayMode (..))
import Core.Card.Exploration
  ( ClockDeckId (..)
  , ClockEventCard (..)
  , ClockNarrative (..)
  )
import Core.DSL (toText)
import Core.Logic.Deck qualified as Logic
import Core.Logic.Exploration qualified as LogicExpl
import Core.Logic.Monad (GameM)
import Core.Logic.Planning qualified as Logic
import Core.Logic.Status qualified as Logic
import Core.NonEmptyText (getRawText)
import Core.Primitives (ActorId)
import Core.State
  ( ActiveChallenge (..)
  , ActiveDefense (..)
  , ActorState (..)
  , ChallengeDomain (..)
  , ChallengeSource (..)
  , CoreCardState (..)
  , ExplorationFocus (..)
  , GameEvent (..)
  , LocationRuntimeState (..)
  , PlannedAction (PPass)
  , RevealedEffect (..)
  , TeamworkProgress (..)
  , WorldState (..)
  )
import Core.Time (formatExpeditionTime)
import Data.Text (Text, pack)
import Server.ChatParser (ChallengeDetails (..), ChatCommand (..), parseChatCommand)
import Server.Engine
  ( autoPlanForNPCs
  , concludeRound
  , revealPlannedActions
  , runActorAction
  , transitionToCrisis
  , transitionToExploration
  )
import Server.Presenter (eventToLogs, explorationEventToLog)
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
      let resolvedGame = newGame & #phase .~ Resolution
      let payloads =
            concatMap
              (\(ActorGameEvent aid evt) -> eventToLogs aid evt resolvedGame)
              events
      newLogs <- mapM (\(p, aid) -> mkLogEntry (resolveSender aid game) p) payloads
      let finalGame = resolvedGame & #history %~ (++ newLogs)
      return (finalGame, Right [], events, newLogs)
    EndRound -> do
      case game.playMode of
        ModeExploration -> do
          (newGame, updates, roundEvents, explPayloads) <- concludeRound game
          if newGame.playMode == ModeCrisis
            then do
              logCrisis <- mkLogEntry SenderSystem (LogInfo "Encounter triggered! Transitioning to Crisis mode.")
              explLogs <- mapM (mkLogEntry SenderSystem) explPayloads
              let allLogs = explLogs ++ [logCrisis]
                  finalGame = newGame & #history %~ (++ allLogs)
              return (finalGame, Right updates, roundEvents, allLogs)
            else do
              let newRound = newGame.roundNumber
                  roundStartEvent = ActorGameEvent Nothing (RoundStarted newRound)
                  payloads =
                    concatMap
                      (\(ActorGameEvent aid evt) -> eventToLogs aid evt newGame)
                      (roundEvents ++ [roundStartEvent])
              newLogs <- mapM (\(p, aid) -> mkLogEntry (resolveSender aid game) p) payloads
              explLogs <- mapM (mkLogEntry SenderSystem) explPayloads
              let allLogs = newLogs ++ explLogs
                  finalGame = newGame & #history %~ (++ allLogs)
              return (finalGame, Right updates, roundEvents ++ [roundStartEvent], allLogs)
        ModeCrisis -> do
          (newGame, updates, roundEvents, _) <- concludeRound game
          let hostiles = filter (\a -> a.actorType /= "PC") (Map.elems newGame.actors)
          if not (null hostiles) && all Logic.isDefeated hostiles
            then do
              (expGame, expUpdates, expEvents) <- transitionToExploration newGame
              logEntry <- mkLogEntry SenderSystem (LogInfo "All hostiles defeated. Resuming exploration mode.")
              let allUpdates = updates ++ expUpdates
                  allEvents = roundEvents ++ expEvents
                  finalGame = expGame & #history %~ (++ [logEntry])
              return (finalGame, Right allUpdates, allEvents, [logEntry])
            else do
              (gameWithPlan, planEvents) <- autoPlanForNPCs newGame
              let newRound = game.roundNumber + 1
              let planningGame =
                    gameWithPlan
                      & #phase .~ Planning
                      & #roundNumber .~ newRound
              let roundStartEvent = ActorGameEvent Nothing (RoundStarted newRound)
              let payloads =
                    concatMap
                      (\(ActorGameEvent aid evt) -> eventToLogs aid evt planningGame)
                      (roundEvents ++ [roundStartEvent])
              newLogs <- mapM (\(p, aid) -> mkLogEntry (resolveSender aid game) p) payloads
              let finalGame = planningGame & #history %~ (++ newLogs)
              return (finalGame, Right updates, planEvents ++ roundEvents ++ [roundStartEvent], newLogs)
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
                  , challengeDomain = CombatTrauma
                  , consequencePool = Nothing
                  , timePerImpact = Nothing
                  }
          let logPayload =
                LogChallenge
                  { challenge = challenge
                  , plannedAction = PPass
                  }

          let sender = resolveSender maybeAid game
          logEntry <- mkLogEntry sender logPayload

          let newGame =
                game
                  & #phase .~ Resolution
                  & #history %~ (++ [logEntry])
          return (newGame, (), [], [logEntry])
        CmdText _ -> do
          -- Normal Chat
          let sender = resolveSender maybeAid game
          logEntry <- mkLogEntry sender (LogChat content)
          let newLogs = [logEntry]
          let finalGame = game & #history %~ (++ newLogs)
          return (finalGame, (), [], newLogs)
    Join _ -> error "Join is handled by the connection layer" -- Should never be called here
    SetRole _ -> error "SetRole is handled by the connection layer" -- Should never be called here
    UndoPhase -> error "UndoPhase is handled by the connection layer" -- Should never be called here
    SaveCustomCard _ _ -> error "SaveCustomCard is handled by the connection layer" -- Should never be called here
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
        Just challenge -> do
          (maybeEvents, newGame) <- runActorAction tid (Logic.flipCardToDefense challenge) game
          case maybeEvents of
            Nothing -> return (game, Right [], [], [])
            Just events -> do
              let updatedActorState = case Map.lookup tid newGame.actors of
                    Just a -> a
                    Nothing -> error "Actor missing after update"
                  actorEvents = map (ActorGameEvent (Just tid)) events
                  stateUpdates = [StateUpdate tid updatedActorState]
                  payloads = concatMap (\evt -> eventToLogs (Just tid) evt newGame) events
              newLogs <- mapM (\(p, aid) -> mkLogEntry (resolveSender aid game) p) payloads
              let finalWorldState = case newGame.worldState of
                    Just ws
                      | Just tp <- ws.activeTeamworkChallenge
                      , tp.activeChallenge.id == cid ->
                          let flippedCards = [c | CardDefended _ c <- events]
                              (ws', _isComplete, _extraDur) =
                                LogicExpl.contributeToTeamworkChallenge updatedActorState.name flippedCards ws
                           in Just ws'
                    other -> other
                  finalGame = (newGame & #worldState .~ finalWorldState) & #history %~ (++ newLogs)
              return (finalGame, Right stateUpdates, actorEvents, newLogs)
        Nothing -> runStandard tid (return ())
    EndDefense tid -> runStandard tid Logic.endDefense
    PlanMove tid x y -> runStandard tid (Logic.planMove x y)
    PlanRankMove tid rank cardId -> runStandard tid (Logic.planRankMove rank cardId)
    SetMapMode mode -> do
      let logPayload = LogInfo ("Map mode switched to " <> pack (show mode))
      logEntry <- mkLogEntry SenderSystem logPayload
      let finalGame =
            game
              & (#mapMode ?~ mode)
              & #history %~ (++ [logEntry])
      return (finalGame, Right [], [], [logEntry])
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
    AddConsequence tid sev maybeCid -> do
      let findChallenge [] = Nothing
          findChallenge (logEntry : rest) = case logEntry.payload of
            LogChallenge activeChallenge _ ->
              if Just activeChallenge.id == maybeCid
                then Just activeChallenge
                else findChallenge rest
            _ -> findChallenge rest
          mChallenge = findChallenge game.history
      (maybeEvents, newGame) <- runActorAction tid (Logic.addConsequenceForChallenge mChallenge sev) game
      case maybeEvents of
        Nothing -> return (game, Right [], [], []) -- Actor missing or no action
        Just events -> do
          let
            updatedActorState = case Map.lookup tid newGame.actors of
              Just a -> a
              Nothing -> error "Actor missing after update"

            actorEvents = map (ActorGameEvent (Just tid)) events
            stateUpdates = [StateUpdate tid updatedActorState]

            overrideCid (LogConsequence aid Nothing c) | aid == tid = LogConsequence aid maybeCid c
            overrideCid p = p

            payloads =
              map (first overrideCid) $
                concatMap (\evt -> eventToLogs (Just tid) evt newGame) events

          newLogs <- mapM (\(p, aid) -> mkLogEntry (resolveSender aid game) p) payloads

          let hostiles = filter (\a -> a.actorType /= "PC") (Map.elems newGame.actors)
          if newGame.playMode == ModeCrisis && not (null hostiles) && all Logic.isDefeated hostiles
            then do
              (expGame, expUpdates, expEvents) <- transitionToExploration newGame
              logDefeated <- mkLogEntry SenderSystem (LogInfo "Hostiles defeated. Resuming exploration mode.")
              let allUpdates = stateUpdates ++ expUpdates
                  allEvents = actorEvents ++ expEvents
                  finalGame = expGame & #history %~ (++ (newLogs ++ [logDefeated]))
              return (finalGame, Right allUpdates, allEvents, newLogs ++ [logDefeated])
            else do
              let finalGame = newGame & #history %~ (++ newLogs)
              return (finalGame, Right stateUpdates, actorEvents, newLogs)
    DestroyConsequence tid cid -> runStandard tid (Logic.destroyConsequence cid)
    ReturnToDeck tid cids -> runStandard tid (Logic.returnCardsToDeck cids)
    Pass tid -> runStandard tid Logic.passAction
    DiscardCards tid cids -> runStandard tid (Logic.discardCards cids)
    PlanExplorationIntent tid intent -> runStandard tid (Logic.planExploration intent)
    SetVigilanceDial tid dial -> runStandard tid (Logic.setVigilanceDial dial)
    SelectReadiedCard tid cid -> runStandard tid (void $ Logic.searchDeckForReadiedCard cid)
    CommitVigilance tid -> runStandard tid Logic.commitVigilancePool
    AbortExplorationChallenge cid -> do
      let clearActor a =
            let cs = a.coreState
                matchesChal = case cs.revealed of
                  Just (REChallenge ch) -> ch.id == cid
                  _ -> False
                clearedDef = case cs.defending of
                  Just (ActiveDefense ch _) | ch.id == cid -> Nothing
                  other -> other
             in if matchesChal
                  then
                    a
                      & #coreState . #revealed .~ Nothing
                      & #coreState . #planned .~ Nothing
                      & #coreState . #defending .~ clearedDef
                  else a & #coreState . #defending .~ clearedDef
          actors' = Map.map clearActor game.actors
          ws' = case game.worldState of
            Just ws
              | Just tp <- ws.activeTeamworkChallenge
              , tp.activeChallenge.id == cid ->
                  ws & #activeTeamworkChallenge .~ Nothing
            other -> fromMaybe (error "no world") other
          newGame =
            game
              & #actors .~ actors'
              & (if isJust game.worldState then #worldState ?~ ws' else id)
      logEntry <- mkLogEntry SenderSystem (LogInfo "Challenge aborted.")
      let finalGame = newGame & #history %~ (++ [logEntry])
          updates = [StateUpdate aid act | (aid, act) <- Map.toList actors']
      return (finalGame, Right updates, [], [logEntry])
    AdvanceTimeManual dur -> do
      case game.worldState of
        Nothing -> return (game, Right [], [], [])
        Just ws -> do
          (ws', explEvs) <- LogicExpl.advanceTimeAndTriggerClocks dur [] ws
          let newGame = game & #worldState ?~ ws'
              logPayloads = map explorationEventToLog explEvs
          logMain <-
            mkLogEntry
              SenderGM
              (LogInfo $ "Advanced time by " <> pack (show dur) <> " (" <> formatExpeditionTime ws'.time <> ")")
          subLogs <- mapM (mkLogEntry SenderSystem) logPayloads
          let allLogs = logMain : subLogs
              gameWithLogs = newGame & #history %~ (++ allLogs)
          case ws'.focus of
            AtLocation locId -> do
              let scenarioEncounters = fromMaybe [] (Map.lookup locId ws'.locationEncounters)
                  spawnedAtLoc = maybe [] (.spawnedActors) (Map.lookup locId ws'.locationStates)
              if (not (null scenarioEncounters) || not (null spawnedAtLoc))
                && gameWithLogs.playMode == ModeExploration
                then do
                  (crisisGame, cUpdates, cEvents) <- transitionToCrisis gameWithLogs
                  logCrisis <- mkLogEntry SenderSystem (LogInfo "Encounter triggered! Transitioning to Crisis mode.")
                  return (crisisGame & #history %~ (++ [logCrisis]), Right cUpdates, cEvents, allLogs ++ [logCrisis])
                else
                  return (gameWithLogs, Right [], [], allLogs)
            _ -> return (gameWithLogs, Right [], [], allLogs)
    DrawClockManual cid -> do
      case game.worldState of
        Nothing -> return (game, Right [], [], [])
        Just ws -> do
          (ws1, mCard, drawEvs) <- LogicExpl.drawClockCard cid ws
          case mCard of
            Nothing -> do
              logEmpty <-
                mkLogEntry SenderGM (LogInfo $ "Clock deck " <> cid.unClockDeckId <> " has no cards to draw.")
              return (game & #history %~ (++ [logEmpty]), Right [], [], [logEmpty])
            Just card -> do
              let (ws2, effEvs) = LogicExpl.applyClockEventEffects card ws1
                  newGame = game & #worldState ?~ ws2
                  allEvs = drawEvs ++ effEvs
                  logPayloads = map explorationEventToLog allEvs
              logDrawn <-
                mkLogEntry
                  SenderGM
                  (LogInfo $ "Drew clock card: " <> getRawText card.name <> " — " <> toText card.narrative.summary)
              subLogs <- mapM (mkLogEntry SenderSystem) logPayloads
              let allLogs = logDrawn : subLogs
                  gameWithLogs = newGame & #history %~ (++ allLogs)
              case ws2.focus of
                AtLocation locId -> do
                  let scenarioEncounters = fromMaybe [] (Map.lookup locId ws2.locationEncounters)
                      spawnedAtLoc = maybe [] (.spawnedActors) (Map.lookup locId ws2.locationStates)
                  if (not (null scenarioEncounters) || not (null spawnedAtLoc))
                    && gameWithLogs.playMode == ModeExploration
                    then do
                      (crisisGame, cUpdates, cEvents) <- transitionToCrisis gameWithLogs
                      logCrisis <- mkLogEntry SenderSystem (LogInfo "Encounter triggered! Transitioning to Crisis mode.")
                      return (crisisGame & #history %~ (++ [logCrisis]), Right cUpdates, cEvents, allLogs ++ [logCrisis])
                    else
                      return (gameWithLogs, Right [], [], allLogs)
                _ -> return (gameWithLogs, Right [], [], allLogs)
    TransitionMode mode -> do
      case mode of
        ModeCrisis -> do
          (newGame, updates, events) <- transitionToCrisis game
          logEntry <- mkLogEntry SenderSystem (LogInfo "Play mode switched to ModeCrisis")
          let finalGame = newGame & #history %~ (++ [logEntry])
          return (finalGame, Right updates, events, [logEntry])
        ModeExploration -> do
          (newGame, updates, events) <- transitionToExploration game
          logEntry <- mkLogEntry SenderSystem (LogInfo "Play mode switched to ModeExploration")
          let finalGame = newGame & #history %~ (++ [logEntry])
          return (finalGame, Right updates, events, [logEntry])
  where
    runStandard
      :: ActorId
      -> GameM StdGen ()
      -> State StdGen (GameState, Either Text [StateUpdate], [ActorGameEvent], [LogEntry])
    runStandard targetId action = do
      (maybeEvents, newGame) <- runActorAction targetId action game
      case maybeEvents of
        Nothing -> return (game, Right [], [], []) -- Actor missing or no action
        Just events -> do
          let
            updatedActorState = case Map.lookup targetId newGame.actors of
              Just a -> a
              Nothing -> error "Actor missing after update"

            actorEvents = map (ActorGameEvent (Just targetId)) events
            stateUpdates = [StateUpdate targetId updatedActorState]

            payloads = concatMap (\evt -> eventToLogs (Just targetId) evt newGame) events

          newLogs <- mapM (\(p, aid) -> mkLogEntry (resolveSender aid game) p) payloads

          let hostiles = filter (\a -> a.actorType /= "PC") (Map.elems newGame.actors)
          if newGame.playMode == ModeCrisis && not (null hostiles) && all Logic.isDefeated hostiles
            then do
              (expGame, expUpdates, expEvents) <- transitionToExploration newGame
              logDefeated <- mkLogEntry SenderSystem (LogInfo "Hostiles defeated. Resuming exploration mode.")
              let allUpdates = stateUpdates ++ expUpdates
                  allEvents = actorEvents ++ expEvents
                  finalGame = expGame & #history %~ (++ (newLogs ++ [logDefeated]))
              return (finalGame, Right allUpdates, allEvents, newLogs ++ [logDefeated])
            else do
              let finalGame = newGame & #history %~ (++ newLogs)
              return (finalGame, Right stateUpdates, actorEvents, newLogs)

resolveSender :: Maybe ActorId -> GameState -> LogSender
resolveSender Nothing _ = SenderGM -- Default to GM
resolveSender (Just aid) game =
  case Map.lookup aid game.actors of
    Just actor -> SenderActor aid actor.name
    Nothing -> SenderActor aid "Unknown"
