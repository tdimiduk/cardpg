{-# LANGUAGE DeriveGeneric #-}
{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE DuplicateRecordFields #-}
{-# LANGUAGE DisambiguateRecordFields #-}
{-# LANGUAGE NamedFieldPuns #-}
{-# LANGUAGE OverloadedRecordDot #-}
{-# LANGUAGE ScopedTypeVariables #-}

module CardPG.Server.Scenario where

import Control.Monad (forM, forM_)
import Control.Monad.IO.Class (liftIO)
import Control.Monad.State (StateT, evalStateT, execStateT, get, put, runStateT)
import Data.Aeson (FromJSON)
import qualified Data.Map.Strict as Map
import Data.Text (Text)
import qualified Data.Text as T
import Data.Yaml (decodeFileThrow)
import GHC.Generics (Generic)
import Optics (set, (&), (.~), (?~), at)
import System.FilePath ((</>), takeDirectory)
import System.Random (StdGen, newStdGen, getStdGen, uniform)
import System.Random.Stateful (Uniform (..), uniformM)

import CardPG.Core.Card (ActorDefinition, CoreCard, ItemCard, NatureCard, TalentCard)
import qualified CardPG.Core.Card as Card
import CardPG.Core.Hardcoded (fatigueCard)
import CardPG.Core.Primitives (CardInstanceId, TargetId, EquipSlot (..))
import CardPG.Core.State
  ( ActorState (..)
  , AssetState (..)
  , CoreCardState (..)
  , GameEnv (..)
  , TableCard (..)
  , TableState (..)
  )
import qualified CardPG.Core.State as State
import CardPG.Server.Game (GameState (..), addActor, emptyGame)

-- | Definition of an actor within a scenario
data ScenarioActor = ScenarioActor
  { id :: Text
  , file :: FilePath
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
  
  let env = GameEnv
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
    actorState <- liftIO $ loadActorState actorPath
    
    -- For now, we generate a random TargetId for the actor.
    -- In the future, we might want to map the ScenarioActor.id to this TargetId explicitly
    -- or store it in a lookup table if we need to reference them by name.
    gameState <- get
    let (tid, newRng) = uniform (rng gameState) :: (TargetId, StdGen)
    put $ gameState { rng = newRng }
    
    let updatedGame = addActor tid actorState (gameState { rng = newRng })
    put updatedGame

-- | Load a single actor from a YAML file and instantiate it into an ActorState
loadActorState :: FilePath -> IO ActorState
loadActorState path = do
  -- Parse the static definition
  def :: ActorDefinition <- decodeFileThrow path
  
  -- Instantiate with fresh UUIDs
  rng <- newStdGen
  evalStateT (instantiateActor def) rng

-- | Convert a static ActorDefinition into a dynamic ActorState by generating IDs
instantiateActor :: ActorDefinition -> StateT StdGen IO ActorState
instantiateActor def = do
  -- Process Deck (Core Cards)
  (deckIds, coreRegistry) <- processCards (def.deck)
  
  let coreSt = State.CoreCardState
        { deck = deckIds
        , hand = []
        , discard = []
        , defending = []
        , inPlay = Map.empty
        , registry = coreRegistry
        }
        
  -- Process Table Cards (Items, Nature)
  -- Note: We map different card types to TableCard
  (itemIds, itemRegistry) <- processTableCards TCItem (def.items) InCollection
  (natureIds, natureRegistry) <- processTableCards TCNature (def.nature) Trait
  -- TODO: Add talents logic when available in ActorDefinition if needed
  
  let tableReg = itemRegistry `Map.union` natureRegistry
  let tableAssets = Map.fromList $ 
                      [(id, InCollection) | id <- itemIds] ++
                      [(id, Trait) | id <- natureIds]
  
  let tableSt = State.TableState
        { assets = tableAssets
        , registry = tableReg
        }
        
  return $ ActorState
    { coreState = coreSt
    , tableState = tableSt
    }

-- | Helper to instantiate a list of cards
processCards :: [card] -> StateT StdGen IO ([CardInstanceId], Map.Map CardInstanceId card)
processCards cards = do
  ids <- mapM (\_ -> stateUniform) cards
  let registry = Map.fromList $ zip ids cards
  return (ids, registry)

-- | Helper specifically for TableCards which need wrapping and AssetState mapping
-- actually processCards is generic enough for the registry, but we need to wrap the card.
processTableCards 
  :: (card -> TableCard) 
  -> [card] 
  -> AssetState 
  -> StateT StdGen IO ([CardInstanceId], Map.Map CardInstanceId TableCard)
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
