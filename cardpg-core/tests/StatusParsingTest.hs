{-# LANGUAGE OverloadedStrings #-}
module StatusParsingTest where

import Data.Yaml (decodeFileEither, ParseException, encode)
import qualified Data.ByteString as BS
import qualified Data.ByteString.Char8 as BSC
import Test.Tasty
import Test.Tasty.HUnit
import CardPG.Core.Card (CoreCard(..))
import CardPG.Core.RuleInstances () -- Import orphan instances
import CardPG.Core.RuleDefs (Rule(..))
import qualified Data.List.NonEmpty as NE
import Data.Maybe (fromMaybe)

test_statusParsing :: TestTree
test_statusParsing = testCase "Status Card Parsing & Roundtrip" $ do
  let path = "../data/cards/status/core.yaml"
  result <- decodeFileEither path :: IO (Either ParseException [CoreCard])
  case result of
    Left err -> assertFailure $ "Failed to parse status cards: " ++ show err
    Right cards -> do
      assertBool "Should have at least one card" (not (null cards))
      
      -- Verify that rules are parsed as General, not Narrative (fallback)
      let fatigue = head cards
      let rules = fromMaybe (error "No rules") (_rules fatigue)
      case NE.head rules of
        RuleGeneral _ -> return ()
        r -> assertFailure $ "Expected RuleGeneral, got: " ++ show r

      -- Roundtrip check
      let encoded = encode cards
      original <- BS.readFile path
      
      if encoded /= original
        then do
          let reformattedPath = "../data/cards/status/core.reformatted.yaml"
          BS.writeFile reformattedPath encoded
          assertFailure $ "YAML output mismatch. Reformatted content written to " ++ reformattedPath
        else
          return ()
