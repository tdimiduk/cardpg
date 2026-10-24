module Main where

import ExportTraceTest qualified
import GameTest qualified
import InMemoryTest qualified
import LoaderTest qualified
import ModeTransitionTest qualified
import ScenarioTest qualified
import Test.Tasty (defaultMain, testGroup)

main :: IO ()
main =
  defaultMain $
    testGroup
      "CardPG Server Tests"
      [ GameTest.test_game
      , ScenarioTest.test_scenario
      , ModeTransitionTest.test_mode_transition
      , LoaderTest.test_loader
      , InMemoryTest.test_in_memory
      , ExportTraceTest.test_export_trace
      ]
