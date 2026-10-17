{-# LANGUAGE OverloadedRecordDot #-}
{-# LANGUAGE OverloadedStrings #-}

module ExplorationParsingTest (test_explorationParsing) where

import Control.Monad (forM_)
import Data.ByteString qualified as BS
import Data.List.NonEmpty qualified as NE
import Data.Maybe (fromMaybe, isJust)
import Data.Yaml (ParseException, decodeEither', decodeFileEither, encode)
import System.Directory (doesFileExist)
import System.FilePath ((</>))
import Test.Tasty
import Test.Tasty.HUnit

import Core.Card.Exploration
  ( ChallengeDef (..)
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
  , NodeId (..)
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
  , TimeUnit (..)
  , addDuration
  , canonicalDurationText
  , scaleDuration
  , toMinutes
  )

test_explorationParsing :: IO TestTree
test_explorationParsing = do
  locPath <- findFile "data/modules/crag_gallows/locations.yaml"
  trvPath <- findFile "data/modules/crag_gallows/travel.yaml"
  clkPath <- findFile "data/modules/crag_gallows/clocks.yaml"
  pure $
    testGroup
      "Exploration & Module Cards"
      [ timeUnitTests
      , testCase "Parse and validate locations.yaml" (testLocationParsing locPath)
      , testCase "Parse and validate travel.yaml" (testTravelParsing trvPath)
      , testCase "Parse and validate clocks.yaml" (testClockParsing clkPath)
      , testCase "Roundtrip encode/decode locations.yaml" (testLocationRoundtrip locPath)
      , testCase "Roundtrip encode/decode travel.yaml" (testTravelRoundtrip trvPath)
      , testCase "Roundtrip encode/decode clocks.yaml" (testClockRoundtrip clkPath)
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
-- Location Card Parsing
--------------------------------------------------------------------------------

testLocationParsing :: FilePath -> Assertion
testLocationParsing path = do
  result <- decodeFileEither path :: IO (Either ParseException [LocationCard])
  case result of
    Left err -> assertFailure $ "Failed to decode Location cards: " ++ show err
    Right cards -> do
      length cards @?= 1
      let loc = head cards
      loc.id @?= LocationId "loc_barricaded_portal"
      getRawText loc.name @?= "The Barricaded Portal"
      loc.cardType @?= "Location"
      loc.governingClock @?= Just (ClockDeckId "site_activity_clock")
      loc.baseTime @?= Duration 5 Minute
      loc.tags @?= Just ("Chokepoint" NE.:| ["Dim", "ColdDamp"])

      -- Exits
      case loc.exits of
        Nothing -> assertFailure "Expected exits to be present"
        Just exitsList -> do
          length exitsList @?= 1
          let exit = head exitsList
          exit.to @?= LocationId "loc_sorting_yard"
          exit.status @?= ExitBlocked
          assertBool "Exit passage should be present" (isJust exit.passage)

      -- Actions
      case loc.actions of
        Nothing -> assertFailure "Expected actions to be present"
        Just acts -> do
          length acts @?= 4
          -- Action 1: Sledgehammer Breach
          let a1 = head acts
          getRawText a1.name @?= "Sledgehammer Breach"
          a1.time @?= Duration 1 Minute
          case a1.challenge of
            Nothing -> assertFailure "Expected challenge on Sledgehammer Breach"
            Just ch -> do
              ch.color @?= Red
              ch.strength @?= 22
              ch.consequences @?= Just ("Exhaustion" NE.:| ["BluntForce"])
          a1.tags @?= Just ("Loud" NE.:| ["Exhausting"])
          a1.unblocks @?= Just (LocationId "loc_sorting_yard")

          -- Action 4: Methodical Deconstruction
          let a4 = acts !! 3
          getRawText a4.name @?= "Methodical Deconstruction"
          a4.time @?= Duration 30 Minute
          a4.timePerImpact @?= Just (Duration 10 Minute)
          case a4.challenge of
            Nothing -> assertFailure "Expected challenge on Methodical Deconstruction"
            Just ch -> do
              ch.color @?= Red
              ch.strength @?= 16
              ch.consequences @?= Just ("Fatigue" NE.:| [])

testLocationRoundtrip :: FilePath -> Assertion
testLocationRoundtrip path = do
  result <- decodeFileEither path :: IO (Either ParseException [LocationCard])
  case result of
    Left err -> assertFailure $ "Failed initial decode: " ++ show err
    Right cards -> do
      let encoded = encode cards
      case decodeEither' encoded of
        Left err -> assertFailure $ "Failed to decode re-encoded Location cards: " ++ show err
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

      -- Route
      trv.route.from @?= NodeId "haven_crow_roost"
      trv.route.to @?= NodeId "site_timber_cut"
      trv.route.distanceLeagues @?= Just 1.5
      trv.route.baseTime @?= Duration 45 Minute
      trv.route.terrainTags @?= Just ("LooseSlate" NE.:| ["WindBuffeted", "WolfSign"])

      -- Paces
      length trv.paces @?= 3
      let pace1 = NE.head trv.paces
      getRawText pace1.name @?= "Measured Mountain March"
      pace1.time @?= Duration 45 Minute
      pace1.challenge @?= Nothing -- Standard pace has no challenge
      pace1.tags @?= Just ("StandardPace" NE.:| [])

      let pace2 = trv.paces NE.!! 1
      getRawText pace2.name @?= "Agile Scree Scramble"
      pace2.time @?= Duration 20 Minute
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
        Left err -> assertFailure $ "Failed to decode re-encoded Travel cards: " ++ show err
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
      let eff1 = head c1.effects
      eff1.target @?= "loc_barricaded_portal"
      eff1.duration @?= Just (Duration 20 Minute)
      eff1.hazard @?= (Nothing :: Maybe ChallengeDef)

      -- Card 2: Sudden Scree Squall
      let c2 = cards !! 1
      c2.id @?= ClockEventId "clk_wild_sudden_scree_squall"
      c2.urgency @?= OngoingModifier
      length c2.effects @?= 1
      let eff2 = head c2.effects
      eff2.target @?= "current_zone"
      eff2.duration @?= Just (Duration 1 Hour)
      case eff2.hazard of
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
        Left err -> assertFailure $ "Failed to decode re-encoded Clock cards: " ++ show err
        Right (cards' :: [ClockEventCard]) -> cards' @?= cards
