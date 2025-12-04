{-# LANGUAGE OverloadedStrings #-}
module ConsequenceParsingTest where

import Data.Yaml (decodeFileEither, ParseException, encode)
import qualified Data.ByteString as BS
import Test.Tasty
import Test.Tasty.HUnit
import CardPG.Core.Card (ConsequenceCard(..))
import CardPG.Core.RuleInstances () -- Import orphan instances
import CardPG.Core.RuleDefs (Rule(..))
import qualified Data.List.NonEmpty as NE
import Data.Maybe (fromMaybe)

test_consequenceParsing :: TestTree
test_consequenceParsing = testCase "Consequence Card Parsing & Roundtrip" $ do
  let path = "../data/cards/consequences/baseline.yaml"
  result <- decodeFileEither path :: IO (Either ParseException [ConsequenceCard])
  case result of
    Left err -> assertFailure $ "Failed to parse consequence cards: " ++ show err
    Right cards -> do
      case cards of
        [] -> assertFailure $ "Should have at least one card"
        firstCard:_ -> do
          -- Verify that rules are parsed as Task or Trigger, not Narrative (fallback)
          let rules = fromMaybe (error "No rules") (_rules firstCard)
          case NE.head rules of
              RuleTask _ -> return ()
              RuleTrigger _ -> return ()
              RuleGeneral _ -> return () -- Some might be general actions
              r -> assertFailure $ "Expected RuleTask, RuleTrigger, or RuleGeneral, got: " ++ show r

          -- Roundtrip check
          let encoded = encode cards
          original <- BS.readFile path

          if encoded /= original
              then do
              let reformattedPath = "../data/cards/consequences/baseline.reformatted.yaml"
              BS.writeFile reformattedPath encoded
              assertFailure $ "YAML output mismatch. Reformatted content written to " ++ reformattedPath
              else
              return ()
