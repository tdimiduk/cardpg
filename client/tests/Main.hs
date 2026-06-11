module Main where

import Test.Tasty
import Test.Tasty.HUnit

import PlanningTest qualified

main :: IO ()
main = defaultMain tests

tests :: TestTree
tests =
  testGroup
    "ClientReflex Tests"
    [ testCase "Sanity check" $ True @?= True
    , PlanningTest.tests
    ]
