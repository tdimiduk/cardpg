module Main where

import Test.Tasty (defaultMain, testGroup)
import qualified GameTest
import qualified ScenarioTest

main :: IO ()
main = defaultMain $ testGroup "CardPG Server Tests"
  [ GameTest.test_game
  , ScenarioTest.test_scenario
  ]
