{-# LANGUAGE DisambiguateRecordFields #-}

module CardPG.Server.Scenario where

import Control.Monad (forM, forM_)
import Control.Monad.IO.Class (liftIO)
import Control.Monad.State
  ( State
  , StateT
  , evalStateT
  , execStateT
  , get
  , lift
  , put
  , runState
  , runStateT
  )
import Data.Aeson (FromJSON)
import Data.List.NonEmpty (toList)
import Data.Map.Strict qualified as Map
import Data.Maybe (fromMaybe)
import Data.Text (Text)
import Data.Text qualified as T
import Data.Yaml (decodeFileThrow)
import GHC.Generics (Generic)
import Optics (at, set, (&), (.~), (?~))
import System.FilePath (takeDirectory, (</>))
import System.Random (StdGen, getStdGen, newStdGen, uniform)
import System.Random.Stateful (Uniform (..), uniformM)

import CardPG.Core.Card
  ( ActorDefinition
  , ActorDefinitionDSL
  , CoreCard
  , ItemCard
  , NatureCard
  , TalentCard
  )
import CardPG.Core.Card qualified as Card
import CardPG.Core.Conversion (compileActorDefinition)
import CardPG.Core.Hardcoded (fatigueCard)
import CardPG.Core.Primitives (ActorId, CardInstanceId, EquipSlot (..), TargetId)
import CardPG.Core.State
  ( ActorState (..)
  , AssetState (..)
  , CoreCardState (..)
  , GameEnv (..)
  , TableCard (..)
  , TableState (..)
  )
import CardPG.Core.State qualified as State
import CardPG.Server.Engine (autoPlanForNPCs)
import CardPG.Server.Game (GameState (..), addActor, emptyGame)

import CardPG.Core.Util (shuffleListM)

-- | Definition of an actor within a scenario
data ScenarioActor = ScenarioActor
  { name :: Text
  , file :: FilePath
  , x :: Int
  , y :: Int
  , initialHandSize :: Maybe Int
  }
  deriving (Show, Eq, Generic)

instance FromJSON ScenarioActor

-- | Definition of a scenario file
data Scenario = Scenario
  { name :: Text
  , actors :: [ScenarioActor]
  }
  deriving (Show, Eq, Generic)

instance FromJSON Scenario

-- | Load a scenario from a YAML file.
-- This initializes the game state, loads all actors, and generates UUIDs.
loadScenario :: FilePath -> IO (GameState, StdGen)
loadScenario path = do
  scenario :: Scenario <- decodeFileThrow path
  rng <- newStdGen

  let env =
        GameEnv
          { fatigueCardTemplate = fatigueCard
          , statusCardTemplates = Map.empty
          , consequenceCardTemplates = Map.empty
          }

  let initialGame = emptyGame env

  -- We use StateT GameState (StateT StdGen IO) to accumulate actors into the game
  ((_, finalGameState), finalRng) <-
    runStateT (runStateT (loadScenarioActors (takeDirectory path) (scenario.actors)) initialGame) rng

  -- Auto-plan for NPCs at start
  let ((gameWithPlans, _), plannedRng) = runState (autoPlanForNPCs finalGameState) finalRng
  return (gameWithPlans, plannedRng)

-- | Load a list of actors and add them to the game state
loadScenarioActors :: FilePath -> [ScenarioActor] -> StateT GameState (StateT StdGen IO) ()
loadScenarioActors baseDir actorsList = do
  forM_ actorsList $ \actorDef -> do
    let actorPath = baseDir </> actorDef.file

    -- Generate random ActorId
    -- We are in StateT GameState (StateT StdGen IO)
    -- stateUniform is in StateT StdGen IO
    tid <- lift stateUniform :: StateT GameState (StateT StdGen IO) ActorId

    -- Load actor definition (IO).
    -- Instantiation requires RNG state.
    -- loadActorState now needs to return a state action or we liftIO deeply?

    -- Let's helper: loadAndInstantiate :: FilePath -> ... -> StateT StdGen IO ActorState
    actorState <-
      lift $ loadAndInstantiateActor actorPath actorDef.x actorDef.y actorDef.initialHandSize

    gst <- get
    let updatedGame = addActor tid actorState gst
    put updatedGame

loadAndInstantiateActor :: FilePath -> Int -> Int -> Maybe Int -> StateT StdGen IO ActorState
loadAndInstantiateActor path x y handSize = do
  dsl :: ActorDefinitionDSL <- liftIO $ decodeFileThrow path
  let def = compileActorDefinition dsl
  instantiateActor def x y handSize

-- | Load a single actor from a YAML file and instantiate it into an ActorState

-- | Convert a static ActorDefinition into a dynamic ActorState by generating IDs
instantiateActor :: ActorDefinition -> Int -> Int -> Maybe Int -> StateT StdGen IO ActorState
instantiateActor def x y maybeHandSize = do
  -- Process Deck (Core Cards)
  (deckIds, coreRegistry) <- processCards (def.deck)
  shuffledDeckIds <- shuffleListM deckIds

  let handSize = fromMaybe 0 maybeHandSize
  let (initialHand, remainingDeck) = splitAt handSize shuffledDeckIds

  let nameVal = def.name
  let tagsList = maybe [] toList (def.tags)
  let actorTypeVal
        | "pc" `elem` tagsList = "PC"
        | "monster" `elem` tagsList = "Monster"
        | otherwise = "NPC"

  let coreSt =
        State.CoreCardState
          { deck = remainingDeck
          , hand = initialHand
          , discard = []
          , defending = []
          , inPlay = Map.empty
          , registry = coreRegistry
          , planned = Nothing
          , revealed = Nothing
          }

  -- Process Table Cards (Items, Nature)
  -- Note: We map different card types to TableCard
  (itemIds, itemRegistry) <- processTableCards TCItem (def.items) InCollection
  (natureIds, natureRegistry) <- processTableCards TCNature (def.nature) Trait
  -- TODO: Add talents logic when available in ActorDefinition if needed

  let tableReg = itemRegistry `Map.union` natureRegistry
  let tableAssets =
        Map.fromList $
          zipWith (\id item -> (id, determineItemState item)) itemIds (def.items)
            ++ [(id, Trait) | id <- natureIds]

  let tableSt =
        State.TableState
          { assets = tableAssets
          , registry = tableReg
          , consequences = []
          , consequenceRegistry = Map.empty
          }

  return $
    ActorState
      { name = nameVal
      , actorType = actorTypeVal
      , coreState = coreSt
      , tableState = tableSt
      , spatial = State.SpatialState{posX = x, posY = y, size = 1, mapId = Nothing}
      , plannedMove = Nothing
      }

-- | Helper to instantiate a list of cards
processCards :: [card] -> StateT StdGen IO ([CardInstanceId], Map.Map CardInstanceId card)
processCards cards = do
  ids <- mapM (const stateUniform) cards
  let registry = Map.fromList $ zip ids cards
  return (ids, registry)

-- | Helper specifically for TableCards which need wrapping and AssetState mapping
-- actually processCards is generic enough for the registry, but we need to wrap the card.
processTableCards ::
  (card -> TableCard) ->
  [card] ->
  AssetState ->
  StateT StdGen IO ([CardInstanceId], Map.Map CardInstanceId TableCard)
processTableCards wrapper cards defaultState = do
  ids <- mapM (const stateUniform) cards
  let registry = Map.fromList $ zip ids (map wrapper cards)
  return (ids, registry)

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
