{-# LANGUAGE OverloadedRecordDot #-}
{-# LANGUAGE OverloadedStrings #-}

module Main (main) where

import Core.Glossary
import Data.Text (Text)
import KeywordMod hiding (main)
import Test.Tasty
import Test.Tasty.HUnit

main :: IO ()
main = defaultMain tests

tests :: TestTree
tests =
  testGroup
    "tools-hs tests"
    [ test_glossaryParser
    , test_chunking
    , test_normalization
    , test_renaming
    ]

sampleMarkdown :: Text
sampleMarkdown =
  "# Keyword Glossary\n\
  \\n\
  \Intro text.\n\
  \\n\
  \## The Three Colors\n\
  \\n\
  \### Color\n\
  \\n\
  \_Aliases: Colors_\n\
  \\n\
  \How approaches are classified.\n\
  \\n\
  \#### Red\n\
  \\n\
  \One of the game's [[Colors]].\n"

test_glossaryParser :: TestTree
test_glossaryParser =
  testGroup
    "Glossary Parser"
    [ testCase "Parses categories, aliases, and themes correctly" $ do
        let g = parseGlossaryText sampleMarkdown
        assertEqual "Total entries" 2 (length (allEntries g))

        case lookupGlossary "Color" g of
          Nothing -> assertFailure "Did not find 'Color'"
          Just e -> do
            assertEqual "Canonical" "Color" e.canonical
            assertEqual "Slug" "color" e.slug
            assertEqual "Aliases" ["Colors"] e.aliases
            assertEqual "Category" "The Three Colors" e.category
            assertEqual "Summary" "How approaches are classified." e.summary
            assertEqual "Theme is Nothing" Nothing e.theme

        case lookupGlossary "Red" g of
          Nothing -> assertFailure "Did not find 'Red'"
          Just e -> do
            assertEqual "Canonical" "Red" e.canonical
            assertEqual "Theme is red" (Just "red") e.theme
    ]

test_chunking :: TestTree
test_chunking =
  testGroup
    "Line Chunking"
    [ testCase "Separates protected markdown links and wikilinks from regular text" $ do
        let line = "See [[Color]] and [Link](url.md) here"
            chunks = chunkLine line
        assertEqual
          "Chunks"
          [ Unprotected "See "
          , Protected "[[Color]]"
          , Unprotected " and "
          , Protected "[Link](url.md)"
          , Unprotected " here"
          ]
          chunks
    , testCase "Protects multi-backtick spans" $ do
        let line = "Code: `` `literal` `` end"
            chunks = chunkLine line
        assertEqual
          "Chunks"
          [ Unprotected "Code: "
          , Protected "`` `literal` ``"
          , Unprotected " end"
          ]
          chunks
    ]

test_normalization :: TestTree
test_normalization =
  testGroup
    "Markdown Normalization"
    [ testCase "Replaces backticks and bold with wikilinks without duplicating brackets" $ do
        let terms = ["Color", "Colors", "Red"]
            pluralPairs = [("Colors", "Color")]
            line = "Use `Color` and `Color`s and **Red** and [[Color]]"
            transformed = transformLine terms pluralPairs line
        assertEqual "Result" "Use [[Color]] and [[Colors]] and [[Red]] and [[Color]]" transformed
    , testCase "Preserves headings" $ do
        let terms = ["Color"]
            pluralPairs = []
            line = "## The Color System"
            transformed = transformLine terms pluralPairs line
        assertEqual "Unchanged heading" line transformed
    , testCase "Preserves fenced code blocks" $ do
        let terms = ["Color"]
            content = "Before `Color`\n```\nInside `Color`\n```\nAfter `Color`\n"
            (newContent, count) = transformContent terms content
        assertEqual "Changed line count" 2 count
        assertEqual "Content" "Before [[Color]]\n```\nInside `Color`\n```\nAfter [[Color]]\n" newContent
    ]

test_renaming :: TestTree
test_renaming =
  testGroup
    "Keyword Renaming"
    [ testCase "Renames across wikilinks, backticks, and bold" $ do
        let content = "Use `OldKw` and [[OldKw]] and **OldKw**."
            (newContent, count) = renameContent "OldKw" "NewKw" content
        assertEqual "Changes" 1 count
        assertEqual "Result" "Use [[NewKw]] and [[NewKw]] and [[NewKw]]." newContent
    ]
