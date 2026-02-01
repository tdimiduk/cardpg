{-# LANGUAGE OverloadedStrings #-}

module CardParsingTest (test_cardParsing) where

import Control.Monad (forM, when)
import Data.ByteString qualified as BS
import Data.List (isSuffixOf)
import Data.Yaml (ParseException, decodeFileEither, encode)
import System.Directory (doesDirectoryExist, listDirectory)
import System.FilePath ((</>))
import Test.Tasty
import Test.Tasty.HUnit

import Core.Card (ActorDefinition)

test_cardParsing :: IO TestTree
test_cardParsing = do
  pcFiles <- getYamlFiles "data/cards/pc"
  monsterFiles <- getYamlFiles "data/cards/monsters"
  let allFiles = pcFiles ++ monsterFiles
  tests <- forM allFiles $ \path -> do
    return $ testCase path $ testActorDefinitionFile path
  return $ testGroup "Card Parsing" tests

getYamlFiles :: FilePath -> IO [FilePath]
getYamlFiles dir = do
  -- Try to find the directory, handling both "cabal run" from root and "ghci" or other contexts
  -- We'll try the direct path first (relative to CWD), and if it fails, maybe try with "../" prefix if we were in core/
  -- actually, the previous error was "../data/cards/pc: does not exist" when running from root.
  -- "data/cards/pc" exists from root.
  let candidates = [dir, "core" </> dir, "../" ++ dir]

  -- This is a bit hacky but simpler than robust discovery.
  -- We just want it to work for "cabal run test:core-test" from root.
  -- The original code used "../data/cards/pc" which implies running from "core/".
  -- When running from root, it should be "data/cards/pc".

  -- Let's try to list specifically the likely correct path based on cwd
  dirExists <- doesDirectoryExist dir
  let actualDir = if dirExists then dir else "../" ++ dir

  files <- listDirectory actualDir
  return $ map (actualDir </>) $ filter (\f -> ".yaml" `isSuffixOf` f) files

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
