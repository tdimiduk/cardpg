{-# LANGUAGE OverloadedRecordDot #-}
{-# LANGUAGE OverloadedStrings #-}

module GlossaryTest (test_glossary) where

import Data.Aeson (decode, encode)
import Data.ByteString.Lazy.Char8 qualified as BL
import System.Directory (doesFileExist)
import Test.Tasty
import Test.Tasty.HUnit

import Core.DSL (TextRep (..), parseText)
import Core.Glossary
import Core.RichText (RichText)

sampleGlossaryJson :: BL.ByteString
sampleGlossaryJson =
  "{\n\
  \  \"color\": {\n\
  \    \"canonical\": \"Color\",\n\
  \    \"aliases\": [\"Colors\"],\n\
  \    \"slug\": \"color\",\n\
  \    \"category\": \"The Three Colors\",\n\
  \    \"summary\": \"How approaches and abilities are classified and actions are adjudicated.\",\n\
  \    \"theme\": null\n\
  \  },\n\
  \  \"red\": {\n\
  \    \"canonical\": \"Red\",\n\
  \    \"aliases\": [],\n\
  \    \"slug\": \"red\",\n\
  \    \"category\": \"The Three Colors\",\n\
  \    \"summary\": \"One of the game's Colors. The color of Force, Endurance, Presence, Passion, Dominion.\",\n\
  \    \"theme\": \"red\"\n\
  \  }\n\
  \}"

test_glossary :: TestTree
test_glossary =
  testGroup
    "Glossary Tests"
    [ testCase "Decodes brief sample JSON accurately" $ do
        case decode sampleGlossaryJson of
          Nothing -> assertFailure "Failed to decode sampleGlossaryJson"
          Just g -> do
            let colorEntry = lookupGlossary "Color" g
            case colorEntry of
              Nothing -> assertFailure "Could not find 'Color' entry"
              Just e -> do
                assertEqual "Canonical name" "Color" e.canonical
                assertEqual "Aliases" ["Colors"] e.aliases
                assertEqual "Slug" "color" e.slug
                assertEqual "Category" "The Three Colors" e.category
                assertEqual "Theme is Nothing" Nothing e.theme

            let redEntry = lookupGlossary "Red" g
            case redEntry of
              Nothing -> assertFailure "Could not find 'Red' entry"
              Just e -> do
                assertEqual "Canonical name" "Red" e.canonical
                assertEqual "Theme" (Just "red") e.theme
    , testCase "JSON roundtrip preserves data" $ do
        case (decode sampleGlossaryJson :: Maybe Glossary) of
          Nothing -> assertFailure "Initial decode failed"
          Just g -> do
            let reencoded = encode g
            case (decode reencoded :: Maybe Glossary) of
              Nothing -> assertFailure "Decode after encode failed"
              Just g' -> assertEqual "Roundtrip glossary equality" g g'
    , testCase "Lookup by canonical, alias, slug, and case-insensitively" $ do
        case decode sampleGlossaryJson of
          Nothing -> assertFailure "Decode failed"
          Just g -> do
            -- Canonical
            assertEqual "Lookup 'Color'" (Just "color") ((\e -> e.slug) <$> lookupGlossary "Color" g)
            -- Alias
            assertEqual "Lookup alias 'Colors'" (Just "color") ((\e -> e.slug) <$> lookupGlossary "Colors" g)
            -- Slug
            assertEqual "Lookup slug 'color'" (Just "color") ((\e -> e.slug) <$> lookupGlossary "color" g)
            -- Mixed case
            assertEqual "Lookup 'cOLoRs'" (Just "color") ((\e -> e.slug) <$> lookupGlossary "cOLoRs" g)
            -- Unknown
            assertEqual "Lookup unknown" Nothing (lookupGlossary "Nonexistent" g)
    , testCase "canonicalSlug resolves known terms to canonical slug and falls back to toSlug" $ do
        case decode sampleGlossaryJson of
          Nothing -> assertFailure "Decode failed"
          Just g -> do
            assertEqual "Canonical 'Color'" "color" (canonicalSlug "Color" g)
            assertEqual "Alias 'Colors'" "color" (canonicalSlug "Colors" g)
            assertEqual "Fallback 'Crisis Time'" "crisis-time" (canonicalSlug "Crisis Time" g)
    , testCase "toSlug formats strings cleanly" $ do
        assertEqual "Multi-word" "crisis-time" (toSlug "Crisis Time")
        assertEqual "Special chars" "colors-of-action" (toSlug "Colors of Action!")
        assertEqual "Numbers" "severity-1" (toSlug "Severity 1")
    , testCase "Decodes exported export/glossary.json from disk when present" $ do
        exists <- doesFileExist "export/glossary.json"
        if not exists
          then pure ()
          else do
            content <- BL.readFile "export/glossary.json"
            case (decode content :: Maybe Glossary) of
              Nothing -> assertFailure "Failed to decode export/glossary.json"
              Just g -> do
                assertBool "Has at least 20 entries" (length (allEntries g) >= 20)
                assertEqual
                  "Finds 'Crisis Time'"
                  (Just "crisis-time")
                  ((\e -> e.slug) <$> lookupGlossary "Crisis Time" g)
                assertEqual
                  "Finds alias 'Action Stacks'"
                  (Just "action-stack")
                  ((\e -> e.slug) <$> lookupGlossary "Action Stacks" g)
    , testCase "Canonical compiled glossary is populated" $ do
        assertBool "Has at least 20 entries" (length (allEntries glossary) >= 20)
        assertEqual
          "Finds 'Crisis Time'"
          (Just "crisis-time")
          ((\e -> e.slug) <$> lookupGlossary "Crisis Time" glossary)
        assertEqual
          "Finds alias 'Action Stacks'"
          (Just "action-stack")
          ((\e -> e.slug) <$> lookupGlossary "Action Stacks" glossary)
    , testCase "RichText parses and roundtrips [[Wikilink]] and [[Target|Label]]" $ do
        let input1 = "Use [[Action]] to strike."
        case parseText input1 of
          Left err -> assertFailure ("Failed to parse wikilink: " ++ err)
          Right (rt :: RichText) -> do
            assertEqual "Roundtrips wikilink" input1 (toText rt)
        let input2 = "Perform [[Crisis Time|tactical mode]] now."
        case parseText input2 of
          Left err -> assertFailure ("Failed to parse piped wikilink: " ++ err)
          Right (rt :: RichText) -> do
            assertEqual "Roundtrips piped wikilink" input2 (toText rt)
    ]
