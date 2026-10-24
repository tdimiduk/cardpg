module Main where

import Test.Tasty
import Test.Tasty.HUnit

import ChronometerBarTest qualified
import ExplorationBoardTest qualified
import PandocRenderTest qualified
import PlanningTest qualified
import RulesViewerTest qualified
import VigilanceAndDefenseWidgetTest qualified

main :: IO ()
main = defaultMain tests

tests :: TestTree
tests =
  testGroup
    "ClientReflex Tests"
    [ testCase "Sanity check" $ True @?= True
    , PlanningTest.tests
    , PandocRenderTest.tests
    , RulesViewerTest.tests
    , ChronometerBarTest.tests
    , ExplorationBoardTest.tests
    , VigilanceAndDefenseWidgetTest.tests
    ]
