{-# LANGUAGE DeriveGeneric #-}
{-# LANGUAGE DerivingStrategies #-}
{-# LANGUAGE StandaloneDeriving #-}
{-# LANGUAGE GeneralisedNewtypeDeriving #-}
{-# LANGUAGE FlexibleInstances #-}
{-# LANGUAGE ScopedTypeVariables #-}
{-# LANGUAGE DisambiguateRecordFields #-}
{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE RecordWildCards #-}
{-# LANGUAGE TypeApplications #-}
{-# OPTIONS_GHC -fno-warn-orphans #-}

module Main where

import ArbitraryInstances ()
import RuleJsonTest (prop_ruleJsonParsing)
import StatusParsingTest (test_statusParsing)
import ReadmeExamplesTest (test_readmeExamples)


import Test.Tasty
import Test.Tasty.QuickCheck
import Data.Aeson (encode, eitherDecode, ToJSON, FromJSON)

import CardPG.Core.Card
import CardPG.Core.DSL.Parser (parseRule)
import CardPG.Core.DSL.Printer (prettyRule)

main :: IO ()
main = defaultMain tests

tests :: TestTree
tests = testGroup "Tests"
  [ testProperty "CoreCard Roundtrip" $ prop_jsonRoundtrip @CoreCard
  , testProperty "ItemCard Roundtrip" $ prop_jsonRoundtrip @ItemCard
  , testProperty "NatureCard Roundtrip" $ prop_jsonRoundtrip @NatureCard
  , testProperty "TalentCard Roundtrip" $ prop_jsonRoundtrip @TalentCard
  , testProperty "EncounterCard Roundtrip" $ prop_jsonRoundtrip @EncounterCard
  , testProperty "ConsequenceCard Roundtrip" $ prop_jsonRoundtrip @ConsequenceCard
  , testProperty "DSL Roundtrip" prop_dslRoundtrip
  , testProperty "Rule JSON Object Parsing" prop_ruleJsonParsing
  , test_statusParsing
  , test_readmeExamples
  ]

prop_jsonRoundtrip :: (ToJSON a, FromJSON a, Eq a, Show a) => a -> Property
prop_jsonRoundtrip x = 
  let encoded = encode x
      decoded = eitherDecode encoded
  in counterexample (show encoded) $ decoded === Right x

prop_dslRoundtrip :: Rule -> Property
prop_dslRoundtrip r = 
  let printed = prettyRule r
      parsed = parseRule printed
  in counterexample ("Original: " ++ show r ++ "\nPrinted: " ++ show printed ++ "\nParsed: " ++ show parsed) $ parsed === Right r
