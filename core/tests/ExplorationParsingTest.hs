{-# LANGUAGE OverloadedRecordDot #-}
{-# LANGUAGE OverloadedStrings #-}

module ExplorationParsingTest (test_explorationParsing) where

import Control.Monad (forM_)
import Data.ByteString qualified as BS
import Data.List.NonEmpty qualified as NE
import Data.Map.Strict qualified as Map
import Data.Maybe (fromMaybe, isJust)
import Data.Yaml (ParseException, decodeEither', decodeFileEither, encode)
import System.Directory (doesFileExist)
import System.FilePath ((</>))
import Test.Tasty
import Test.Tasty.HUnit

import Core.Card.Exploration
  ( ActionScope (..)
  , ChallengeDef (..)
  , ChallengeModifier (..)
  , ClockConfig (..)
  , ClockDeckId (..)
  , ClockEffect (..)
  , ClockEventCard (..)
  , ClockEventId (..)
  , ClockNarrative (..)
  , ClockUrgency (..)
  , ExitStatus (..)
  , ExplorationAction (..)
  , LocationCard (..)
  , LocationExit (..)
  , LocationId (..)
  , ModuleId (..)
  , ModuleManifest (..)
  , ScenarioActor (..)
  , SetExitStatus (..)
  , TravelCard (..)
  , TravelExpedients (..)
  , TravelId (..)
  , TravelRoute (..)
  )
import Core.DSL (parseText, toText)
import Core.NonEmptyText (getRawText)
import Core.RichText (RichText)
import Core.Stats (ResourceType (..))
import Core.Time
  ( Duration (..)
  , ExpeditionTime (..)
  , TimeUnit (..)
  , addDuration
  , addExpeditionDuration
  , addMinutes
  , canonicalDurationText
  , clockTicksCrossed
  , expeditionDay
  , expeditionHour
  , expeditionMinute
  , formatExpeditionTime
  , scaleDuration
  , toMinutes
  )

test_explorationParsing :: IO TestTree
test_explorationParsing = do
  modPath <- findFile "data/modules/crag_gallows/module.yaml"
  locPath <- findFile "data/modules/crag_gallows/locations.yaml"
  trvPath <- findFile "data/modules/crag_gallows/travel.yaml"
  clkPath <- findFile "data/modules/crag_gallows/clocks.yaml"
  pure $
    testGroup
      "Exploration & Module Cards"
      [ timeUnitTests
      , expeditionTimeTests
      , testCase "Parse and validate module.yaml" (testModuleParsing modPath)
      , testCase "Roundtrip encode/decode module.yaml" (testModuleRoundtrip modPath)
      , testCase "Parse and validate locations.yaml" (testLocationParsing locPath)
      , testCase "Parse and validate travel.yaml" (testTravelParsing trvPath)
      , testCase "Parse and validate clocks.yaml" (testClockParsing clkPath)
      , testCase "Roundtrip encode/decode locations.yaml" (testLocationRoundtrip locPath)
      , testCase "Roundtrip encode/decode travel.yaml" (testTravelRoundtrip trvPath)
      , testCase "Roundtrip encode/decode clocks.yaml" (testClockRoundtrip clkPath)
      , testCase "Validate crag_gallows graph connectivity" (testGraphConnectivity locPath trvPath)
      ]

findFile :: FilePath -> IO FilePath
findFile rel = do
  let candidates = [rel, "core" </> rel, ".." </> rel]
  found <- filterM doesFileExist candidates
  case found of
    (p : _) -> pure p
    [] -> fail $ "Could not find file: " ++ rel
  where
    filterM _ [] = pure []
    filterM p (x : xs) = do
      b <- p x
      ys <- filterM p xs
      pure (if b then x : ys else ys)

--------------------------------------------------------------------------------
-- Time & Duration Tests
--------------------------------------------------------------------------------

timeUnitTests :: TestTree
timeUnitTests =
  testGroup
    "Time & Duration Parsing and Normalization"
    [ testCase "Parses lax abbreviations for minutes" $ do
        let minuteExamples = ["10m", "10 min", "10 mins", "10 minute", "10 minutes", " 10  min "]
        forM_ minuteExamples $ \str ->
          case parseText str of
            Left err -> assertFailure $ "Failed parsing " ++ show str ++ ": " ++ err
            Right (d :: Duration) -> do
              d.value @?= 10
              d.unit @?= Minute
    , testCase "Parses lax abbreviations for hours" $ do
        let hourExamples = ["1h", "1 hr", "1 hrs", "1 hour", " 1  hour "]
        forM_ hourExamples $ \str ->
          case parseText str of
            Left err -> assertFailure $ "Failed parsing " ++ show str ++ ": " ++ err
            Right (d :: Duration) -> do
              d.value @?= 1
              d.unit @?= Hour
    , testCase "Parses lax abbreviations for days" $ do
        let dayExamples = ["2d", "2 day", "2 days", " 2  days "]
        forM_ dayExamples $ \str ->
          case parseText str of
            Left err -> assertFailure $ "Failed parsing " ++ show str ++ ": " ++ err
            Right (d :: Duration) -> do
              d.value @?= 2
              d.unit @?= Day
    , testCase "Renders canonical representations" $ do
        canonicalDurationText (Duration 5 Minute) @?= "5 min"
        canonicalDurationText (Duration 1 Hour) @?= "1 hour"
        canonicalDurationText (Duration 3 Hour) @?= "3 hours"
        canonicalDurationText (Duration 1 Day) @?= "1 day"
        canonicalDurationText (Duration 2 Day) @?= "2 days"
    , testCase "Normalizing rewrite preserves duration value" $ do
        let laxInputs = ["10m", "10 mins", "1hr", "3hrs", "2d", "4days"]
        forM_ laxInputs $ \input ->
          case parseText input of
            Left err -> assertFailure $ "Failed to parse " ++ show input ++ ": " ++ err
            Right (d :: Duration) -> do
              let canonical = toText d
              case parseText canonical of
                Left err2 -> assertFailure $ "Failed to re-parse canonical " ++ show canonical ++ ": " ++ err2
                Right d' -> d' @?= d
    , testCase "Duration computable operations" $ do
        toMinutes (Duration 10 Minute) @?= 10
        toMinutes (Duration 2 Hour) @?= 120
        toMinutes (Duration 1 Day) @?= 1440
        addDuration (Duration 15 Minute) (Duration 30 Minute) @?= Duration 45 Minute
        addDuration (Duration 30 Minute) (Duration 1 Hour) @?= Duration 90 Minute
        scaleDuration 3 (Duration 10 Minute) @?= Duration 30 Minute
        assertBool "10 min < 1 hour" (Duration 10 Minute < Duration 1 Hour)
        assertBool "1 hour < 1 day" (Duration 1 Hour < Duration 1 Day)
    ]

--------------------------------------------------------------------------------
-- ExpeditionTime Tests
--------------------------------------------------------------------------------

expeditionTimeTests :: TestTree
expeditionTimeTests =
  testGroup
    "ExpeditionTime Parsing, Formatting, and Pulse Math"
    [ testCase "Parses Day and HH:MM format" $ do
        case parseText "Day 1, 08:45" of
          Left err -> assertFailure $ "Failed to parse Day format: " ++ err
          Right (et :: ExpeditionTime) -> do
            et.totalMinutes @?= 525
            expeditionDay et @?= 1
            expeditionHour et @?= 8
            expeditionMinute et @?= 45
            formatExpeditionTime et @?= "Day 1, 08:45"
    , testCase "Parses Day 2 time correctly" $ do
        case parseText "Day 2, 01:15" of
          Left err -> assertFailure $ "Failed to parse Day 2: " ++ err
          Right (et :: ExpeditionTime) -> do
            et.totalMinutes @?= 1515
            expeditionDay et @?= 2
            expeditionHour et @?= 1
            expeditionMinute et @?= 15
            formatExpeditionTime et @?= "Day 2, 01:15"
    , testCase "Formats padded single digits" $ do
        formatExpeditionTime (ExpeditionTime 480) @?= "Day 1, 08:00"
        formatExpeditionTime (ExpeditionTime 5) @?= "Day 1, 00:05"
    , testCase "Arithmetic operations" $ do
        let t0 = ExpeditionTime 480
        addMinutes 45 t0 @?= ExpeditionTime 525
        addExpeditionDuration (Duration 2 Hour) t0 @?= ExpeditionTime 600
    , testCase "Threshold crossing pulse math (clockTicksCrossed)" $ do
        let t0 = ExpeditionTime 0
        -- Delve 30m ticks:
        clockTicksCrossed t0 (Duration 25 Minute) (Duration 30 Minute) @?= 0
        clockTicksCrossed (ExpeditionTime 25) (Duration 10 Minute) (Duration 30 Minute) @?= 1
        clockTicksCrossed t0 (Duration 65 Minute) (Duration 30 Minute) @?= 2
        clockTicksCrossed (ExpeditionTime 30) (Duration 30 Minute) (Duration 30 Minute) @?= 1
        clockTicksCrossed (ExpeditionTime 30) (Duration 0 Minute) (Duration 30 Minute) @?= 0
        -- Wilderness 60m ticks:
        clockTicksCrossed (ExpeditionTime 45) (Duration 45 Minute) (Duration 60 Minute) @?= 1
        clockTicksCrossed (ExpeditionTime 45) (Duration 80 Minute) (Duration 60 Minute) @?= 2
    ]

--------------------------------------------------------------------------------
-- Module Manifest Parsing
--------------------------------------------------------------------------------

testModuleParsing :: FilePath -> Assertion
testModuleParsing path = do
  result <- decodeFileEither path :: IO (Either ParseException ModuleManifest)
  case result of
    Left err -> assertFailure $ "Failed to decode module.yaml: " ++ show err
    Right m -> do
      m.id @?= ModuleId "crag_gallows"
      m.name @?= "Crag-Gallows Delve"
      m.startingLocation @?= LocationId "haven_crow_roost"
      m.startingTime @?= ExpeditionTime 480
      formatExpeditionTime m.startingTime @?= "Day 1, 08:00"

      -- Clock configs
      case Map.lookup (ClockDeckId "site_activity_clock") m.clockConfigs of
        Nothing -> assertFailure "Expected site_activity_clock config"
        Just cfg -> do
          cfg.name @?= Just "Site Activity Clock"
          cfg.tickInterval @?= Duration 30 Minute

      case Map.lookup (ClockDeckId "wilderness_clock") m.clockConfigs of
        Nothing -> assertFailure "Expected wilderness_clock config"
        Just cfg -> do
          cfg.name @?= Just "Wilderness Clock"
          cfg.tickInterval @?= Duration 60 Minute

      -- Starting actors
      length m.startingActors @?= 1
      let pc = head m.startingActors
      pc.name @?= "vallhach"
      pc.initialHandSize @?= Just 4

      -- Encounters
      case Map.lookup (LocationId "loc_sorting_yard") m.locationEncounters of
        Nothing -> assertFailure "Expected encounter at loc_sorting_yard"
        Just enemies -> length enemies @?= 2

testModuleRoundtrip :: FilePath -> Assertion
testModuleRoundtrip path = do
  result <- decodeFileEither path :: IO (Either ParseException ModuleManifest)
  case result of
    Left err -> assertFailure $ "Failed initial decode: " ++ show err
    Right m -> do
      let encoded = encode m
      case decodeEither' encoded of
        Left err2 -> assertFailure $ "Failed to decode re-encoded module manifest: " ++ show err2
        Right (m' :: ModuleManifest) -> m' @?= m

--------------------------------------------------------------------------------
-- Location Card Parsing
--------------------------------------------------------------------------------

testLocationParsing :: FilePath -> Assertion
testLocationParsing path = do
  result <- decodeFileEither path :: IO (Either ParseException [LocationCard])
  case result of
    Left err -> assertFailure $ "Failed to decode Location cards: " ++ show err
    Right cards -> do
      length cards @?= 4

      -- Loc 1: haven_crow_roost
      let haven = head cards
      haven.id @?= LocationId "haven_crow_roost"
      getRawText haven.name @?= "Crow's Roost Haven"
      haven.baseTime @?= Duration 10 Minute
      case haven.exits of
        Nothing -> assertFailure "Expected exits on haven"
        Just [exit1] -> do
          exit1.to @?= LocationId "site_timber_cut"
          exit1.viaTravel @?= Just (TravelId "trv_low_scree_path")
          exit1.status @?= ExitOpen
        Just other -> assertFailure $ "Unexpected exits on haven: " ++ show (length other)

      -- Haven actions have enablesAction & modifiesStrength
      case haven.actions of
        Nothing -> assertFailure "Expected actions on haven"
        Just [act1] -> do
          getRawText act1.name @?= "Survey Descent"
          act1.scope @?= ScopeSolo
          act1.enablesAction @?= Just "Rigged Mountain Line"
          act1.modifiesStrength @?= Just (-3)
        Just other -> assertFailure $ "Unexpected actions on haven: " ++ show (length other)

      -- Loc 2: site_timber_cut
      let timber = cards !! 1
      timber.id @?= LocationId "site_timber_cut"
      case timber.exits of
        Nothing -> assertFailure "Expected exits on site_timber_cut"
        Just exitsList -> do
          length exitsList @?= 2
          let e1 = head exitsList
          e1.to @?= LocationId "haven_crow_roost"
          e1.viaTravel @?= Just (TravelId "trv_low_scree_path")
          let e2 = exitsList !! 1
          e2.to @?= LocationId "loc_barricaded_portal"
          e2.viaTravel @?= Nothing

      -- Loc 3: loc_barricaded_portal
      let portal = cards !! 2
      portal.id @?= LocationId "loc_barricaded_portal"
      getRawText portal.name @?= "The Barricaded Portal"
      portal.cardType @?= "Location"
      portal.governingClock @?= Just (ClockDeckId "site_activity_clock")
      portal.baseTime @?= Duration 5 Minute
      portal.tags @?= Just ("Chokepoint" NE.:| ["Dim", "ColdDamp"])

      -- Portal Exits
      case portal.exits of
        Nothing -> assertFailure "Expected exits to be present"
        Just exitsList -> do
          length exitsList @?= 2
          let exit1 = head exitsList
          exit1.to @?= LocationId "loc_sorting_yard"
          exit1.status @?= ExitBlocked
          let exit2 = exitsList !! 1
          exit2.to @?= LocationId "site_timber_cut"
          exit2.status @?= ExitOpen

      -- Portal Actions
      case portal.actions of
        Nothing -> assertFailure "Expected actions to be present"
        Just acts -> do
          length acts @?= 4
          -- Action 1: Sledgehammer Breach (ScopeSolo default)
          let a1 = head acts
          getRawText a1.name @?= "Sledgehammer Breach"
          a1.time @?= Duration 1 Minute
          a1.scope @?= ScopeSolo
          case a1.challenge of
            Nothing -> assertFailure "Expected challenge on Sledgehammer Breach"
            Just ch -> do
              ch.color @?= Red
              ch.strength @?= 22
              ch.consequences @?= Just ("Exhaustion" NE.:| ["BluntForce"])
          a1.tags @?= Just ("Loud" NE.:| ["Exhausting"])
          a1.unblocks @?= Just (LocationId "loc_sorting_yard")

          -- Action 3: Structural Keystoning (has enablesAction)
          let a3 = acts !! 2
          a3.enablesAction @?= Just "Squeeze Through Keyed Timbers"
          a3.modifiesStrength @?= Just (-4)

          -- Action 4: Methodical Deconstruction (Teamwork tag -> ScopeTeamwork)
          let a4 = acts !! 3
          getRawText a4.name @?= "Methodical Deconstruction"
          a4.time @?= Duration 30 Minute
          a4.timePerImpact @?= Just (Duration 10 Minute)
          a4.scope @?= ScopeTeamwork
          case a4.challenge of
            Nothing -> assertFailure "Expected challenge on Methodical Deconstruction"
            Just ch -> do
              ch.color @?= Red
              ch.strength @?= 16
              ch.consequences @?= Just ("Fatigue" NE.:| [])

      -- Loc 4: loc_sorting_yard
      let yard = cards !! 3
      yard.id @?= LocationId "loc_sorting_yard"
      getRawText yard.name @?= "The Sorting Yard"
      case yard.exits of
        Nothing -> assertFailure "Expected exits on loc_sorting_yard"
        Just [e] -> do
          e.to @?= LocationId "loc_barricaded_portal"
          e.status @?= ExitOpen
        Just other -> assertFailure $ "Unexpected exits on yard: " ++ show (length other)

testLocationRoundtrip :: FilePath -> Assertion
testLocationRoundtrip path = do
  result <- decodeFileEither path :: IO (Either ParseException [LocationCard])
  case result of
    Left err -> assertFailure $ "Failed initial decode: " ++ show err
    Right cards -> do
      let encoded = encode cards
      case decodeEither' encoded of
        Left err2 -> assertFailure $ "Failed to decode re-encoded Location cards: " ++ show err2
        Right (cards' :: [LocationCard]) -> cards' @?= cards

--------------------------------------------------------------------------------
-- Travel Card Parsing
--------------------------------------------------------------------------------

testTravelParsing :: FilePath -> Assertion
testTravelParsing path = do
  result <- decodeFileEither path :: IO (Either ParseException [TravelCard])
  case result of
    Left err -> assertFailure $ "Failed to decode Travel cards: " ++ show err
    Right cards -> do
      length cards @?= 1
      let trv = head cards
      trv.id @?= TravelId "trv_low_scree_path"
      getRawText trv.name @?= "The Low Scree Path"
      trv.cardType @?= "Travel"
      trv.governingClock @?= Just (ClockDeckId "wilderness_clock")

      -- Route with LocationId endpoints
      trv.route.from @?= LocationId "haven_crow_roost"
      trv.route.to @?= LocationId "site_timber_cut"
      trv.route.distanceLeagues @?= Just 1.5
      trv.route.baseTime @?= Duration 45 Minute
      trv.route.terrainTags @?= Just ("LooseSlate" NE.:| ["WindBuffeted", "WolfSign"])

      -- Paces: Travel paces default to ScopeEveryone
      length trv.paces @?= 3
      let pace1 = NE.head trv.paces
      getRawText pace1.name @?= "Measured Mountain March"
      pace1.time @?= Duration 45 Minute
      pace1.scope @?= ScopeEveryone
      case pace1.challenge of
        Nothing -> assertFailure "Expected challenge on Measured Mountain March"
        Just ch -> do
          ch.color @?= Red
          ch.strength @?= 10
          ch.consequences @?= Just ("Fatigue" NE.:| [])
      pace1.tags @?= Just ("StandardPace" NE.:| ["Travel", "Exertion"])

      let pace2 = trv.paces NE.!! 1
      getRawText pace2.name @?= "Agile Scree Scramble"
      pace2.time @?= Duration 20 Minute
      pace2.scope @?= ScopeEveryone
      case pace2.challenge of
        Nothing -> assertFailure "Expected challenge on Agile Scree Scramble"
        Just ch -> do
          ch.color @?= Yellow
          ch.strength @?= 15
          ch.consequences @?= Just ("BruisedShins" NE.:| ["RattleScreeNoise"])

      -- Expedients
      case trv.expedients of
        Nothing -> assertFailure "Expected expedients to be present"
        Just (expeds :: TravelExpedients) -> do
          assertBool "Camp restriction present" (isJust expeds.campRestriction)
          case expeds.actions of
            Nothing -> assertFailure "Expected actions in expedients"
            Just (acts :: [ExplorationAction]) -> do
              length acts @?= 1
              let act = head acts
              getRawText act.name @?= "Forage Trail Cut"
              act.time @?= Duration 30 Minute
              act.scope @?= ScopeSolo
              case act.challenge of
                Nothing -> assertFailure "Expected challenge on Forage Trail Cut"
                Just (ch :: ChallengeDef) -> do
                  ch.color @?= Blue
                  ch.strength @?= 10

testTravelRoundtrip :: FilePath -> Assertion
testTravelRoundtrip path = do
  result <- decodeFileEither path :: IO (Either ParseException [TravelCard])
  case result of
    Left err -> assertFailure $ "Failed initial decode: " ++ show err
    Right cards -> do
      let encoded = encode cards
      case decodeEither' encoded of
        Left err2 -> assertFailure $ "Failed to decode re-encoded Travel cards: " ++ show err2
        Right (cards' :: [TravelCard]) -> cards' @?= cards

--------------------------------------------------------------------------------
-- Clock Event Card Parsing
--------------------------------------------------------------------------------

testClockParsing :: FilePath -> Assertion
testClockParsing path = do
  result <- decodeFileEither path :: IO (Either ParseException [ClockEventCard])
  case result of
    Left err -> assertFailure $ "Failed to decode Clock cards: " ++ show err
    Right cards -> do
      length cards @?= 2

      -- Card 1: Sentry Shift Rotation
      let c1 = head cards
      c1.id @?= ClockEventId "clk_site_sentry_rotation"
      getRawText c1.name @?= "Sentry Shift Rotation"
      c1.cardType @?= "ClockEvent"
      c1.clockDeck @?= ClockDeckId "site_activity_clock"
      c1.urgency @?= Immediate
      c1.tags @?= Just ("InhabitantAction" NE.:| [])
      case c1.narrative of
        ClockNarrative _ mCue -> assertBool "Sensory cue present on c1" (isJust mCue)
      length c1.effects @?= 2

      -- Effect 1 on c1: unguarded
      let eff1 = head c1.effects
      eff1.target @?= "loc_barricaded_portal"
      eff1.duration @?= Just (Duration 20 Minute)
      eff1.unguarded @?= Just True
      eff1.hazard @?= (Nothing :: Maybe ChallengeDef)

      -- Effect 2 on c1: spawnActors
      let eff2 = c1.effects !! 1
      eff2.target @?= "loc_sorting_yard"
      eff2.spawnActors @?= Just ["goblin_lookout", "goblin_lookout"]

      -- Card 2: Sudden Scree Squall
      let c2 = cards !! 1
      c2.id @?= ClockEventId "clk_wild_sudden_scree_squall"
      c2.urgency @?= OngoingModifier
      length c2.effects @?= 1
      let squallEff = head c2.effects
      squallEff.target @?= "current_zone"
      squallEff.duration @?= Just (Duration 1 Hour)
      squallEff.extinguishesLight @?= True
      squallEff.challengeModifier @?= Just (ChallengeModifier (Just Yellow) 5)
      case squallEff.hazard of
        Nothing -> assertFailure "Expected hazard on squall effect"
        Just hz -> do
          hz.color @?= Yellow
          hz.strength @?= 12
          hz.consequences @?= Just ("BluntForce" NE.:| ["BruisedShins"])

testClockRoundtrip :: FilePath -> Assertion
testClockRoundtrip path = do
  result <- decodeFileEither path :: IO (Either ParseException [ClockEventCard])
  case result of
    Left err -> assertFailure $ "Failed initial decode: " ++ show err
    Right cards -> do
      let encoded = encode cards
      case decodeEither' encoded of
        Left err2 -> assertFailure $ "Failed to decode re-encoded Clock cards: " ++ show err2
        Right (cards' :: [ClockEventCard]) -> cards' @?= cards

--------------------------------------------------------------------------------
-- Graph Connectivity
--------------------------------------------------------------------------------

testGraphConnectivity :: FilePath -> FilePath -> Assertion
testGraphConnectivity locPath trvPath = do
  locRes <- decodeFileEither locPath :: IO (Either ParseException [LocationCard])
  trvRes <- decodeFileEither trvPath :: IO (Either ParseException [TravelCard])
  case (locRes, trvRes) of
    (Left e, _) -> assertFailure $ "Failed to load locations: " ++ show e
    (_, Left e) -> assertFailure $ "Failed to load travel: " ++ show e
    (Right locs, Right travels) -> do
      let locMap = Map.fromList [(l.id, l) | l <- locs]
      let trvMap = Map.fromList [(t.id, t) | t <- travels]

      -- Every location exit destination must exist in the location graph
      forM_ locs $ \loc -> do
        case loc.exits of
          Nothing -> pure ()
          Just exitsList -> forM_ exitsList $ \exit -> do
            assertBool
              ("Exit destination " ++ show exit.to ++ " from " ++ show loc.id ++ " must exist in locations")
              (Map.member exit.to locMap)
            case exit.viaTravel of
              Nothing -> pure ()
              Just tid ->
                assertBool
                  ("Travel route " ++ show tid ++ " from " ++ show loc.id ++ " must exist in travel.yaml")
                  (Map.member tid trvMap)

      -- Every travel card must connect two valid locations in the graph
      forM_ travels $ \trv -> do
        assertBool
          ("Travel " ++ show trv.id ++ " route.from " ++ show trv.route.from ++ " must exist in locations")
          (Map.member trv.route.from locMap)
        assertBool
          ("Travel " ++ show trv.id ++ " route.to " ++ show trv.route.to ++ " must exist in locations")
          (Map.member trv.route.to locMap)
