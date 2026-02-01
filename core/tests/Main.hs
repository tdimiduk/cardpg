{-# LANGUAGE DerivingStrategies #-}
{-# LANGUAGE OverloadedStrings #-}
{-# OPTIONS_GHC -fno-warn-orphans #-}

module Main where

import Data.Aeson (FromJSON, ToJSON, eitherDecode, encode)
import Test.Tasty
import Test.Tasty.QuickCheck

import Core.Card
import Core.DSL.TextRep (TextRep (..), parseText)
import Core.LogicTest (test_logic)

import ArbitraryInstances ()
import CardParsingTest (test_cardParsing)
import ConsequenceParsingTest (test_consequenceParsing)
import PlanningTests (test_planningLogic)
import ReadmeExamplesTest (test_readmeExamples)
import ResolutionTests (test_resolutionCycle)
import StateTests (test_stateTests)
import StatusParsingTest (test_statusParsing)

main :: IO ()
main = do
  cardTests <- test_cardParsing
  defaultMain (tests cardTests)

tests :: TestTree -> TestTree
tests cardTests =
  testGroup
    "Tests"
    [ -- testProperty "CoreCard Roundtrip" $ prop_jsonRoundtrip @CoreCard
      -- , testProperty "ItemCard Roundtrip" $ prop_jsonRoundtrip @ItemCard
      -- , testProperty "NatureCard Roundtrip" $ prop_jsonRoundtrip @NatureCard
      -- , testProperty "TalentCard Roundtrip" $ prop_jsonRoundtrip @TalentCard
      -- , testProperty "EncounterCard Roundtrip" $ prop_jsonRoundtrip @EncounterCard
      -- , testProperty "ConsequenceCard Roundtrip" $ prop_jsonRoundtrip @ConsequenceCard
      testProperty "DSL Roundtrip" prop_dslRoundtrip
    , test_statusParsing
    , test_consequenceParsing
    , test_readmeExamples
    , test_stateTests
    , test_resolutionCycle
    , test_logic
    , test_planningLogic
    , cardTests
    ]

prop_jsonRoundtrip :: (ToJSON a, FromJSON a, Eq a, Show a) => a -> Property
prop_jsonRoundtrip x =
  let encoded = encode x
      decoded = eitherDecode encoded
   in counterexample (show encoded) $ decoded === Right x

prop_dslRoundtrip :: Rule -> Property
prop_dslRoundtrip r =
  let printed = toText r
      parsed = parseText printed
   in counterexample
        ("Original: " ++ show r ++ "\nPrinted: " ++ show printed ++ "\nParsed: " ++ show parsed)
        $ parsed === Right r
