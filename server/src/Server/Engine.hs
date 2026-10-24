{-# LANGUAGE DuplicateRecordFields #-}
{-# LANGUAGE LambdaCase #-}
{-# LANGUAGE OverloadedRecordDot #-}

module Server.Engine
  ( runActorAction
  , concludeRound
  , revealPlannedActions
  , autoPlanForNPCs
  , transitionToCrisis
  , transitionToExploration
  , spawnLocationEncounter
  , lookupExplorationAction
  , mkChallengeFromExplorationAction
  ) where

import Control.Lens (at, ix, use, (%~), (&), (.~), (?~))
import Control.Monad (foldM, replicateM)
import Control.Monad.RWS (modify, runRWST, tell)
import Control.Monad.State (State, get, put, runState, state)
import Data.Generics.Labels ()
import Data.List (find)
import Data.List.NonEmpty qualified as NE
import Data.Map.Strict qualified as Map
import Data.Maybe (fromMaybe, isJust, isNothing, listToMaybe, mapMaybe, maybeToList)
import Data.Text (Text)
import System.Random (RandomGen, StdGen)
import System.Random.Stateful (uniform)

import Api.Types (Phase (..), PlayMode (..))
import Core.Card (Identified (..))
import Core.Card.Exploration
  ( ActionScope (..)
  , ChallengeDef (..)
  , ExplorationAction (..)
  , LocationCard (..)
  , LocationExit (..)
  , ScenarioActor (..)
  , TravelCard (..)
  , TravelExpedients (..)
  )
import Core.DSL (toText)
import Core.Keyword (keywordToText)
import Core.Logic.Bot qualified as Logic
import Core.Logic.Deck qualified as Logic
import Core.Logic.Exploration qualified as LogicExpl
import Core.Logic.Monad (GameM, runGameM)
import Core.Logic.Planning qualified as Logic
import Core.Logic.Status qualified as Logic
import Core.NonEmptyText (getRawText)
import Core.Primitives (ActorId)
import Core.State
  ( ActiveChallenge (..)
  , ActorState (..)
  , BattleRank (..)
  , ChallengeDomain (..)
  , ChallengeSource (..)
  , CoreCardState (..)
  , ExplorationFocus (..)
  , ExplorationIntent (..)
  , GameEvent (..)
  , LocationRuntimeState (..)
  , MapMode (..)
  , PlannedAction (..)
  , RevealedEffect (..)
  , SpatialState (..)
  , TableState (..)
  , TeamworkProgress (..)
  , WorldState (..)
  , emptyCoreCardState
  )
import Core.Time (Duration (..), TimeUnit (..), toMinutes)
import Server.Presenter (explorationEventToLog)
import Server.Types (ActorGameEvent (..), GameState (..), LogPayload (..), StateUpdate (..))

runActorAction
  :: ActorId -> GameM StdGen a -> GameState -> State StdGen (Maybe [GameEvent], GameState)
runActorAction tid action game =
  case Map.lookup tid game.actors of
    Nothing -> return (Nothing, game)
    Just actorState -> do
      rng <- get
      let ((_, newState, events), newRng) = runState (runRWST (runGameM action) game.env actorState) rng
      put newRng
      let newGame = game{actors = Map.insert tid newState game.actors}
      return (Just events, newGame)

-- | Mode-aware round conclusion.
concludeRound
  :: GameState
  -> State StdGen (GameState, [StateUpdate], [ActorGameEvent], [LogPayload])
concludeRound game = case game.playMode of
  ModeExploration -> concludeExplorationRound game
  ModeCrisis -> do
    (g, us, evs) <- concludeCrisisRound game
    pure (g, us, evs, [])

concludeCrisisRound :: GameState -> State StdGen (GameState, [StateUpdate], [ActorGameEvent])
concludeCrisisRound game = foldM step (game, [], []) (Map.keys game.actors)
  where
    step (g, updates, events) actorId = do
      -- 1. End Defense
      (maybeDefenseEvents, gAfterDefense) <- runActorAction actorId Logic.endDefense g
      let defEvents = maybe [] (map (ActorGameEvent (Just actorId))) maybeDefenseEvents

      -- 2. Apply Planned Move
      (maybeMoveEvents, gAfterMove) <- runActorAction actorId Logic.applyPlannedMove gAfterDefense
      let movEvents = maybe [] (map (ActorGameEvent (Just actorId))) maybeMoveEvents

      -- 3. Discard Planned Actions
      (maybeDiscardEvents, gAfterDiscard) <- runActorAction actorId Logic.discardPlannedActions gAfterMove
      let disEvents = maybe [] (map (ActorGameEvent (Just actorId))) maybeDiscardEvents

      -- 4. Draw Cards
      (maybeDrawEvents, gAfterDraw) <-
        case Map.lookup actorId gAfterDiscard.actors of
          Just actor
            | not (Logic.isDefeated actor) ->
                runActorAction actorId (Logic.drawCard >> Logic.drawCard) gAfterDiscard
          _ -> return (Nothing, gAfterDiscard)
      let drwEvents = maybe [] (map (ActorGameEvent (Just actorId))) maybeDrawEvents

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

-- | Conclude an exploration round:
-- 1. Ends defense for all actors.
-- 2. Applies world mutations (unblock exits, unlocks, travel completion, exit transitions).
-- 3. Advances time and triggers clocks (including [Loud] and explicit interrupts).
-- 4. Flushes vigilance cycles on all PCs.
-- 5. Transitions to crisis if an encounter triggers at the destination.
concludeExplorationRound
  :: GameState
  -> State StdGen (GameState, [StateUpdate], [ActorGameEvent], [LogPayload])
concludeExplorationRound game = do
  -- 1. End lingering defense for all actors
  (g1, defUpdates, defEvents) <- foldM endDefenseStep (game, [], []) (Map.keys game.actors)

  case g1.worldState of
    Nothing -> do
      (g2, pcUpdates, pcEvents) <- foldM flushPC (g1, [], []) (Map.keys g1.actors)
      let finalG = g2 & #phase .~ Planning & #roundNumber %~ (+ 1)
          allUpdates = defUpdates ++ pcUpdates
          allEvents = defEvents ++ pcEvents
      pure (finalG, allUpdates, allEvents, [])
    Just ws -> do
      -- 2. Collect planned exploration intents
      let actorIntents =
            [ (aid, intent)
            | (aid, act) <- Map.toList g1.actors
            , Just (PExploration intent) <- [act.coreState.planned]
            ]
          intents = map snd actorIntents
          mExecutedActions = mapMaybe (lookupExplorationAction ws) intents
          traversals = [targetLocId | IntentTraverseExit targetLocId <- intents]
          hasCompletedPace = any (\case IntentPace _ -> True; _ -> False) intents

      -- 3. Apply world mutations:
      -- a) Unblock exits
      let (ws1, unblockEvs) =
            foldl'
              ( \(curWs, curEvs) act -> case act.unblocks of
                  Just toLoc -> case curWs.focus of
                    AtLocation fromLoc ->
                      let (nextWs, evs) = LogicExpl.unblockExit fromLoc toLoc curWs
                       in (nextWs, curEvs ++ evs)
                    _ -> (curWs, curEvs)
                  Nothing -> (curWs, curEvs)
              )
              (ws, [])
              mExecutedActions

      -- b) Unlock follow-up actions
      let ws2 =
            foldl'
              ( \curWs act -> case act.enablesAction of
                  Just actName -> case curWs.focus of
                    AtLocation fromLoc ->
                      LogicExpl.unlockFollowUpAction fromLoc actName act.modifiesStrength curWs
                    _ -> curWs
                  Nothing -> curWs
              )
              ws1
              mExecutedActions

      -- c) Movement / Travel transitions
      let (ws3, moveEvs, travTime) =
            if hasCompletedPace
              then case LogicExpl.completeTravel ws2 of
                Right (nextWs, evs) -> (nextWs, evs, Duration 0 Minute)
                Left _ -> (ws2, [], Duration 0 Minute)
              else case traversals of
                (targetLoc : _) -> case ws2.focus of
                  AtLocation curLoc ->
                    case Map.lookup curLoc ws2.locations of
                      Just loc ->
                        case find (\e -> e.to == targetLoc) (fromMaybe [] loc.exits) of
                          Just exit -> case LogicExpl.transitionViaExit exit ws2 of
                            Right (nextWs, evs, t) -> (nextWs, evs, t)
                            Left _ -> (ws2, [], Duration 0 Minute)
                          Nothing -> (ws2, [], Duration 0 Minute)
                      Nothing -> (ws2, [], Duration 0 Minute)
                  _ -> (ws2, [], Duration 0 Minute)
                [] -> (ws2, [], Duration 0 Minute)

      -- d) Duration, Clock interrupts and time advancement
      let maxActionMins = if null mExecutedActions then 0 else maximum [toMinutes a.time | a <- mExecutedActions]
          travMins = toMinutes travTime
          extraImpactMins = maybe 0 (\tp -> toMinutes tp.totalImpactTimeAdded) ws.activeTeamworkChallenge
          totalMins = maxActionMins + travMins + extraImpactMins
          deltaDur = Duration totalMins Minute
          allTags = concat [maybe [] NE.toList a.tags | a <- mExecutedActions]
          mInterrupt = listToMaybe [i | a <- mExecutedActions, Just i <- [a.interrupt]]

      (ws4, clockEvs) <-
        if totalMins > 0
          then LogicExpl.advanceTimeWithInterrupt deltaDur allTags mInterrupt ws3
          else pure (ws3, [])

      -- e) Clear active teamwork challenge
      let wsFinal = LogicExpl.clearTeamworkChallenge ws4
          g2 = g1 & #worldState ?~ wsFinal

      -- 4. Vigilance flush and clean planned/revealed for PCs
      (g3, pcUpdates, pcEvents) <- foldM flushPC (g2, [], []) (Map.keys g2.actors)

      -- 5. Exploration log payloads
      let explEvs = unblockEvs ++ moveEvs ++ clockEvs
          explPayloads = map explorationEventToLog explEvs

      -- 6. Check for encounter at new focus
      case wsFinal.focus of
        AtLocation locId -> do
          let scenarioActs = fromMaybe [] (Map.lookup locId wsFinal.locationEncounters)
              spawnedActs = maybe [] (.spawnedActors) (Map.lookup locId wsFinal.locationStates)
              hasEncounter = not (null scenarioActs) || not (null spawnedActs)
          if hasEncounter
            then do
              (crisisG, crisisUpdates, crisisEvents) <- transitionToCrisis g3
              let allUpdates = defUpdates ++ pcUpdates ++ crisisUpdates
                  allEvents = defEvents ++ pcEvents ++ crisisEvents
              pure (crisisG, allUpdates, allEvents, explPayloads)
            else do
              let finalG = g3 & #phase .~ Planning & #roundNumber %~ (+ 1)
                  allUpdates = defUpdates ++ pcUpdates
                  allEvents = defEvents ++ pcEvents
              pure (finalG, allUpdates, allEvents, explPayloads)
        OnTravel _ _ -> do
          let finalG = g3 & #phase .~ Planning & #roundNumber %~ (+ 1)
              allUpdates = defUpdates ++ pcUpdates
              allEvents = defEvents ++ pcEvents
          pure (finalG, allUpdates, allEvents, explPayloads)
  where
    endDefenseStep (curG, curUs, curEvs) aid = do
      (mEvs, g') <- runActorAction aid Logic.endDefense curG
      let evs = maybe [] (map (ActorGameEvent (Just aid))) mEvs
          u = case Map.lookup aid g'.actors of
            Just act -> [StateUpdate aid act]
            Nothing -> []
      pure (g', curUs ++ u, curEvs ++ evs)

    flushPC (curG, curUs, curEvs) aid =
      case Map.lookup aid curG.actors of
        Just act | act.actorType == "PC" -> do
          (mEvs1, g1') <- runActorAction aid Logic.discardPlannedActions curG
          (mEvs2, g2') <- runActorAction aid (Logic.flushVigilanceCycle False) g1'
          let evs =
                maybe [] (map (ActorGameEvent (Just aid))) mEvs1
                  ++ maybe [] (map (ActorGameEvent (Just aid))) mEvs2
              u = case Map.lookup aid g2'.actors of
                Just updatedAct -> [StateUpdate aid updatedAct]
                Nothing -> []
          pure (g2', curUs ++ u, curEvs ++ evs)
        _ -> pure (curG, curUs, curEvs)

-- | Lookup an exploration action or pace defined on the active focus node in WorldState.
lookupExplorationAction
  :: WorldState
  -> ExplorationIntent
  -> Maybe ExplorationAction
lookupExplorationAction ws = \case
  IntentAction idx -> case ws.focus of
    AtLocation locId -> do
      loc <- Map.lookup locId ws.locations
      acts <- loc.actions
      if idx >= 0 && idx < length acts
        then Just (acts !! idx)
        else Nothing
    OnTravel trvId _ -> do
      trv <- Map.lookup trvId ws.travelCards
      expeds <- trv.expedients
      acts <- expeds.actions
      if idx >= 0 && idx < length acts
        then Just (acts !! idx)
        else Nothing
  IntentPace idx -> case ws.focus of
    OnTravel trvId _ -> do
      trv <- Map.lookup trvId ws.travelCards
      let paces = NE.toList trv.paces
      if idx >= 0 && idx < length paces
        then Just (paces !! idx)
        else Nothing
    _ -> Nothing
  IntentTraverseExit _ -> Nothing
  IntentPass -> Nothing

-- | Construct an ActiveChallenge from an ExplorationAction and the active location state.
mkChallengeFromExplorationAction
  :: (RandomGen g)
  => WorldState
  -> ExplorationAction
  -> State g (Maybe ActiveChallenge)
mkChallengeFromExplorationAction ws act = case act.challenge of
  Nothing -> pure Nothing
  Just cDef -> do
    cid <- state uniform
    let baseStr = cDef.strength
        locMod = case ws.focus of
          AtLocation locId -> LogicExpl.getLocationChallengeModifier locId (Just cDef.color) ws
          _ -> 0
        actMod = case ws.focus of
          AtLocation locId -> LogicExpl.getActionStrengthModifier locId (getRawText act.name) ws
          _ -> 0
        finalStr = max 1 (baseStr + locMod + actMod)
        tags = maybe [] NE.toList act.tags
        domain =
          if any (`elem` ["Environmental", "Hazard", "Terrain"]) tags
            then EnvironmentalHazard tags
            else PhysicalLabor tags
        src = CSAdHoc (getRawText act.name) (fmap toText act.narrative)
    pure $
      Just
        ActiveChallenge
          { id = cid
          , source = src
          , challengeStrength = finalStr
          , challengeColor = cDef.color
          , challengeDomain = domain
          , consequencePool = fmap (fmap keywordToText) cDef.consequences
          , timePerImpact = act.timePerImpact
          }

-- | Mode-aware reveal of planned actions.
revealPlannedActions :: GameState -> State StdGen (GameState, [ActorGameEvent])
revealPlannedActions game = case game.playMode of
  ModeExploration -> revealExplorationPlans game
  ModeCrisis -> revealCrisisPlannedActions game

revealCrisisPlannedActions :: GameState -> State StdGen (GameState, [ActorGameEvent])
revealCrisisPlannedActions game = foldM step (game, []) (Map.keys game.actors)
  where
    step (g, currentEvents) actorId = do
      (maybeEvents, newG) <- runActorAction actorId Logic.revealPlannedActions g
      case maybeEvents of
        Nothing -> return (newG, currentEvents)
        Just events -> do
          let newEvents = map (ActorGameEvent (Just actorId)) events
          return (newG, currentEvents ++ newEvents)

-- | Reveal exploration intents: groups teamwork actions into a shared challenge on WorldState,
-- creates per-actor challenges for solo/everyone actions (including travel paces),
-- and sets revealed states.
revealExplorationPlans :: GameState -> State StdGen (GameState, [ActorGameEvent])
revealExplorationPlans game = case game.worldState of
  Nothing -> revealCrisisPlannedActions game
  Just ws -> do
    let pcPlans =
          [ (aid, intent)
          | (aid, act) <- Map.toList game.actors
          , Just (PExploration intent) <- [act.coreState.planned]
          ]

    -- Check for teamwork actions among planned intents
    let teamworkActions =
          [ (aid, intent, act)
          | (aid, intent) <- pcPlans
          , Just act <- [lookupExplorationAction ws intent]
          , act.scope == ScopeTeamwork
          ]

    -- If any teamwork action exists, create a shared challenge for the first unique one
    (wsWithTeam, mTeamChallenge) <- case teamworkActions of
      ((_, _, twAct) : _) -> do
        mTwChal <- mkChallengeFromExplorationAction ws twAct
        case mTwChal of
          Just twChal -> pure (LogicExpl.startTeamworkChallenge twChal ws, Just twChal)
          Nothing -> pure (ws, Nothing)
      [] -> pure (ws, Nothing)

    -- Step through each actor in game.actors
    foldM
      (revealOneActor wsWithTeam mTeamChallenge)
      (game & #worldState ?~ wsWithTeam, [])
      (Map.keys game.actors)
  where
    revealOneActor wsAcc mTeamChal (g, currentEvents) aid =
      case Map.lookup aid g.actors of
        Nothing -> pure (g, currentEvents)
        Just actor -> case actor.coreState.planned of
          Just plan@(PExploration intent) -> case lookupExplorationAction wsAcc intent of
            Just act -> case act.scope of
              ScopeTeamwork -> case mTeamChal of
                Just teamChal -> do
                  let actor' = actor & #coreState . #revealed ?~ REChallenge teamChal
                      g' = g & #actors . at aid ?~ actor'
                      ev = ActorGameEvent (Just aid) (ActionRevealed plan (REChallenge teamChal))
                  pure (g', currentEvents ++ [ev])
                Nothing -> do
                  let actor' = actor & #coreState . #revealed ?~ REPass
                      g' = g & #actors . at aid ?~ actor'
                      ev = ActorGameEvent (Just aid) (ActionRevealed plan REPass)
                  pure (g', currentEvents ++ [ev])
              _ -> do
                -- ScopeSolo or ScopeEveryone
                mChal <- mkChallengeFromExplorationAction wsAcc act
                case mChal of
                  Just chal -> do
                    let actor' = actor & #coreState . #revealed ?~ REChallenge chal
                        g' = g & #actors . at aid ?~ actor'
                        ev = ActorGameEvent (Just aid) (ActionRevealed plan (REChallenge chal))
                    pure (g', currentEvents ++ [ev])
                  Nothing -> do
                    let actor' = actor & #coreState . #revealed ?~ REPass
                        g' = g & #actors . at aid ?~ actor'
                        ev = ActorGameEvent (Just aid) (ActionRevealed plan REPass)
                    pure (g', currentEvents ++ [ev])
            Nothing -> do
              -- IntentTraverseExit or IntentPass
              let actor' = actor & #coreState . #revealed ?~ REPass
                  g' = g & #actors . at aid ?~ actor'
                  ev = ActorGameEvent (Just aid) (ActionRevealed plan REPass)
              pure (g', currentEvents ++ [ev])
          Just _ -> do
            -- Regular combat action plan
            (maybeEvents, newG) <- runActorAction aid Logic.revealPlannedActions g
            let newEvents = maybe [] (map (ActorGameEvent (Just aid))) maybeEvents
            pure (newG, currentEvents ++ newEvents)
          Nothing -> do
            let actor' = actor & #coreState . #revealed ?~ REPass
                g' = g & #actors . at aid ?~ actor'
                ev = ActorGameEvent (Just aid) (ActionRevealed PPass REPass)
            pure (g', currentEvents ++ [ev])

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
                  let newEvents = map (ActorGameEvent (Just actorId)) events
                  return (newG, currentEvents ++ newEvents)
            else return (g, currentEvents)

--------------------------------------------------------------------------------
-- Mode Transitions
--------------------------------------------------------------------------------

-- | Commit PC vigilance cards to hand for crisis mode.
commitVigilanceToCrisis :: (RandomGen g) => GameM g ()
commitVigilanceToCrisis = do
  pool <- use (#coreState . #vigilancePool)
  mReadied <- use (#coreState . #readiedCard)
  let cardsToAdd = pool ++ maybeToList mReadied
  modify $ #coreState . #hand %~ (cardsToAdd ++)
  modify $ #coreState . #vigilancePool .~ []
  modify $ #coreState . #readiedCard .~ Nothing
  modify $ #coreState . #committedVigilance .~ False
  tell [VigilanceCommitted]

-- | Reset PC state when leaving crisis mode: discard hand and sync vigilance pool to dial.
resetPCToExploration :: (RandomGen g) => GameM g ()
resetPCToExploration = do
  handCards <- use (#coreState . #hand)
  modify $ #coreState . #discard %~ (handCards ++)
  modify $ #coreState . #hand .~ []
  modify $ #coreState . #planned .~ Nothing
  modify $ #coreState . #revealed .~ Nothing
  modify $ #coreState . #committedVigilance .~ False
  Logic.syncVigilanceToDial

-- | Instantiate a fresh ActorState clone from a template with new IDs and specified coordinates.
freshActorState :: ActorState -> Text -> Int -> Int -> Maybe Int -> State StdGen ActorState
freshActorState template actName x y mHandSize = do
  newDeckIds <- replicateM (length template.coreState.deck) (state uniform)
  newHandIds <- replicateM (length template.coreState.hand) (state uniform)
  let freshDeck = [c & #id .~ cid | (cid, c) <- zip newDeckIds template.coreState.deck]
      freshHand = [c & #id .~ cid | (cid, c) <- zip newHandIds template.coreState.hand]
      (finalHand, finalDeck) = case mHandSize of
        Just sz | null freshHand -> splitAt sz (freshHand ++ freshDeck)
        _ -> (freshHand, freshDeck)

  newAssetIds <- replicateM (Map.size template.tableState.assets) (state uniform)
  let freshAssets =
        Map.fromList
          [ (newCid, (Identified newCid card, assetSt))
          | (newCid, (_, (Identified _ card, assetSt))) <-
              zip newAssetIds (Map.toList template.tableState.assets)
          ]
      initialRank = if y == 0 then FrontRank else BackRank

  pure
    template
      { name = actName
      , coreState =
          template.coreState
            { deck = finalDeck
            , hand = finalHand
            , discard = []
            , planned = Nothing
            , defending = Nothing
            , revealed = Nothing
            }
      , tableState = template.tableState{assets = freshAssets}
      , spatial = template.spatial{posX = x, posY = y, rank = Just initialRank}
      , plannedMove = Nothing
      , plannedRank = Nothing
      }

-- | Spawn encounter actors registered at the party's current location.
spawnLocationEncounter :: GameState -> State StdGen (GameState, [StateUpdate], [ActorGameEvent])
spawnLocationEncounter g =
  case g.worldState of
    Nothing -> pure (g, [], [])
    Just ws -> case ws.focus of
      OnTravel _ _ -> pure (g, [], [])
      AtLocation locId -> do
        let scenarioActors = fromMaybe [] (Map.lookup locId ws.locationEncounters)
            mLocSt = Map.lookup locId ws.locationStates
            extraNames = case mLocSt of
              Nothing -> []
              Just locSt ->
                let initNames = map (\(s :: ScenarioActor) -> s.name) scenarioActors
                    removeFirst [] ys = ys
                    removeFirst (x : xs) ys = removeFirst xs (removeOne x ys)
                    removeOne _ [] = []
                    removeOne target (y : ys)
                      | target == y = ys
                      | otherwise = y : removeOne target ys
                 in removeFirst initNames locSt.spawnedActors
            extraScenarioActors = [ScenarioActor name "" 0 0 Nothing | name <- extraNames]
            allToSpawn = scenarioActors ++ extraScenarioActors
        if null allToSpawn
          then pure (g, [], [])
          else do
            (g', updates, events) <- foldM (spawnOneActor ws) (g, [], []) allToSpawn
            let ws' =
                  ws
                    & #locationEncounters . at locId .~ Nothing
                    & #locationStates . ix locId . #spawnedActors .~ []
                gFinal = g' & #worldState ?~ ws'
            pure (gFinal, updates, events)
  where
    spawnOneActor ws (curG, curUpdates, curEvents) scAct = do
      newAid <- state uniform
      case Map.lookup scAct.name ws.actorTemplates of
        Just template -> do
          freshAct <- freshActorState template scAct.name scAct.x scAct.y scAct.initialHandSize
          let g' = curG & #actors . at newAid ?~ freshAct
              u = StateUpdate newAid freshAct
              ev = ActorGameEvent (Just newAid) (CardsCreated freshAct.coreState.hand)
          pure (g', curUpdates ++ [u], curEvents ++ [ev])
        Nothing -> do
          let alreadyExists = any (\a -> a.name == scAct.name) (Map.elems curG.actors)
          if alreadyExists
            then pure (curG, curUpdates, curEvents)
            else do
              let defaultAct =
                    ActorState
                      { name = scAct.name
                      , actorType = "Monster"
                      , coreState = emptyCoreCardState
                      , tableState = TableState Map.empty []
                      , spatial =
                          SpatialState scAct.x scAct.y 1 Nothing (Just (if scAct.y == 0 then FrontRank else BackRank))
                      , plannedMove = Nothing
                      , plannedRank = Nothing
                      }
              let g' = curG & #actors . at newAid ?~ defaultAct
                  u = StateUpdate newAid defaultAct
              pure (g', curUpdates ++ [u], curEvents)

-- | Transition game state from Exploration to Crisis mode:
-- 1. Moves PC vigilance pool + readied cards into Round 1 hand.
-- 2. Spawns location encounter actors (if at an encounter node).
-- 3. Sets mapMode to MapModeRank if any hostile has coordinates (0, 0).
-- 4. Runs NPC auto-planning for Round 1.
transitionToCrisis :: GameState -> State StdGen (GameState, [StateUpdate], [ActorGameEvent])
transitionToCrisis game = do
  -- 1. For each PC, commit vigilance pool + readiedCard into hand
  (g1, pcUpdates, pcEvents) <- foldM stepPC (game, [], []) (Map.keys game.actors)

  -- 2. Spawn encounters if any at current location
  (g2, spawnUpdates, spawnEvents) <- spawnLocationEncounter g1

  -- 3. Check for rank mode: if any actor has x == 0 && y == 0, set mapMode = Just MapModeRank
  let allActors = Map.elems g2.actors
      shouldRank = any (\a -> a.spatial.posX == 0 && a.spatial.posY == 0) allActors
      effectiveMapMode = if shouldRank then Just MapModeRank else g2.mapMode

  -- 4. Update actor ranks if in rank mode
  let updateRank a =
        if effectiveMapMode == Just MapModeRank && isNothing a.spatial.rank
          then
            let r = if a.spatial.posY == 0 then FrontRank else BackRank
             in a & #spatial . #rank ?~ r
          else a
      g3 =
        g2
          & #actors %~ Map.map updateRank
          & #mapMode .~ effectiveMapMode
          & #playMode .~ ModeCrisis
          & #phase .~ Planning
          & #roundNumber .~ (if g2.playMode == ModeCrisis then g2.roundNumber else 1)

  -- 5. Auto-plan for NPCs in crisis
  (g4, planEvents) <- autoPlanForNPCs g3

  let allUpdates = pcUpdates ++ spawnUpdates ++ [StateUpdate aid act | (aid, act) <- Map.toList g4.actors]
      dedupUpdates = Map.elems $ Map.fromList [(u.actorId, u) | u <- allUpdates]
      allEvents = pcEvents ++ spawnEvents ++ planEvents

  pure (g4, dedupUpdates, allEvents)
  where
    stepPC (g, us, evs) aid =
      case Map.lookup aid g.actors of
        Just act | act.actorType == "PC" -> do
          (mEvs, g') <- runActorAction aid commitVigilanceToCrisis g
          let actEvs = maybe [] (map (ActorGameEvent (Just aid))) mEvs
          let u = case Map.lookup aid g'.actors of
                Just updated -> [StateUpdate aid updated]
                Nothing -> []
          pure (g', us ++ u, evs ++ actEvs)
        _ -> pure (g, us, evs)

-- | Transition game state from Crisis back to Exploration mode:
-- 1. Moves PC hands to discard and refills vigilance pools up to dial.
-- 2. Removes defeated hostile NPCs from the active arena.
-- 3. Resets mapMode to Nothing and phase to Planning.
transitionToExploration :: GameState -> State StdGen (GameState, [StateUpdate], [ActorGameEvent])
transitionToExploration game = do
  -- 1. For each PC, discard hand to discard and sync vigilance to dial
  (g1, pcUpdates, pcEvents) <- foldM stepPC (game, [], []) (Map.keys game.actors)

  -- 2. Remove defeated hostiles (or all hostiles)
  let remainingActors = Map.filter (\a -> a.actorType == "PC") g1.actors
      g2 =
        g1
          & #actors .~ remainingActors
          & #playMode .~ ModeExploration
          & #phase .~ Planning
          & #mapMode .~ Nothing

  let updates = pcUpdates ++ [StateUpdate aid act | (aid, act) <- Map.toList g2.actors]
      dedupUpdates = Map.elems $ Map.fromList [(u.actorId, u) | u <- updates]

  pure (g2, dedupUpdates, pcEvents)
  where
    stepPC (g, us, evs) aid =
      case Map.lookup aid g.actors of
        Just act | act.actorType == "PC" -> do
          (mEvs, g') <- runActorAction aid resetPCToExploration g
          let actEvs = maybe [] (map (ActorGameEvent (Just aid))) mEvs
          let u = case Map.lookup aid g'.actors of
                Just updated -> [StateUpdate aid updated]
                Nothing -> []
          pure (g', us ++ u, evs ++ actEvs)
        _ -> pure (g, us, evs)
