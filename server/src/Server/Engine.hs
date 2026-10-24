{-# LANGUAGE OverloadedRecordDot #-}

module Server.Engine
  ( runActorAction
  , concludeRound
  , revealPlannedActions
  , autoPlanForNPCs
  , transitionToCrisis
  , transitionToExploration
  , spawnLocationEncounter
  ) where

import Control.Lens (at, ix, use, (%~), (&), (.~), (?~))
import Control.Monad (foldM, replicateM)
import Control.Monad.RWS (modify, runRWST, tell)
import Control.Monad.State (State, get, put, runState, state)
import Data.Generics.Labels ()
import Data.Map.Strict qualified as Map
import Data.Maybe (fromMaybe, isJust, isNothing, maybeToList)
import Data.Text (Text)
import System.Random (RandomGen, StdGen)
import System.Random.Stateful (uniform)

import Api.Types (Phase (..), PlayMode (..))
import Core.Card (Identified (..))
import Core.Card.Exploration (ScenarioActor (..))
import Core.Logic.Bot qualified as Logic
import Core.Logic.Deck qualified as Logic
import Core.Logic.Monad (GameM, runGameM)
import Core.Logic.Planning qualified as Logic
import Core.Logic.Status qualified as Logic
import Core.Primitives (ActorId)
import Core.State
  ( ActorState (..)
  , BattleRank (..)
  , CoreCardState (..)
  , ExplorationFocus (..)
  , GameEvent (..)
  , LocationRuntimeState (..)
  , MapMode (..)
  , SpatialState (..)
  , TableState (..)
  , WorldState (..)
  , emptyCoreCardState
  )
import Server.Types (ActorGameEvent (..), GameState (..), StateUpdate (..))

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

concludeRound :: GameState -> State StdGen (GameState, [StateUpdate], [ActorGameEvent])
concludeRound game = foldM step (game, [], []) (Map.keys game.actors)
  where
    step (g, updates, events) actorId = do
      -- 1. End Defense (new)
      (maybeDefenseEvents, gAfterDefense) <- runActorAction actorId Logic.endDefense g
      let defEvents = maybe [] (map (ActorGameEvent (Just actorId))) maybeDefenseEvents

      -- 2. Apply Planned Move (existing)
      (maybeMoveEvents, gAfterMove) <- runActorAction actorId Logic.applyPlannedMove gAfterDefense
      let movEvents = maybe [] (map (ActorGameEvent (Just actorId))) maybeMoveEvents

      -- 3. Discard Planned Actions (existing)
      (maybeDiscardEvents, gAfterDiscard) <- runActorAction actorId Logic.discardPlannedActions gAfterMove
      let disEvents = maybe [] (map (ActorGameEvent (Just actorId))) maybeDiscardEvents

      -- 4. Draw Cards (new)
      (maybeDrawEvents, gAfterDraw) <-
        case Map.lookup actorId gAfterDiscard.actors of
          Just actor
            | not (Logic.isDefeated actor) ->
                runActorAction actorId (Logic.drawCard >> Logic.drawCard) gAfterDiscard
          _ -> return (Nothing, gAfterDiscard)
      let drwEvents = maybe [] (map (ActorGameEvent (Just actorId))) maybeDrawEvents

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
          let newEvents = map (ActorGameEvent (Just actorId)) events
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
