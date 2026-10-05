module Main where

import ExportTraceTest qualified
import GameTest qualified
import InMemoryTest qualified
import ScenarioTest qualified
import Test.Tasty (defaultMain, testGroup)

main :: IO ()
main =
  defaultMain $
    testGroup
      "CardPG Server Tests"
      [ GameTest.test_game
      , ScenarioTest.test_scenario
      , InMemoryTest.test_in_memory
      , ExportTraceTest.test_export_trace
      ]
