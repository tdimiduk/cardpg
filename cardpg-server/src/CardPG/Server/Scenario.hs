{-# LANGUAGE DisambiguateRecordFields #-}
{-# LANGUAGE NamedFieldPuns #-}

module CardPG.Server.Scenario where

import Control.Monad (forM, forM_)
import Control.Monad.IO.Class (liftIO)
import Control.Monad.State (StateT, evalStateT, execStateT, get, put, runStateT)
import Data.Aeson (FromJSON)
import Data.List.NonEmpty (toList)
import Data.Map.Strict qualified as Map
import Data.Text (Text)
import Data.Text qualified as T
import Data.Yaml (decodeFileThrow)
import GHC.Generics (Generic)
import Optics (at, set, (&), (.~), (?~))
import System.FilePath (takeDirectory, (</>))
import System.Random (StdGen, getStdGen, newStdGen, uniform)
import System.Random.Stateful (Uniform (..), uniformM)

import CardPG.Core.Card (ActorDefinition, CoreCard, ItemCard, NatureCard, TalentCard)
import CardPG.Core.Card qualified as Card
import CardPG.Core.Hardcoded (fatigueCard)
import CardPG.Core.Primitives (CardInstanceId, EquipSlot (..), TargetId, ActorId)
import CardPG.Core.State
  ( ActorState (..)
  , AssetState (..)
  , CoreCardState (..)
  , GameEnv (..)
  , TableCard (..)
  , TableState (..)
  )
import CardPG.Core.State qualified as State
import CardPG.Server.Game (GameState (..), addActor, emptyGame)

-- | Definition of an actor within a scenario
data ScenarioActor = ScenarioActor
  { name :: Text
  , file :: FilePath
  , x :: Int
  , y :: Int
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
loadScenario :: FilePath -> IO GameState
loadScenario path = do
  scenario :: Scenario <- decodeFileThrow path
  rng <- newStdGen

  let env =
        GameEnv
          { fatigueCardTemplate = fatigueCard
          }

  let initialGame = emptyGame env rng

  -- We use StateT GameState to accumulate actors into the game
  execStateT (loadScenarioActors (takeDirectory path) (scenario.actors)) initialGame

-- | Load a list of actors and add them to the game state
loadScenarioActors :: FilePath -> [ScenarioActor] -> StateT GameState IO ()
loadScenarioActors baseDir actorsList = do
  forM_ actorsList $ \actorDef -> do
    let actorPath = baseDir </> actorDef.file

    -- For now, we generate a random TargetId for the actor.
    -- In the future, we might want to map the ScenarioActor.id to this TargetId explicitly
    -- or store it in a lookup table if we need to reference them by name.
    gameState <- get
    let (tid, newRng) = uniform (gameState.rng) :: (ActorId, StdGen)
    put $ gameState{rng = newRng}

    actorState <- liftIO $ loadActorState actorPath (actorDef.x) (actorDef.y)

    let updatedGame = addActor tid actorState (gameState{rng = newRng})
    put updatedGame

-- | Load a single actor from a YAML file and instantiate it into an ActorState
loadActorState :: FilePath -> Int -> Int -> IO ActorState
loadActorState path x y = do
  -- Parse the static definition
  def :: ActorDefinition <- decodeFileThrow path

  -- Instantiate with fresh UUIDs
  rng <- newStdGen
  evalStateT (instantiateActor def x y) rng

-- | Convert a static ActorDefinition into a dynamic ActorState by generating IDs
instantiateActor :: ActorDefinition -> Int -> Int -> StateT StdGen IO ActorState
instantiateActor def x y = do
  -- Process Deck (Core Cards)
  (deckIds, coreRegistry) <- processCards (def.deck)

  let nameVal = def.name
  let tagsList = maybe [] toList (def.tags)
  let actorTypeVal =
        if "pc" `elem` tagsList
          then "PC"
          else
            if "monster" `elem` tagsList
              then "Monster"
              else "NPC"

  let coreSt =
        State.CoreCardState
          { deck = deckIds
          , hand = []
          , discard = []
          , defending = []
          , inPlay = Map.empty
          , registry = coreRegistry
          , planned = Nothing
          }

  -- Process Table Cards (Items, Nature)
  -- Note: We map different card types to TableCard
  (itemIds, itemRegistry) <- processTableCards TCItem (def.items) InCollection
  (natureIds, natureRegistry) <- processTableCards TCNature (def.nature) Trait
  -- TODO: Add talents logic when available in ActorDefinition if needed

  let tableReg = itemRegistry `Map.union` natureRegistry
  let tableAssets =
        Map.fromList $
          [(id, InCollection) | id <- itemIds]
            ++ [(id, Trait) | id <- natureIds]

  let tableSt =
        State.TableState
          { assets = tableAssets
          , registry = tableReg
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
  ids <- mapM (\_ -> stateUniform) cards
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
  ids <- mapM (\_ -> stateUniform) cards
  let registry = Map.fromList $ zip ids (map wrapper cards)
  return (ids, registry)

-- | Helper to get a uniform value from the stateful generator
stateUniform :: (Uniform a) => StateT StdGen IO a
stateUniform = do
  g <- get
  let (val, newG) = uniform g
  put newG
  return val
