{-# LANGUAGE OverloadedRecordDot #-}
{-# LANGUAGE OverloadedStrings #-}

module LoaderTest (test_loader) where

import Control.Exception (SomeException, finally, try)
import Control.Monad.State (evalStateT)
import Data.ByteString qualified as BS
import Data.List (isInfixOf)
import Data.Map.Strict qualified as Map
import Data.Text (Text)
import Data.Text qualified as T
import Data.Text.Encoding qualified as TE
import Data.Time.Clock (diffTimeToPicoseconds, getCurrentTime, utctDay, utctDayTime)
import System.Directory
  ( createDirectoryIfMissing
  , getTemporaryDirectory
  , removePathForcibly
  )
import System.FilePath ((</>))
import System.Random (mkStdGen)
import Test.Tasty (TestTree, testGroup)
import Test.Tasty.HUnit (assertBool, testCase, (@?=))

import Core.Card
  ( ActorDefinition (..)
  , CardReference (..)
  , CoreCard (..)
  , DeckEntry (..)
  , Identified (..)
  , MasterCard (..)
  , RulesStatus (..)
  , Stats (..)
  )
import Core.NonEmptyText (getRawText, unsafeNonEmptyText)
import Core.State (ActorState (..), CoreCardState (..))
import Server.Game (GameState (..))
import Server.Loader (loadLibrary, loadMasterCatalog)
import Server.Scenario
  ( instantiateActor
  , loadAndInstantiateActor
  , loadScenarioWithCatalog
  )
import Server.Types (CardLibrary (..))

withTempDir :: String -> (FilePath -> IO a) -> IO a
withTempDir prefix action = do
  tmpBase <- getTemporaryDirectory
  time <- getCurrentTime
  let dirName = prefix ++ "-" ++ show (utctDay time) ++ "-" ++ show (diffTimeToPicoseconds (utctDayTime time))
      tempPath = tmpBase </> dirName
  createDirectoryIfMissing True tempPath
  action tempPath `finally` removePathForcibly tempPath

writeUtf8 :: FilePath -> Text -> IO ()
writeUtf8 path content = BS.writeFile path (TE.encodeUtf8 content)

sampleSingleMasterCardYaml :: Text
sampleSingleMasterCardYaml =
  T.unlines
    [ "id: sunder-armor"
    , "name: Sunder Armor"
    , "tags: [Martial, Attack]"
    , "stats:"
    , "  red: 2"
    , "  yellow: 0"
    , "  blue: 0"
    , "cost: 1"
    , "rules_status: current"
    , "legacy_notes: null"
    ]

sampleMultiMasterCardYaml :: Text
sampleMultiMasterCardYaml =
  T.unlines
    [ "- id: shield-bash"
    , "  name: Shield Bash"
    , "  tags: [Martial, Defense]"
    , "  stats:"
    , "    red: 1"
    , "    yellow: 0"
    , "    blue: 2"
    , "  cost: 0"
    , "  rules_status: current"
    , "- id: athletics"
    , "  name: Athletics"
    , "  tags: [Core, Physical]"
    , "  stats:"
    , "    red: 1"
    , "    yellow: 1"
    , "    blue: 1"
    , "  cost: null"
    , "  rules_status: outdated"
    , "  legacy_notes: Uses obsolete color wording"
    ]

sampleMilestoneMasterCardYaml :: Text
sampleMilestoneMasterCardYaml =
  T.unlines
    [ "id: fireball"
    , "name: Fireball"
    , "tags: [Spell]"
    , "stats:"
    , "  red: 0"
    , "  yellow: 0"
    , "  blue: 3"
    , "cost: 2"
    , "milestones:"
    , "  mastered:"
    , "    stats:"
    , "      blue: 5"
    , "    cost: 1"
    ]

sampleActorYaml :: Text
sampleActorYaml =
  T.unlines
    [ "name: Test Warrior"
    , "tags: [pc]"
    , "items: []"
    , "nature: []"
    , "deck:"
    , "  - card: sunder-armor"
    , "    stats:"
    , "      blue: 3"
    , "    upgrades:"
    , "      red: 1"
    , "  - card: athletics"
    ]

sampleMilestoneActorYaml :: Text
sampleMilestoneActorYaml =
  T.unlines
    [ "name: Test Mage"
    , "tags: [pc]"
    , "items: []"
    , "nature: []"
    , "deck:"
    , "  - card: fireball"
    , "    milestone: mastered"
    ]

sampleBrokenActorYaml :: Text
sampleBrokenActorYaml =
  T.unlines
    [ "name: Broken Hero"
    , "tags: [pc]"
    , "items: []"
    , "nature: []"
    , "deck:"
    , "  - card: nonexistent-card-slug"
    ]

test_loader :: TestTree
test_loader =
  testGroup
    "Master Card Catalog Loader & Resolution"
    [ testGroup
        "loadMasterCatalog"
        [ testCase "Loads single master card YAML" $ withTempDir "test-mc-single" $ \dir -> do
            let cardFile = dir </> "sunder.yaml"
            writeUtf8 cardFile sampleSingleMasterCardYaml
            catalog <- loadMasterCatalog dir
            Map.size catalog @?= 1
            case Map.lookup "sunder-armor" catalog of
              Nothing -> assertBool "sunder-armor must exist" False
              Just mc -> do
                mc.id @?= "sunder-armor"
                getRawText mc.name @?= "Sunder Armor"
                mc.stats.red @?= 2
                mc.stats.blue @?= 0
                mc.rulesStatus @?= Just RulesCurrent
        , testCase "Loads multi-card list YAML" $ withTempDir "test-mc-multi" $ \dir -> do
            let cardFile = dir </> "core.yaml"
            writeUtf8 cardFile sampleMultiMasterCardYaml
            catalog <- loadMasterCatalog dir
            Map.size catalog @?= 2
            case Map.lookup "shield-bash" catalog of
              Nothing -> assertBool "shield-bash must exist" False
              Just mc -> do
                getRawText mc.name @?= "Shield Bash"
                mc.stats.blue @?= 2
            case Map.lookup "athletics" catalog of
              Nothing -> assertBool "athletics must exist" False
              Just mc -> do
                mc.rulesStatus @?= Just RulesOutdated
                mc.legacyNotes @?= Just "Uses obsolete color wording"
        , testCase "Recursively loads nested directories" $ withTempDir "test-mc-nested" $ \dir -> do
            let martialDir = dir </> "martial"
                beastsDir = dir </> "monsters" </> "beasts"
            createDirectoryIfMissing True martialDir
            createDirectoryIfMissing True beastsDir
            writeUtf8 (martialDir </> "sunder.yaml") sampleSingleMasterCardYaml
            writeUtf8 (beastsDir </> "core.yaml") sampleMultiMasterCardYaml
            catalog <- loadMasterCatalog dir
            Map.size catalog @?= 3
            assertBool "contains sunder-armor" (Map.member "sunder-armor" catalog)
            assertBool "contains shield-bash" (Map.member "shield-bash" catalog)
            assertBool "contains athletics" (Map.member "athletics" catalog)
        , testCase "Non-existent directory returns empty map" $ do
            catalog <- loadMasterCatalog "/tmp/nonexistent-cardpg-catalog-dir-12345"
            Map.size catalog @?= 0
        ]
    , testGroup
        "loadLibrary Integration"
        [ testCase "Populates masterCatalog from master subdirectory" $ withTempDir "test-lib-master" $ \dir -> do
            let masterDir = dir </> "master" </> "martial"
            createDirectoryIfMissing True masterDir
            writeUtf8 (masterDir </> "cards.yaml") sampleMultiMasterCardYaml
            lib <- loadLibrary dir
            Map.size lib.masterCatalog @?= 2
            assertBool "masterCatalog has shield-bash" (Map.member "shield-bash" lib.masterCatalog)
            assertBool "masterCatalog has athletics" (Map.member "athletics" lib.masterCatalog)
        , testCase "Distinguishes master/monsters from root monsters" $ withTempDir "test-lib-distinguish" $ \dir -> do
            let masterMonstersDir = dir </> "master" </> "monsters"
            createDirectoryIfMissing True masterMonstersDir
            writeUtf8 (masterMonstersDir </> "sunder.yaml") sampleSingleMasterCardYaml
            lib <- loadLibrary dir
            Map.size lib.masterCatalog @?= 1
            length lib.actors @?= 0
        ]
    , testGroup
        "Scenario & Actor Resolution"
        [ testCase "Instantiates actor with referenced cards and stat overrides" $ withTempDir "test-actor-res" $ \dir -> do
            let masterDir = dir </> "master"
            createDirectoryIfMissing True masterDir
            writeUtf8 (masterDir </> "sunder.yaml") sampleSingleMasterCardYaml
            writeUtf8 (masterDir </> "core.yaml") sampleMultiMasterCardYaml
            catalog <- loadMasterCatalog masterDir

            let actorPath = dir </> "warrior.yaml"
            writeUtf8 actorPath sampleActorYaml

            actorState <- evalStateT (loadAndInstantiateActor catalog actorPath 0 0 (Just 2)) (mkStdGen 42)
            actorState.name @?= "Test Warrior"

            let allCards = map (\i -> i.content) (actorState.coreState.hand ++ actorState.coreState.deck)
            length allCards @?= 2

            -- Sunder armor should have: base red 2 + upgrade red 1 = 3, blue override = 3
            let mSunder = [c | c <- allCards, getRawText c.name == "Sunder Armor"]
            case mSunder of
              [c] -> do
                c.stats.red @?= 3
                c.stats.blue @?= 3
                c.stats.yellow @?= 0
              _ -> assertBool "Must contain resolved Sunder Armor" False

            -- Athletics should have base stats 1, 1, 1
            let mAthletics = [c | c <- allCards, getRawText c.name == "Athletics"]
            case mAthletics of
              [c] -> do
                c.stats.red @?= 1
                c.stats.yellow @?= 1
                c.stats.blue @?= 1
              _ -> assertBool "Must contain resolved Athletics" False
        , testCase "Instantiates actor with milestone reference" $ withTempDir "test-actor-milestone" $ \dir -> do
            let masterDir = dir </> "master"
            createDirectoryIfMissing True masterDir
            writeUtf8 (masterDir </> "spells.yaml") sampleMilestoneMasterCardYaml
            catalog <- loadMasterCatalog masterDir

            let actorPath = dir </> "mage.yaml"
            writeUtf8 actorPath sampleMilestoneActorYaml

            actorState <- evalStateT (loadAndInstantiateActor catalog actorPath 0 0 Nothing) (mkStdGen 42)
            let allCards = map (\i -> i.content) actorState.coreState.deck
            case allCards of
              [c] -> do
                getRawText c.name @?= "Fireball"
                c.stats.blue @?= 5
                c.cost @?= Just 1
              _ -> assertBool "Must contain resolved Fireball milestone" False
        , testCase "Fails with descriptive error when card ID is missing" $ withTempDir "test-actor-err" $ \dir -> do
            let actorPath = dir </> "broken.yaml"
            writeUtf8 actorPath sampleBrokenActorYaml
            res <-
              try (evalStateT (loadAndInstantiateActor Map.empty actorPath 0 0 Nothing) (mkStdGen 42))
                :: IO (Either SomeException ActorState)
            case res of
              Right _ -> assertBool "Loading broken actor should have thrown exception" False
              Left err -> do
                let msg = show err
                assertBool "Mentions actor path" (actorPath `isInfixOf` msg)
                assertBool "Mentions actor name" ("Broken Hero" `isInfixOf` msg)
                assertBool "Mentions missing card slug" ("nonexistent-card-slug" `isInfixOf` msg)
        , testCase "instantiateActor directly resolves in-memory ActorDefinition" $ do
            let mc =
                  MasterCard
                    { id = "quick-jab"
                    , name = unsafeNonEmptyText "Quick Jab"
                    , tags = Nothing
                    , stats = Stats 3 0 0
                    , cost = Nothing
                    , attack = Nothing
                    , rules = Nothing
                    , flavor = Nothing
                    , rulesStatus = Just RulesCurrent
                    , legacyNotes = Nothing
                    , milestones = Nothing
                    }
                catalog = Map.singleton "quick-jab" mc
                actorDef =
                  ActorDefinition
                    { name = "Boxer"
                    , tags = Nothing
                    , items = []
                    , nature = []
                    , deck =
                        [ EntryRef (CardReference "quick-jab" (Just (Stats (Just 4) Nothing Nothing)) Nothing Nothing)
                        ]
                    }
            actorState <- evalStateT (instantiateActor catalog actorDef 0 0 Nothing) (mkStdGen 42)
            actorState.name @?= "Boxer"
            let cards = [c.content | c <- actorState.coreState.deck]
            case cards of
              [c] -> do
                getRawText c.name @?= "Quick Jab"
                c.stats.red @?= 4
              _ -> assertBool "Must resolve Quick Jab" False
        , testCase "loadScenarioWithCatalog loads scenario referencing master cards" $ withTempDir "test-scenario-full" $ \dir -> do
            let masterDir = dir </> "master"
                cardsDir = dir </> "cards"
            createDirectoryIfMissing True masterDir
            createDirectoryIfMissing True cardsDir
            writeUtf8 (masterDir </> "sunder.yaml") sampleSingleMasterCardYaml
            writeUtf8 (masterDir </> "core.yaml") sampleMultiMasterCardYaml
            catalog <- loadMasterCatalog masterDir

            let warriorFile = cardsDir </> "warrior.yaml"
            writeUtf8 warriorFile sampleActorYaml

            let scenarioFile = dir </> "test_scenario.yaml"
            writeUtf8
              scenarioFile
              ( T.unlines
                  [ "name: Test Scenario"
                  , "actors:"
                  , "  - name: warrior"
                  , "    file: cards/warrior.yaml"
                  , "    x: 0"
                  , "    y: 0"
                  , "    initialHandSize: 1"
                  ]
              )

            (gs, _) <- loadScenarioWithCatalog catalog scenarioFile (Just 42)
            Map.size gs.actors @?= 1
            case Map.elems gs.actors of
              [actor] -> do
                actor.name @?= "Test Warrior"
                length actor.coreState.hand @?= 1
                length actor.coreState.deck @?= 1
              _ -> assertBool "Must contain single actor" False
        ]
    ]
