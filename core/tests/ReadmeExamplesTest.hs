{-# LANGUAGE OverloadedStrings #-}

module ReadmeExamplesTest where

import Data.Text qualified as T
import Data.Text.IO qualified as TIO
import System.Directory (doesFileExist)
import Test.Tasty
import Test.Tasty.HUnit

import Core.DSL.RuleParser (parseRule)

test_readmeExamples :: TestTree
test_readmeExamples = testCase "README Syntax Examples" $ do
  let baseReadmePath = "data/cards/README.md"
  exists <- doesFileExist baseReadmePath
  let readmePath = if exists then baseReadmePath else "../" ++ baseReadmePath
  content <- TIO.readFile readmePath
  let ls = T.lines content
      -- Filter lines that look like examples
      -- Note: The indentation might vary slightly, so we trim first to check prefix
      isExampleHeader :: T.Text -> Bool
      isExampleHeader = T.isPrefixOf "- _Example:_" . T.strip
      examples = filter isExampleHeader ls

      cleanExample line =
        let
          -- Remove the prefix part
          stripped = T.strip line
          withoutPrefix = T.drop (T.length "- _Example:_ ") stripped
          -- Remove backticks
          withoutBackticks = T.replace "`" "" withoutPrefix
         in
          T.strip withoutBackticks

  mapM_ (checkExample . cleanExample) examples

checkExample :: T.Text -> Assertion
checkExample ex = do
  let result = parseRule ex
  case result of
    Left err -> assertFailure $ "Failed to parse example: " ++ T.unpack ex ++ "\nError: " ++ err
    Right _ -> return ()
