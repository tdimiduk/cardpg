{-# LANGUAGE OverloadedStrings #-}

module ScenarioTest where

import Data.Map.Strict qualified as Map
import Data.Maybe (fromMaybe)
import System.Directory (getCurrentDirectory)
import System.Environment (lookupEnv)
import Test.Tasty (TestTree, testGroup)
import Test.Tasty.HUnit (assertBool, testCase, (@?=))

import CardPG.Server.Game (GameState (..))
import CardPG.Server.Scenario (loadScenario)

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

        (game, _) <- loadScenario path
        let actorCount = Map.size (game.actors)
        actorCount @?= 2
    ]
