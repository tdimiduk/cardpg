{-# LANGUAGE DisambiguateRecordFields #-}

{- HLINT ignore "Redundant id" -}

module Server.Scenario where

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

import Core.Card
  ( ActorDefinition
  , CoreCard
  , Identified (..)
  , ItemCard
  , NatureCard
  , TalentCard
  )
import Core.Card qualified as Card
import Core.Hardcoded (fatigueCard)
import Core.Primitives (ActorId, CardInstanceId, EquipSlot (..), TargetId)
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

import Core.Util (shuffleListM)

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
  def :: ActorDefinition <- liftIO $ decodeFileThrow path
  instantiateActor def x y handSize

-- | Convert a static ActorDefinition into a dynamic ActorState by generating IDs
instantiateActor :: ActorDefinition -> Int -> Int -> Maybe Int -> StateT StdGen IO ActorState
instantiateActor def x y maybeHandSize = do
  -- Process Deck (Core Cards)
  deckCards <- processCards (def.deck)
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
        State.CoreCardState
          { deck = remainingDeck
          , hand = initialHand
          , discard = []
          , defending = Nothing
          , inPlay = Map.empty
          , planned = Nothing
          , revealed = Nothing
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
      , spatial = State.SpatialState{posX = x, posY = y, size = 1, mapId = Nothing}
      , plannedMove = Nothing
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
