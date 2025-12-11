{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE OverloadedLabels #-}

module StatusParsingTest where

import qualified Control.Monad
import qualified Data.ByteString as BS
import qualified Data.List.NonEmpty as NE
import Data.Maybe (fromMaybe)
import Data.Yaml (ParseException, decodeFileEither, encode)
import Test.Tasty
import Test.Tasty.HUnit
import Optics ((^.))

import CardPG.Core.Card (CoreCard, CoreCardT (..))
import CardPG.Core.RuleDefs (DSLRule (DSLRule), RuleT (..))
import CardPG.Core.RuleInstances ()

test_statusParsing :: TestTree
test_statusParsing = testCase "Status Card Parsing & Roundtrip" $ do
  let path = "../data/cards/status/core.yaml"
  result <- decodeFileEither path :: IO (Either ParseException [CoreCard])
  case result of
    Left err -> assertFailure $ "Failed to parse status cards: " ++ show err
    Right cards -> do
      case cards of
        [] -> assertFailure "Should have at least one card"
        fatigue : _ -> do
          -- Verify that rules are parsed as General, not Narrative (fallback)
          let rules = fromMaybe (error "No rules") (fatigue ^. #rules)
          case NE.head rules of
            DSLRule (RuleGeneral _) -> return ()
            DSLRule (RuleTask _) -> return ()
            r -> assertFailure $ "Expected RuleGeneral or RuleTask, got: " ++ show r

          -- Roundtrip check
          let encoded = encode cards
          original <- BS.readFile path

          Control.Monad.when (encoded /= original) $ do
            let reformattedPath = "../data/cards/status/core.reformatted.yaml"
            BS.writeFile reformattedPath encoded
            assertFailure $ "YAML output mismatch. Reformatted content written to " ++ reformattedPath
