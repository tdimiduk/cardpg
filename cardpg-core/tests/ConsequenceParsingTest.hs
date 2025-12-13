{-# LANGUAGE DuplicateRecordFields #-}
{-# LANGUAGE OverloadedStrings #-}

module ConsequenceParsingTest where

import Control.Monad (when)
import Data.ByteString qualified as BS
import Data.List.NonEmpty qualified as NE
import Data.Maybe (fromMaybe)
import Data.Yaml (ParseException, decodeFileEither, encode)
import Test.Tasty
import Test.Tasty.HUnit

import CardPG.Core.Card (ConsequenceCardDSL, ConsequenceCardT (..))
import CardPG.Core.RuleDefs (DSLRule (DSLRule), RuleT (..))
import CardPG.Core.RuleInstances ()

test_consequenceParsing :: TestTree
test_consequenceParsing = testCase "Consequence Card Parsing & Roundtrip" $ do
  let path = "../data/cards/consequences/baseline.yaml"
  result <- decodeFileEither path :: IO (Either ParseException [ConsequenceCardDSL])
  case result of
    Left err -> assertFailure $ "Failed to parse consequence cards: " ++ show err
    Right cards -> do
      assertBool "Should have at least one card" (not (null cards))
      let firstCard = case cards of
            (c : _) -> c
            [] -> error "Impossible: length 1 but empty"
      -- Verify that rules are parsed as Task or Trigger, not Narrative (fallback)
      let rules = case firstCard of
            ConsequenceCard{rules = r} -> fromMaybe (error "No rules") r
      case NE.head rules of
        DSLRule (RuleTask _) -> return ()
        DSLRule (RuleTrigger _) -> return ()
        DSLRule (RuleGeneral _) -> return () -- Some might be general actions
        r -> assertFailure $ "Expected RuleTask, RuleTrigger, or RuleGeneral, got: " ++ show r

      -- Roundtrip check
      let encoded = encode cards
      original <- BS.readFile path

      when (encoded /= original) $ do
        let reformattedPath = "../data/cards/consequences/baseline.reformatted.yaml"
        BS.writeFile reformattedPath encoded
        assertFailure $
          "YAML output mismatch. Reformatted content written to "
            ++ reformattedPath
