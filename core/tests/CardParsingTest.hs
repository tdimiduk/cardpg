{-# LANGUAGE OverloadedStrings #-}

module CardParsingTest (test_cardParsing) where

import Control.Monad (forM, when)
import Data.ByteString qualified as BS
import Data.ByteString.Char8 qualified as BS8
import Data.List (isSuffixOf)
import Data.List.NonEmpty qualified as NE
import Data.Map.Strict qualified as Map
import Data.Maybe (isJust)
import Data.Text qualified as T
import Data.Text.Encoding (encodeUtf8)
import Data.Yaml (ParseException, decodeEither', decodeFileEither, encode)
import System.Directory (doesDirectoryExist, listDirectory)
import System.FilePath ((</>))
import Test.Tasty
import Test.Tasty.HUnit

import Core.Card
  ( ActorDefinition
  , CardMilestone (..)
  , CardReference (..)
  , CoreCard (..)
  , DeckEntry (..)
  , MasterCard (..)
  , RulesStatus (..)
  , masterCardToCoreCard
  , resolveDeckEntry
  )
import Core.NonEmptyText (getRawText)
import Core.Stats (Stats (..))

test_cardParsing :: IO TestTree
test_cardParsing = do
  pcFiles <- getYamlFiles "data/cards/pc"
  monsterFiles <- getYamlFiles "data/cards/monsters"
  let allFiles = pcFiles ++ monsterFiles
  fileTests <- forM allFiles $ \path -> do
    return $ testCase path $ testActorDefinitionFile path
  return $
    testGroup
      "Card Database & Parsing"
      [ testGroup "Master Card Schema & Parsing" masterCardTests
      , testGroup "Deck Entry Parsing" deckEntryParsingTests
      , testGroup "Deck Entry Resolution" deckResolutionTests
      , testGroup "Actor File Parsing & Roundtrip" fileTests
      ]

sampleMasterYaml :: BS.ByteString
sampleMasterYaml =
  encodeUtf8 $
    T.unlines
      [ "id: sunder-armor"
      , "name: Sunder Armor"
      , "tags:"
      , "  - Martial"
      , "  - Attack"
      , "stats:"
      , "  red: 4"
      , "  yellow: 2"
      , "  blue: 3"
      , "cost: 2"
      , "attack: '{Red}: Str = {Red} + 2 → ignore 1 armor'"
      , "rules:"
      , "  - Armor damage (on any success)"
      , "flavor: A crushing blow to shatter defenses."
      , "rules_status: outdated"
      , "legacy_notes: Uses legacy armor bypass syntax"
      , "milestones:"
      , "  veteran:"
      , "    cost: 1"
      , "    stats:"
      , "      red: 5"
      , "    rules:"
      , "      - Deal additional armor damage"
      ]

masterCardTests :: [TestTree]
masterCardTests =
  [ testCase "Parses all master card fields accurately" $ do
      case decodeEither' sampleMasterYaml of
        Left err -> assertFailure $ "Failed to decode sample MasterCard: " ++ show err
        Right (mc :: MasterCard) -> do
          mc.id @?= "sunder-armor"
          getRawText mc.name @?= "Sunder Armor"
          mc.tags @?= Just ("Martial" NE.:| ["Attack"])
          mc.stats @?= Stats{red = 4, yellow = 2, blue = 3}
          mc.cost @?= Just 2
          assertBool "Attack should be parsed" (isJust mc.attack)
          assertBool "Rules should be parsed" (fmap length mc.rules == Just 1)
          mc.rulesStatus @?= Just RulesOutdated
          mc.legacyNotes @?= Just "Uses legacy armor bypass syntax"
          case mc.milestones of
            Nothing -> assertFailure "Milestones should be parsed"
            Just ms -> case Map.lookup "veteran" ms of
              Nothing -> assertFailure "Veteran milestone should exist"
              Just v -> do
                v.cost @?= Just 1
                v.stats @?= Just (Stats (Just 5) Nothing Nothing)
                assertBool "Veteran rules should be parsed" (isJust v.rules)
  , testCase "Roundtrips MasterCard YAML encode/decode" $ do
      case decodeEither' sampleMasterYaml of
        Left err -> assertFailure $ "Failed to decode: " ++ show err
        Right (mc :: MasterCard) -> do
          let encoded = encode mc
          case decodeEither' encoded of
            Left err -> assertFailure $ "Failed to decode re-encoded: " ++ show err
            Right (mc' :: MasterCard) -> mc' @?= mc
  , testCase "Parses RulesStatus variants" $ do
      let parseStatus s = case decodeEither'
            (BS8.unlines ["id: test", "name: Test", "stats: {red: 1, yellow: 1, blue: 1}", "rules_status: " <> s]) of
            Right (m :: MasterCard) -> m.rulesStatus
            Left _ -> Nothing
      parseStatus "current" @?= Just RulesCurrent
      parseStatus "outdated" @?= Just RulesOutdated
      parseStatus "experimental" @?= Just RulesExperimental
  ]

deckEntryParsingTests :: [TestTree]
deckEntryParsingTests =
  [ testCase "Parses CardReference with overrides and deltas" $ do
      let yaml =
            BS8.unlines
              [ "card: sunder-armor"
              , "stats:"
              , "  blue: 4"
              , "upgrades:"
              , "  red: 1"
              , "milestone: veteran"
              ]
      case decodeEither' yaml of
        Left err -> assertFailure $ "Failed to decode CardReference: " ++ show err
        Right (entry :: DeckEntry) -> case entry of
          EntryInline _ -> assertFailure "Expected EntryRef, got EntryInline"
          EntryRef ref -> do
            ref.card @?= "sunder-armor"
            ref.stats @?= Just (Stats Nothing Nothing (Just 4))
            ref.upgrades @?= Just (Stats (Just 1) Nothing Nothing)
            ref.milestone @?= Just "veteran"
  , testCase "Parses inline CoreCard backward-compatibly" $ do
      let yaml =
            BS8.unlines
              [ "name: Conditioning"
              , "stats:"
              , "  red: 4"
              , "  yellow: 3"
              , "  blue: 3"
              ]
      case decodeEither' yaml of
        Left err -> assertFailure $ "Failed to decode inline CoreCard: " ++ show err
        Right (entry :: DeckEntry) -> case entry of
          EntryRef _ -> assertFailure "Expected EntryInline, got EntryRef"
          EntryInline c -> do
            getRawText c.name @?= "Conditioning"
            c.stats @?= Stats{red = 4, yellow = 3, blue = 3}
  ]

deckResolutionTests :: [TestTree]
deckResolutionTests =
  let sampleMaster = case decodeEither' sampleMasterYaml of
        Right (m :: MasterCard) -> m
        Left err -> error $ "Invalid sample MasterCard YAML: " ++ show err
      catalog = Map.singleton "sunder-armor" sampleMaster
   in [ testCase "Exact reference inherits master card defaults" $ do
          let ref = CardReference{card = "sunder-armor", stats = Nothing, upgrades = Nothing, milestone = Nothing}
          case resolveDeckEntry catalog (EntryRef ref) of
            Left err -> assertFailure $ "Failed resolution: " ++ err
            Right card -> card @?= masterCardToCoreCard sampleMaster
      , testCase "Partial stat override overrides specified colors" $ do
          let ref =
                CardReference
                  { card = "sunder-armor"
                  , stats = Just (Stats Nothing Nothing (Just 5))
                  , upgrades = Nothing
                  , milestone = Nothing
                  }
          case resolveDeckEntry catalog (EntryRef ref) of
            Left err -> assertFailure $ "Failed resolution: " ++ err
            Right card -> card.stats @?= Stats{red = 4, yellow = 2, blue = 5}
      , testCase "Upgrade delta increments stats" $ do
          let ref =
                CardReference
                  { card = "sunder-armor"
                  , stats = Nothing
                  , upgrades = Just (Stats (Just 2) (Just 1) Nothing)
                  , milestone = Nothing
                  }
          case resolveDeckEntry catalog (EntryRef ref) of
            Left err -> assertFailure $ "Failed resolution: " ++ err
            Right card -> card.stats @?= Stats{red = 6, yellow = 3, blue = 3}
      , testCase "Milestone replaces stats, cost, and rules" $ do
          let ref =
                CardReference
                  { card = "sunder-armor"
                  , stats = Nothing
                  , upgrades = Nothing
                  , milestone = Just "veteran"
                  }
          case resolveDeckEntry catalog (EntryRef ref) of
            Left err -> assertFailure $ "Failed resolution: " ++ err
            Right card -> do
              card.cost @?= Just 1
              card.stats @?= Stats{red = 5, yellow = 2, blue = 3}
              let veteranRules = (Map.lookup "veteran" =<< sampleMaster.milestones) >>= (.rules)
              card.rules @?= veteranRules
      , testCase "Inline CoreCard resolves backward-compatibly" $ do
          let inlineCard = masterCardToCoreCard sampleMaster
          case resolveDeckEntry catalog (EntryInline inlineCard) of
            Left err -> assertFailure $ "Failed resolution: " ++ err
            Right card -> card @?= inlineCard
      , testCase "Unknown card reference returns error" $ do
          let ref = CardReference{card = "unknown-card", stats = Nothing, upgrades = Nothing, milestone = Nothing}
          case resolveDeckEntry catalog (EntryRef ref) of
            Left _ -> pure ()
            Right _ -> assertFailure "Expected resolution error for unknown card ID"
      ]

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
