{-# LANGUAGE DisambiguateRecordFields #-}

{- HLINT ignore "Redundant id" -}

module Server.Scenario where

import Control.Lens ((&), (.~), (?~))
import Control.Monad (foldM, forM_)
import Control.Monad.IO.Class (liftIO)
import Control.Monad.State
  ( StateT
  , get
  , lift
  , put
  , runState
  , runStateT
  )
import Data.Aeson (FromJSON)
import Data.Generics.Labels ()
import Data.List.NonEmpty (toList)
import Data.Map.Strict (Map)
import Data.Map.Strict qualified as Map
import Data.Maybe (fromMaybe)
import Data.Text (Text)
import Data.Text qualified as T
import Data.Yaml (ParseException, decodeFileEither, decodeFileThrow)
import GHC.Generics (Generic)
import System.Directory (doesDirectoryExist, doesFileExist)
import System.FilePath (takeDirectory, takeFileName, (</>))
import System.Random (StdGen, mkStdGen, newStdGen, uniform)
import System.Random.Stateful (Uniform (..))

import Api.Types (PlayMode (..))
import Core.Card
  ( ActorDefinition (..)
  , CoreCard (..)
  , Identified (..)
  , ItemCard (..)
  , MasterCard (..)
  , resolveActorDeck
  )
import Core.Card.Exploration (ModuleManifest (..), ScenarioActor (..))
import Core.Hardcoded (fatigueCard)
import Core.Primitives (ActorId, CardInstanceId, EquipSlot (..))
import Core.State
  ( ActorState (..)
  , AssetState (..)
  , CoreCardState (..)
  , GameEnv (..)
  , TableCard (..)
  , TableState (..)
  )
import Core.State qualified as State
import Server.Engine (autoPlanForNPCs)
import Server.Game (GameState (..), addActor, emptyGame)
import Server.Loader (loadMasterCatalog, loadModule)

import Core.Util (shuffleListM)

-- | Definition of a scenario file
data Scenario = Scenario
  { name :: Text
  , actors :: [ScenarioActor]
  }
  deriving (Show, Eq, Generic)

instance FromJSON Scenario

-- | Check whether the given path targets an exploration module directory or manifest.
isModuleTarget :: FilePath -> IO Bool
isModuleTarget path = do
  isDir <- doesDirectoryExist path
  if isDir
    then doesFileExist (path </> "module.yaml")
    else
      if takeFileName path == "module.yaml"
        then pure True
        else do
          res <- decodeFileEither path :: IO (Either ParseException ModuleManifest)
          case res of
            Right _ -> pure True
            Left _ -> pure False

-- | Load a scenario or exploration module from a path or directory.
-- This initializes the game state, loads all actors, and generates UUIDs.
loadScenario :: FilePath -> Maybe Int -> IO (GameState, StdGen)
loadScenario path maybeSeed = do
  catalog <- findMasterCatalog (takeDirectory path)
  loadScenarioWithCatalog catalog path maybeSeed

-- | Load a scenario or exploration module with an explicit master card catalog.
loadScenarioWithCatalog :: Map Text MasterCard -> FilePath -> Maybe Int -> IO (GameState, StdGen)
loadScenarioWithCatalog catalog path maybeSeed = do
  isMod <- isModuleTarget path
  if isMod
    then loadModuleScenarioWithCatalog catalog path maybeSeed
    else loadCombatScenarioWithCatalog catalog path maybeSeed

-- | Load an exploration module directory, initializing WorldState and Vigilance pools.
loadModuleScenarioWithCatalog
  :: Map Text MasterCard -> FilePath -> Maybe Int -> IO (GameState, StdGen)
loadModuleScenarioWithCatalog catalog path maybeSeed = do
  isDir <- doesDirectoryExist path
  let modDir = if isDir then path else takeDirectory path
  modRes <- loadModule modDir
  (manifest, worldSt) <- case modRes of
    Left err -> ioError $ userError err
    Right res -> pure res
  rng <- case maybeSeed of
    Just seed -> return $ mkStdGen seed
    Nothing -> newStdGen

  let env =
        GameEnv
          { fatigueCardTemplate = fatigueCard
          , statusCardTemplates = Map.empty
          , consequenceCardTemplates = Map.empty
          }

  let initialGame =
        (emptyGame env)
          { playMode = ModeExploration
          , worldState = Just worldSt
          , mapMode = Nothing
          }

  ((_, finalGameState), finalRng) <-
    runStateT
      (runStateT (loadScenarioActors catalog modDir (manifest.startingActors)) initialGame)
      rng

  -- Load encounter actor templates for all location encounters in manifest
  let encounterActorsList = concat (Map.elems manifest.locationEncounters)
  (templateMap, templateRng) <-
    foldM
      ( \(accMap, curRng) scAct ->
          if Map.member scAct.name accMap
            then pure (accMap, curRng)
            else do
              let actorPath = modDir </> scAct.file
              (actSt, nextRng) <-
                runStateT
                  (loadAndInstantiateActor catalog actorPath scAct.x scAct.y scAct.initialHandSize)
                  curRng
              pure (Map.insert scAct.name actSt accMap, nextRng)
      )
      (Map.empty, finalRng)
      encounterActorsList

  -- For actors in ExplorationMode:
  -- Initialize Vigilance pool from deck (hand remains empty, dial = 2, pool has 2 cards)
  let explorationActors = Map.map initExplorationActor finalGameState.actors
      worldWithTemplates =
        worldSt
          & #actorTemplates .~ templateMap
          & #locationEncounters .~ manifest.locationEncounters
      gameWithVigilance =
        finalGameState
          & #actors .~ explorationActors
          & #worldState ?~ worldWithTemplates

  return (gameWithVigilance, templateRng)

-- | Set up actor state for exploration mode: hand is emptied, vigilance dial defaults to 2,
-- and cards are drawn into the face-down vigilance pool.
initExplorationActor :: ActorState -> ActorState
initExplorationActor st =
  let cs = st.coreState
      fullDeck = cs.hand ++ cs.deck
      dial = cs.vigilanceDial
      (pool, remDeck) = splitAt dial fullDeck
   in st
        { coreState =
            cs
              { hand = []
              , deck = remDeck
              , vigilancePool = pool
              , readiedCard = Nothing
              , committedVigilance = False
              }
        }

-- | Load a combat-only scenario (e.g., starter.yaml), preserving backwards compatibility.
loadCombatScenarioWithCatalog
  :: Map Text MasterCard -> FilePath -> Maybe Int -> IO (GameState, StdGen)
loadCombatScenarioWithCatalog catalog path maybeSeed = do
  scenario :: Scenario <- decodeFileThrow path
  rng <- case maybeSeed of
    Just seed -> return $ mkStdGen seed
    Nothing -> newStdGen

  let env =
        GameEnv
          { fatigueCardTemplate = fatigueCard
          , statusCardTemplates = Map.empty
          , consequenceCardTemplates = Map.empty
          }

  let initialGame = emptyGame env

  -- We use StateT GameState (StateT StdGen IO) to accumulate actors into the game
  ((_, finalGameState), finalRng) <-
    runStateT
      (runStateT (loadScenarioActors catalog (takeDirectory path) (scenario.actors)) initialGame)
      rng

  -- Auto-plan for NPCs at start
  let ((gameWithPlans, _), plannedRng) = runState (autoPlanForNPCs finalGameState) finalRng
  return (gameWithPlans, plannedRng)

-- | Look for a master card catalog in standard locations relative to the scenario file or repo root.
findMasterCatalog :: FilePath -> IO (Map Text MasterCard)
findMasterCatalog baseDir = do
  let candidates =
        [ baseDir </> "../cards/master"
        , baseDir </> "cards/master"
        , baseDir </> "../../cards/master"
        , "data/cards/master"
        , "../data/cards/master"
        ]
  findFirst candidates
  where
    findFirst [] = pure Map.empty
    findFirst (dir : rest) = do
      exists <- doesDirectoryExist dir
      if exists
        then loadMasterCatalog dir
        else findFirst rest

-- | Load a list of actors and add them to the game state
loadScenarioActors
  :: Map Text MasterCard -> FilePath -> [ScenarioActor] -> StateT GameState (StateT StdGen IO) ()
loadScenarioActors catalog baseDir actorsList = do
  forM_ actorsList $ \actorDef -> do
    let actorPath = baseDir </> actorDef.file

    -- Generate random ActorId
    -- We are in StateT GameState (StateT StdGen IO)
    -- stateUniform is in StateT StdGen IO
    tid <- lift stateUniform :: StateT GameState (StateT StdGen IO) ActorId

    -- Load actor definition (IO).
    -- Instantiation requires RNG state.
    actorState <-
      lift $ loadAndInstantiateActor catalog actorPath actorDef.x actorDef.y actorDef.initialHandSize

    gst <- get
    let updatedGame = addActor tid actorState gst
    put updatedGame

loadAndInstantiateActor
  :: Map Text MasterCard -> FilePath -> Int -> Int -> Maybe Int -> StateT StdGen IO ActorState
loadAndInstantiateActor catalog path x y handSize = do
  def :: ActorDefinition <- liftIO $ decodeFileThrow path
  case resolveActorDeck catalog def of
    Left err ->
      liftIO $
        ioError $
          userError $
            "Failed to resolve actor deck in " ++ path ++ " (" ++ T.unpack def.name ++ "): " ++ err
    Right _ ->
      instantiateActor catalog def x y handSize

-- | Convert a static ActorDefinition into a dynamic ActorState by resolving the deck against the catalog and generating IDs
instantiateActor
  :: Map Text MasterCard -> ActorDefinition -> Int -> Int -> Maybe Int -> StateT StdGen IO ActorState
instantiateActor catalog def x y maybeHandSize = do
  resolvedCards <- case resolveActorDeck catalog def of
    Left err ->
      liftIO $
        ioError $
          userError $
            "Failed to resolve deck for actor '" ++ T.unpack def.name ++ "': " ++ err
    Right cs -> pure cs
  instantiateActorWithCards def resolvedCards x y maybeHandSize

-- | Convert a static ActorDefinition and resolved cards into a dynamic ActorState by generating IDs
instantiateActorWithCards
  :: ActorDefinition -> [CoreCard] -> Int -> Int -> Maybe Int -> StateT StdGen IO ActorState
instantiateActorWithCards def cards x y maybeHandSize = do
  -- Process Deck (Core Cards)
  deckCards <- processCards cards
  shuffledDeck <- shuffleListM deckCards

  let handSize = fromMaybe 0 maybeHandSize
  let (initialHand, remainingDeck) = splitAt handSize shuffledDeck

  let nameVal = def.name
  let tagsList = maybe [] toList (def.tags)
  let actorTypeVal
        | "pc" `elem` tagsList = "PC"
        | "monster" `elem` tagsList = "Monster"
        | otherwise = "NPC"

  let coreSt =
        State.emptyCoreCardState
          { deck = remainingDeck
          , hand = initialHand
          }

  -- Process Table Cards (Items, Nature)
  itemInstances <- processCards (def.items)
  natureInstances <- processCards (def.nature)
  -- TODO: Add talents logic when available in ActorDefinition if needed

  let itemAssets =
        [ (c.id, (Identified c.id (TCItem c.content), determineItemState c.content))
        | c <- itemInstances
        ]
  let natureAssets =
        [ (c.id, (Identified c.id (TCNature c.content), Trait))
        | c <- natureInstances
        ]

  let tableAssets = Map.fromList (itemAssets ++ natureAssets)

  let tableSt =
        State.TableState
          { assets = tableAssets
          , consequences = []
          }

  return $
    ActorState
      { name = nameVal
      , actorType = actorTypeVal
      , coreState = coreSt
      , tableState = tableSt
      , spatial = State.SpatialState{posX = x, posY = y, size = 1, mapId = Nothing, rank = Nothing}
      , plannedMove = Nothing
      , plannedRank = Nothing
      }

-- | Helper to instantiate a list of cards
processCards :: [card] -> StateT StdGen IO [Identified CardInstanceId card]
processCards cards = do
  ids <- mapM (const stateUniform) cards
  return [Identified cid c | (cid, c) <- zip ids cards]

-- | Helper to get a uniform value from the stateful generator
stateUniform :: (Uniform a) => StateT StdGen IO a
stateUniform = do
  g <- get
  let (val, newG) = uniform g
  put newG
  return val

determineItemState :: ItemCard -> AssetState
determineItemState item =
  case item.tags of
    Just ts | "Equipped" `elem` toList ts -> Equipped SlotUnspecified
    _ -> InCollection

-- | Load a full GameState from a saved game YAML file
loadSavedGame :: FilePath -> IO GameState
loadSavedGame = decodeFileThrow
