{-# LANGUAGE OverloadedStrings #-}

module CardParsingTest (test_cardParsing) where

import Control.Monad (forM, forM_, when)
import Data.ByteString qualified as BS
import Data.ByteString.Char8 qualified as BS8
import Data.List (isSuffixOf)
import Data.List.NonEmpty qualified as NE
import Data.Map.Strict qualified as Map
import Data.Maybe (isJust)
import Data.Text qualified as T
import Data.Text.Encoding (encodeUtf8)
import Data.Yaml (ParseException, decodeEither', decodeFileEither, encode)
import System.Directory (doesDirectoryExist, doesFileExist, listDirectory)
import System.FilePath ((</>))
import Test.Tasty
import Test.Tasty.HUnit

import Core.Card
  ( ActorDefinition
  , CardMilestone (..)
  , CardReference (..)
  , CoreCard (..)
  , DeckEntry (..)
  , ItemCard (..)
  , MasterCard (..)
  , RulesStatus (..)
  , emptyItemCard
  , masterCardToCoreCard
  , resolveDeckEntry
  )
import Core.DSL (parseText, toText)
import Core.NonEmptyText (getRawText, unsafeNonEmptyText)
import Core.RichText (unsafeSimpleString)
import Core.Rules (AttackDef (..), Rule (..), TaskDef (..))
import Core.Stats (Difficulty (..), ResourceType (..), StackPower (..), Stats (..))
import Core.Time (Duration (..), TimeUnit (..))

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
      , testGroup "Item Card Schema & Parsing" itemCardTests
      , testGroup "Deck Entry Parsing" deckEntryParsingTests
      , testGroup "Deck Entry Resolution" deckResolutionTests
      , testGroup "Actor File Parsing & Roundtrip" fileTests
      , testGroup "Attack & Task DSL Rules" attackAndTaskDslTests
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

itemCardTests :: [TestTree]
itemCardTests =
  [ testCase "Parses ItemCard with portions and rules" $ do
      let yaml =
            encodeUtf8 $
              T.unlines
                [ "name: Waterskin"
                , "portions: 3"
                , "rules:"
                , "  - Drink 1 Portion every 4 hours."
                , "tags:"
                , "  - Supply"
                , "  - Water"
                ]
      case decodeEither' yaml of
        Left err -> assertFailure $ "Failed to decode ItemCard: " ++ show err
        Right (item :: ItemCard) -> do
          getRawText item.name @?= "Waterskin"
          item.portions @?= Just 3
          assertBool "Rules should be parsed" (isJust item.rules)
          fmap length item.rules @?= Just 1
  , testCase "Roundtrips ItemCard YAML encode/decode with portions and rules" $ do
      let item =
            (emptyItemCard (unsafeNonEmptyText "Travel Rations"))
              { portions = Just 4
              , tags = Just ("Supply" NE.:| ["Food"])
              , rules = Just (RuleNarrative (unsafeSimpleString "Consume 1 portion during rest") NE.:| [])
              }
          encoded = encode item
      case decodeEither' encoded of
        Left err -> assertFailure $ "Failed to decode re-encoded ItemCard: " ++ show err
        Right (item' :: ItemCard) -> item' @?= item
  , testCase "Parses data/cards/items/supplies.yaml" $ do
      let relPath = "data/cards/items/supplies.yaml"
      fileExists <- doesFileExist relPath
      let path = if fileExists then relPath else "../" ++ relPath
      result <- decodeFileEither path :: IO (Either ParseException [ItemCard])
      case result of
        Left err -> assertFailure $ "Failed to parse " ++ path ++ ": " ++ show err
        Right items -> do
          assertBool "Supplies should contain at least 2 items" (length items >= 2)
          let rations = filter (\i -> getRawText i.name == "Travel Rations") items
          case rations of
            [r] -> do
              r.portions @?= Just 4
              assertBool "Travel Rations should have rules" (isJust r.rules)
            _ -> assertFailure "Travel Rations not found in supplies.yaml"
          let waterskin = filter (\i -> getRawText i.name == "Waterskin") items
          case waterskin of
            [w] -> do
              w.portions @?= Just 3
              assertBool "Waterskin should have rules" (isJust w.rules)
            _ -> assertFailure "Waterskin not found in supplies.yaml"
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

attackAndTaskDslTests :: [TestTree]
attackAndTaskDslTests =
  [ testGroup
      "AttackDef DSL Parsing & Roundtrip"
      [ testCase "Parses standard attack without consequences" $ do
          case parseText "{Red}: Str = {Red} + 2" of
            Left err -> assertFailure $ "Failed parsing: " ++ err
            Right (atk :: AttackDef) -> do
              atk.resistedBy @?= Red
              atk.power @?= StackPower Red 2 Nothing
              atk.consequences @?= Nothing
              atk.effect @?= Nothing
              toText atk @?= "{Red}: Str = {Red} + 2"
      , testCase "Parses attack with single consequence tag" $ do
          case parseText "{Red}: Str = {Red} + 2 [BluntForce]" of
            Left err -> assertFailure $ "Failed parsing: " ++ err
            Right (atk :: AttackDef) -> do
              atk.resistedBy @?= Red
              atk.power @?= StackPower Red 2 Nothing
              atk.consequences @?= Just ("BluntForce" NE.:| [])
              atk.effect @?= Nothing
              toText atk @?= "{Red}: Str = {Red} + 2 [BluntForce]"
      , testCase "Parses attack with multiple consequence tags" $ do
          case parseText "{Blue}: Str = {Blue} + 1 [BluntForce, MuscleStrain]" of
            Left err -> assertFailure $ "Failed parsing: " ++ err
            Right (atk :: AttackDef) -> do
              atk.resistedBy @?= Blue
              atk.power @?= StackPower Blue 1 Nothing
              atk.consequences @?= Just ("BluntForce" NE.:| ["MuscleStrain"])
              atk.effect @?= Nothing
              toText atk @?= "{Blue}: Str = {Blue} + 1 [BluntForce, MuscleStrain]"
      , testCase "Parses attack with consequences and effect" $ do
          case parseText "{Red}: Str = {Red} + 3 [BluntForce] → Knockback 1m" of
            Left err -> assertFailure $ "Failed parsing: " ++ err
            Right (atk :: AttackDef) -> do
              atk.resistedBy @?= Red
              atk.power @?= StackPower Red 3 Nothing
              atk.consequences @?= Just ("BluntForce" NE.:| [])
              assertBool "Effect should be present" (isJust atk.effect)
              toText atk @?= "{Red}: Str = {Red} + 3 [BluntForce] → Knockback 1m"
      , testCase "Parses attack with Attack prefix" $ do
          case parseText "Attack {Yellow}: Str = {Yellow} - 1 [Bruise]" of
            Left err -> assertFailure $ "Failed parsing: " ++ err
            Right (atk :: AttackDef) -> do
              atk.resistedBy @?= Yellow
              atk.power @?= StackPower Yellow (-1) Nothing
              atk.consequences @?= Just ("Bruise" NE.:| [])
      ]
  , testGroup
      "TaskDef Duration Parsing & Roundtrip"
      [ testCase "Parses task rule with canonical duration" $ do
          case parseText "Task: First Aid (Check {Blue} 3; Time 1 min; Cost Bandage) → Remove this" of
            Left err -> assertFailure $ "Failed parsing: " ++ err
            Right (RuleTask task) -> do
              getRawText task.name @?= "First Aid"
              task.check @?= Just (Difficulty Blue 3)
              task.time @?= Just (Duration 1 Minute)
              toText (RuleTask task)
                @?= "Task: First Aid (Check {Blue} 3; Time 1 min; Cost Bandage) → Remove this"
            Right other -> assertFailure $ "Expected RuleTask, got: " ++ show other
      , testCase "Parses task rule with hours" $ do
          case parseText "Task: Recuperate (Check {Red} 5; Time 1 hour) → Remove this" of
            Left err -> assertFailure $ "Failed parsing: " ++ err
            Right (RuleTask task) -> do
              task.time @?= Just (Duration 1 Hour)
              toText (RuleTask task) @?= "Task: Recuperate (Check {Red} 5; Time 1 hour) → Remove this"
            Right other -> assertFailure $ "Expected RuleTask, got: " ++ show other
      , testCase "Parses task rule with plural hours" $ do
          case parseText "Task: Careful Repair (Check {Yellow} 12; Time 4 hours; Cost Repair Tools) → Remove this" of
            Left err -> assertFailure $ "Failed parsing: " ++ err
            Right (RuleTask task) -> do
              task.time @?= Just (Duration 4 Hour)
              toText (RuleTask task)
                @?= "Task: Careful Repair (Check {Yellow} 12; Time 4 hours; Cost Repair Tools) → Remove this"
            Right other -> assertFailure $ "Expected RuleTask, got: " ++ show other
      , testCase "Parses lax duration expressions in task and standardizes to canonical" $ do
          let laxTests =
                [
                  ( "Task: Rest (Time 10m) → Remove this"
                  , Duration 10 Minute
                  , "Task: Rest (Time 10 min) → Remove this"
                  )
                ,
                  ( "Task: Rest (Time 2 hrs) → Remove this"
                  , Duration 2 Hour
                  , "Task: Rest (Time 2 hours) → Remove this"
                  )
                , ("Task: Rest (Time 1 day) → Remove this", Duration 1 Day, "Task: Rest (Time 1 day) → Remove this")
                , ("Task: Rest (Time 3 days) → Remove this", Duration 3 Day, "Task: Rest (Time 3 days) → Remove this")
                ]
          forM_ laxTests $ \(input, expectedDur, expectedCanonical) ->
            case parseText input of
              Left err -> assertFailure $ "Failed parsing " ++ show input ++ ": " ++ err
              Right (RuleTask task) -> do
                task.time @?= Just expectedDur
                toText (RuleTask task) @?= expectedCanonical
              Right other -> assertFailure $ "Expected RuleTask, got: " ++ show other
      ]
  ]
