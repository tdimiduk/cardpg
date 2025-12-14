module Main where

import Test.Tasty (defaultMain, testGroup)
import qualified GameTest
import qualified ScenarioTest
import qualified JsonTest

main :: IO ()
main = defaultMain $ testGroup "CardPG Server Tests"
  [ GameTest.test_game
  , ScenarioTest.test_scenario
  , JsonTest.test_json
  ]
