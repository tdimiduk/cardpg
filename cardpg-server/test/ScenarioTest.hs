{-# LANGUAGE OverloadedStrings #-}

module ScenarioTest where

import Test.Tasty (TestTree, testGroup)
import Test.Tasty.HUnit (testCase, (@?=), assertBool)
import qualified Data.Map.Strict as Map
import System.Directory (getCurrentDirectory)

import CardPG.Server.Scenario (loadScenario)
import CardPG.Server.Game (GameState(..))

test_scenario :: TestTree
test_scenario = testGroup "Scenario"
  [ testCase "Load Starter Scenario" $ do
      -- Assuming we are running from project root or can access data
      -- Try to handle pathing robustly?
      cwd <- getCurrentDirectory
      -- We'll try relative path from potential roots
      let path = "../data/scenarios/starter.yaml"
      
      game <- loadScenario path
      let actorCount = Map.size (game.actors)
      actorCount @?= 2
  ]
