module Main where

import GameTest qualified
import InMemoryTest qualified
import JsonTest qualified
import ScenarioTest qualified
import Test.Tasty (defaultMain, testGroup)

main :: IO ()
main =
  defaultMain $
    testGroup
      "CardPG Server Tests"
      [ GameTest.test_game
      , ScenarioTest.test_scenario
      , JsonTest.test_json
      , InMemoryTest.test_in_memory
      ]
