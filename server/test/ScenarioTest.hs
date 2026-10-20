{-# LANGUAGE OverloadedRecordDot #-}
{-# LANGUAGE OverloadedStrings #-}

module ScenarioTest where

import Data.Map.Strict qualified as Map
import Data.Maybe (fromMaybe, isJust)
import System.Directory (doesDirectoryExist, doesFileExist)
import System.Environment (lookupEnv)
import System.FilePath ((</>))
import Test.Tasty (TestTree, testGroup)
import Test.Tasty.HUnit (assertBool, testCase, (@?=))

import Api.Types (PlayMode (..))
import Core.Card.Exploration (LocationId (..), ModuleId (..))
import Core.State (ActorState (..), CoreCardState (..), ExplorationFocus (..), WorldState (..))
import Server.Game (GameState (..))
import Server.Scenario (loadScenario)

resolvePath :: FilePath -> IO FilePath
resolvePath rel = do
  dExists <- doesDirectoryExist rel
  fExists <- doesFileExist rel
  if dExists || fExists
    then pure rel
    else pure (".." </> rel)

test_scenario :: TestTree
test_scenario =
  testGroup
    "Scenario"
    [ testCase "Load Starter Scenario (Combat Mode)" $ do
        scenarioFileEnv <- lookupEnv "CARDPG_SCENARIO_FILE"
        defaultPath <- resolvePath "data/scenarios/starter.yaml"
        let path = fromMaybe defaultPath scenarioFileEnv

        (game, _) <- loadScenario path Nothing
        let actorCount = Map.size game.actors
        actorCount @?= 2
        game.playMode @?= ModeCrisis
        assertBool "WorldState should be Nothing in combat scenario" (isNothing game.worldState)
        let pcs = [a | a <- Map.elems game.actors, a.actorType == "PC"]
            npcs = [a | a <- Map.elems game.actors, a.actorType /= "PC"]
        case (pcs, npcs) of
          ([pc], [npc]) -> do
            length pc.coreState.hand @?= 4
            assertBool "NPC auto-planned in combat mode" (isJust npc.coreState.planned)
          _ -> assertBool "Expected 1 PC and 1 NPC" False
    , testCase "Load Exploration Module (Crag-Gallows)" $ do
        modPath <- resolvePath "data/modules/crag_gallows"
        (game, _) <- loadScenario modPath Nothing
        game.playMode @?= ModeExploration
        assertBool "WorldState should be Just in exploration module" (isJust game.worldState)
        case game.worldState of
          Nothing -> assertBool "Missing WorldState" False
          Just ws -> do
            ws.moduleId @?= Just (ModuleId "crag_gallows")
            ws.focus @?= AtLocation (LocationId "haven_crow_roost")
            Map.size ws.locations @?= 4
            Map.size ws.travelCards @?= 1
            assertBool "Has site_activity_clock" (Map.member "site_activity_clock" ws.clockDecks)
            assertBool "Has wilderness_clock" (Map.member "wilderness_clock" ws.clockDecks)
        Map.size game.actors @?= 1
        case Map.elems game.actors of
          [vallhach] -> do
            vallhach.coreState.hand @?= []
            vallhach.coreState.vigilanceDial @?= 2
            length vallhach.coreState.vigilancePool @?= 2
          _ -> assertBool "Expected exactly 1 starting actor" False
    , testCase "Deterministic Load" $ do
        scenarioFileEnv <- lookupEnv "CARDPG_SCENARIO_FILE"
        defaultPath <- resolvePath "data/scenarios/starter.yaml"
        let path = fromMaybe defaultPath scenarioFileEnv
        let seed = 42

        (game1, _) <- loadScenario path (Just seed)
        (game2, _) <- loadScenario path (Just seed)

        -- Check that actor IDs and hands are identical
        let actors1 = Map.keys game1.actors
        let actors2 = Map.keys game2.actors
        actors1 @?= actors2

        -- Check deep equality
        game1.actors @?= game2.actors
    ]
