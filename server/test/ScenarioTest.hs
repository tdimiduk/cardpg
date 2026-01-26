{-# LANGUAGE OverloadedStrings #-}

module ScenarioTest where

import Data.Map.Strict qualified as Map
import Data.Maybe (fromMaybe)
import System.Directory (getCurrentDirectory)
import System.Environment (lookupEnv)
import Test.Tasty (TestTree, testGroup)
import Test.Tasty.HUnit (assertBool, testCase, (@?=))

import Server.Game (GameState (..))
import Server.Scenario (loadScenario)

test_scenario :: TestTree
test_scenario =
  testGroup
    "Scenario"
    [ testCase "Load Starter Scenario" $ do
        -- Assuming we are running from project root or can access data
        -- Try to handle pathing robustly?
        cwd <- getCurrentDirectory
        -- We'll try relative path from potential roots, or env var
        scenarioFileEnv <- lookupEnv "CARDPG_SCENARIO_FILE"
        let path = fromMaybe "../data/scenarios/starter.yaml" scenarioFileEnv

        (game, _) <- loadScenario path Nothing
        let actorCount = Map.size (game.actors)
        actorCount @?= 2
    , testCase "Deterministic Load" $ do
        scenarioFileEnv <- lookupEnv "CARDPG_SCENARIO_FILE"
        let path = fromMaybe "../data/scenarios/starter.yaml" scenarioFileEnv
        let seed = 42

        (game1, _) <- loadScenario path (Just seed)
        (game2, _) <- loadScenario path (Just seed)

        -- Check that actor IDs and hands are identical
        let actors1 = Map.keys (game1.actors)
        let actors2 = Map.keys (game2.actors)
        actors1 @?= actors2

        -- Check deep equality (or sufficient equality)
        -- We can just check the whole actors map if it derives Eq (it does)
        (game1.actors) @?= (game2.actors)
    ]
