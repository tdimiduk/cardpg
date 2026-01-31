{-# LANGUAGE OverloadedStrings #-}

module CardParsingTest (test_cardParsing) where

import Control.Monad (forM, when)
import Data.ByteString qualified as BS
import Data.List (isSuffixOf)
import Data.Yaml (ParseException, decodeFileEither, encode)
import System.Directory (listDirectory)
import System.FilePath ((</>))
import Test.Tasty
import Test.Tasty.HUnit

import Core.Card (ActorDefinition)

test_cardParsing :: IO TestTree
test_cardParsing = do
  pcFiles <- getYamlFiles "../data/cards/pc"
  monsterFiles <- getYamlFiles "../data/cards/monsters"
  let allFiles = pcFiles ++ monsterFiles
  tests <- forM allFiles $ \path -> do
    return $ testCase path $ testActorDefinitionFile path
  return $ testGroup "Card Parsing" tests

getYamlFiles :: FilePath -> IO [FilePath]
getYamlFiles dir = do
  files <- listDirectory dir
  return $ map (dir </>) $ filter (\f -> ".yaml" `isSuffixOf` f) files

testActorDefinitionFile :: FilePath -> Assertion
testActorDefinitionFile path = do
  result <- decodeFileEither path :: IO (Either ParseException ActorDefinition)
  case result of
    Left err -> assertFailure $ "Failed to parse: " ++ show err
    Right actor -> do
      -- Roundtrip check
      let encoded = encode actor
      original <- BS.readFile path
      when (encoded /= original) $ do
        let reformattedPath = path ++ ".reformatted"
        BS.writeFile reformattedPath encoded
        assertFailure $ "YAML output mismatch. Reformatted content written to " ++ reformattedPath
