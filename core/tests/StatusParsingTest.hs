{-# LANGUAGE OverloadedLabels #-}
{-# LANGUAGE OverloadedStrings #-}

module StatusParsingTest where

import Control.Lens ((^.))
import Control.Monad qualified
import Data.ByteString qualified as BS
import Data.Generics.Labels ()
import Data.List.NonEmpty qualified as NE
import Data.Maybe (fromMaybe)
import Data.Yaml (ParseException, decodeFileEither, encode)
import System.Directory (doesFileExist)
import Test.Tasty
import Test.Tasty.HUnit

import Core.Card (CoreCard (..))
import Core.Rules (Rule (..))

test_statusParsing :: TestTree
test_statusParsing = testCase "Status Card Parsing & Roundtrip" $ do
  let basePath = "data/cards/status/core.yaml"
  exists <- doesFileExist basePath
  let path = if exists then basePath else "../" ++ basePath
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
            RuleGeneral _ -> return ()
            RuleTask _ -> return ()
            r -> assertFailure $ "Expected RuleGeneral or RuleTask, got: " ++ show r

          -- Roundtrip check
          let encoded = encode cards
          original <- BS.readFile path

          Control.Monad.when (encoded /= original) $ do
            let reformattedPath = "../data/cards/status/core.yaml.reformatted"
            BS.writeFile reformattedPath encoded
            assertFailure $ "YAML output mismatch. Reformatted content written to " ++ reformattedPath
