module Main where

import Test.Tasty (defaultMain, testGroup)
import qualified EngineTest

main :: IO ()
main = defaultMain $ testGroup "CardPG Server Tests"
  [ EngineTest.tests
  ]
