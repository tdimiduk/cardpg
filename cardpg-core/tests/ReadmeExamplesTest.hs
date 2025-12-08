{-# LANGUAGE OverloadedStrings #-}

module ReadmeExamplesTest where

import qualified Data.Text as T
import qualified Data.Text.IO as TIO
import Test.Tasty
import Test.Tasty.HUnit

import CardPG.Core.DSL.Parser (parseRule)

test_readmeExamples :: TestTree
test_readmeExamples = testCase "README Syntax Examples" $ do
  content <- TIO.readFile "../data/cards/README.md"
  let ls = T.lines content
      -- Filter lines that look like examples
      -- Note: The indentation might vary slightly, so we trim first to check prefix
      examples = filter (\l -> T.isPrefixOf "- _Example:_" (T.strip l)) ls

      cleanExample line =
        let
          -- Remove the prefix part
          stripped = T.strip line
          withoutPrefix = T.drop (T.length "- _Example:_ ") stripped
          -- Remove backticks
          withoutBackticks = T.replace "`" "" withoutPrefix
         in
          T.strip withoutBackticks

  mapM_ checkExample (map cleanExample examples)

checkExample :: T.Text -> Assertion
checkExample ex = do
  let result = parseRule ex
  case result of
    Left err -> assertFailure $ "Failed to parse example: " ++ T.unpack ex ++ "\nError: " ++ err
    Right _ -> return ()
