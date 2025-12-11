module Main where

import Test.Tasty (defaultMain, testGroup)
import qualified GameTest

main :: IO ()
main = defaultMain $ testGroup "CardPG Server Tests"
  [ GameTest.test_game
  ]
