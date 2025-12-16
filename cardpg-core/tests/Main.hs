{-# LANGUAGE DerivingStrategies #-}
{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE TypeApplications #-}
{-# OPTIONS_GHC -fno-warn-orphans #-}

module Main where

import Data.Aeson (FromJSON, ToJSON, eitherDecode, encode)
import Test.Tasty
import Test.Tasty.QuickCheck

import CardPG.Core.Card
import CardPG.Core.DSL.Parser (parseRule)
import CardPG.Core.DSL.Printer (prettyRule)
import CardPG.Core.LogicTest (test_logic)

import ArbitraryInstances ()
import ConsequenceParsingTest (test_consequenceParsing)
import ReadmeExamplesTest (test_readmeExamples)
import ResolutionTests (test_resolutionCycle)
import RuleJsonTest (prop_ruleJsonParsing, prop_tableStateJsonStructure)
import StateTests (test_stateTests)
import StatusParsingTest (test_statusParsing)

main :: IO ()
main = defaultMain tests

tests :: TestTree
tests =
  testGroup
    "Tests"
    [ testProperty "CoreCard Roundtrip" $ prop_jsonRoundtrip @CoreCard
    , testProperty "ItemCard Roundtrip" $ prop_jsonRoundtrip @ItemCard
    , testProperty "NatureCard Roundtrip" $ prop_jsonRoundtrip @NatureCard
    , testProperty "TalentCard Roundtrip" $ prop_jsonRoundtrip @TalentCard
    , testProperty "EncounterCard Roundtrip" $ prop_jsonRoundtrip @EncounterCard
    , testProperty "ConsequenceCard Roundtrip" $ prop_jsonRoundtrip @ConsequenceCard
    , testProperty "DSL Roundtrip" prop_dslRoundtrip
    , testProperty "Rule JSON Object Parsing" prop_ruleJsonParsing
    , testProperty "TableState JSON Structure" prop_tableStateJsonStructure
    , test_statusParsing
    , test_consequenceParsing
    , test_readmeExamples
    , test_stateTests
    , test_resolutionCycle
    , test_logic
    ]

prop_jsonRoundtrip :: (ToJSON a, FromJSON a, Eq a, Show a) => a -> Property
prop_jsonRoundtrip x =
  let encoded = encode x
      decoded = eitherDecode encoded
   in counterexample (show encoded) $ decoded === Right x

prop_dslRoundtrip :: DSLBase -> Property
prop_dslRoundtrip r =
  let printed = prettyRule r
      parsed = parseRule printed
   in counterexample
        ("Original: " ++ show r ++ "\nPrinted: " ++ show printed ++ "\nParsed: " ++ show parsed)
        $ parsed === Right r
