{-# LANGUAGE OverloadedRecordDot #-}
{-# LANGUAGE OverloadedStrings #-}

module ExplorationLogicTest (test_explorationLogic) where

import Control.Monad.State (evalState, runState)
import Data.ByteString qualified as BS
import Data.Map.Strict qualified as Map
import Data.Maybe (fromMaybe, isJust)
import Data.Yaml (decodeFileEither)
import System.Directory (doesFileExist)
import System.FilePath ((</>))
import System.Random (mkStdGen)
import Test.Tasty
import Test.Tasty.HUnit

import Core.Card.Exploration
  ( ClockDeckId (..)
  , ClockEffect (..)
  , ClockEventCard (..)
  , ClockEventId (..)
  , ClockNarrative (..)
  , ClockUrgency (..)
  , ExitStatus (..)
  , LocationCard (..)
  , LocationExit (..)
  , LocationId (..)
  , ModuleManifest (..)
  , TravelCard (..)
  , TravelId (..)
  )
import Core.DSL (parseText)
import Core.Logic.Exploration
  ( advanceTimeAndTriggerClocks
  , advanceTimeWithInterrupt
  , applyClockEffect
  , completeTravel
  , drawClockCard
  , getActiveGoverningClock
  , initWorldState
  , isLocationUnguarded
  , setExitStatus
  , setLightSource
  , transitionViaExit
  , unblockExit
  )
import Core.NonEmptyText (unsafeNonEmptyText)
import Core.State
  ( ClockDeckState (..)
  , Direction (..)
  , ExplorationEvent (..)
  , ExplorationFocus (..)
  , LightSourceState (..)
  , LocationRuntimeState (..)
  , WorldState (..)
  )
import Core.Time
  ( Duration (..)
  , ExpeditionTime (..)
  , TimeUnit (..)
  )

test_explorationLogic :: IO TestTree
test_explorationLogic = do
  paths <- findCragGallowsPaths
  pure $
    testGroup
      "Exploration & World State Engine Tests"
      [ testCase "Initialize WorldState from crag_gallows manifest" $ testWorldInitialization paths
      , testCase "Exit transitions: direct room-to-room vs travel edges" $ testExitTransitions paths
      , testCase "Light fuel decrement and extinction" testLightFuelMechanics
      , testCase "Timed ClockEffect expiration" testClockEffectExpiration
      , testCase "Scheduled clock ticks vs [Loud] interrupts" testClockTicksAndLoud
      , testCase "Clock deck reshuffle on exhaustion" testClockReshuffle
      ]

data ModulePaths = ModulePaths
  { manifestPath :: FilePath
  , locationsPath :: FilePath
  , travelPath :: FilePath
  , clocksPath :: FilePath
  }

findCragGallowsPaths :: IO ModulePaths
findCragGallowsPaths = do
  let searchRoots =
        [ "data/modules/crag_gallows"
        , "../data/modules/crag_gallows"
        , "../../data/modules/crag_gallows"
        ]
  found <- filterM doesFileExist [r </> "module.yaml" | r <- searchRoots]
  case found of
    (mFile : _) -> do
      let root = takeDirectory' mFile
      pure
        ModulePaths
          { manifestPath = mFile
          , locationsPath = root </> "locations.yaml"
          , travelPath = root </> "travel.yaml"
          , clocksPath = root </> "clocks.yaml"
          }
    [] -> error "Could not locate data/modules/crag_gallows/module.yaml"
  where
    filterM _ [] = pure []
    filterM p (x : xs) = do
      b <- p x
      ys <- filterM p xs
      pure (if b then x : ys else ys)
    takeDirectory' fp = reverse $ drop 1 $ dropWhile (/= '/') $ reverse fp

loadCragGallowsWorld :: ModulePaths -> IO WorldState
loadCragGallowsWorld paths = do
  mManifest <- decodeFileEither paths.manifestPath
  mLocations <- decodeFileEither paths.locationsPath
  mTravel <- decodeFileEither paths.travelPath
  mClocks <- decodeFileEither paths.clocksPath
  case (mManifest, mLocations, mTravel, mClocks) of
    (Right manifest, Right locs, Right travel, Right clocks) ->
      pure $ initWorldState manifest locs travel clocks
    (Left e, _, _, _) -> assertFailure $ "Failed to load module.yaml: " ++ show e
    (_, Left e, _, _) -> assertFailure $ "Failed to load locations.yaml: " ++ show e
    (_, _, Left e, _) -> assertFailure $ "Failed to load travel.yaml: " ++ show e
    (_, _, _, Left e) -> assertFailure $ "Failed to load clocks.yaml: " ++ show e

testWorldInitialization :: ModulePaths -> Assertion
testWorldInitialization paths = do
  ws <- loadCragGallowsWorld paths
  ws.focus @?= AtLocation (LocationId "haven_crow_roost")
  ws.time @?= ExpeditionTime 480 -- 08:00
  Map.member (LocationId "haven_crow_roost") ws.locations @?= True
  Map.member (LocationId "loc_barricaded_portal") ws.locations @?= True
  Map.member (TravelId "trv_low_scree_path") ws.travelCards @?= True
  Map.member (ClockDeckId "site_activity_clock") ws.clockDecks @?= True
  Map.member (ClockDeckId "wilderness_clock") ws.clockDecks @?= True

  -- Barricaded portal should have loc_sorting_yard as blocked initially
  let portalSt = Map.lookup (LocationId "loc_barricaded_portal") ws.locationStates
  case portalSt of
    Nothing -> assertFailure "Barricaded portal runtime state missing"
    Just st -> Map.lookup (LocationId "loc_sorting_yard") st.exitStatuses @?= Just ExitBlocked

testExitTransitions :: ModulePaths -> Assertion
testExitTransitions paths = do
  ws <- loadCragGallowsWorld paths

  -- 1. Haven exit to Timber Cut via travel edge
  let havenLoc = ws.locations Map.! LocationId "haven_crow_roost"
  let havenExits = fromMaybe [] havenLoc.exits
  let havenExitToTimber = head [e | e <- havenExits, e.to == LocationId "site_timber_cut"]

  case transitionViaExit havenExitToTimber ws of
    Left err -> assertFailure $ "Failed haven travel exit: " ++ show err
    Right (wsOnTravel, evs, dur) -> do
      dur @?= Duration 0 Minute
      wsOnTravel.focus @?= OnTravel (TravelId "trv_low_scree_path") Forward
      evs
        @?= [ PartyMoved
                (AtLocation (LocationId "haven_crow_roost"))
                (OnTravel (TravelId "trv_low_scree_path") Forward)
            ]

      -- 2. Completing travel arrives at Timber Cut
      case completeTravel wsOnTravel of
        Left err -> assertFailure $ "Failed complete travel: " ++ show err
        Right (wsAtTimber, trvEvs) -> do
          wsAtTimber.focus @?= AtLocation (LocationId "site_timber_cut")
          trvEvs
            @?= [ PartyMoved
                    (OnTravel (TravelId "trv_low_scree_path") Forward)
                    (AtLocation (LocationId "site_timber_cut"))
                ]

          -- 3. Timber cut to Barricaded Portal is a direct room-to-room exit (viaTravel = Nothing)
          let timberLoc = wsAtTimber.locations Map.! LocationId "site_timber_cut"
          let timberExits = fromMaybe [] timberLoc.exits
          let timberExitToPortal = head [e | e <- timberExits, e.to == LocationId "loc_barricaded_portal"]
          timberExitToPortal.viaTravel @?= Nothing

          case transitionViaExit timberExitToPortal wsAtTimber of
            Left err -> assertFailure $ "Failed direct room transition: " ++ show err
            Right (wsAtPortal, dirEvs, directDur) -> do
              directDur @?= Duration 5 Minute -- target baseTime
              wsAtPortal.focus @?= AtLocation (LocationId "loc_barricaded_portal")
              dirEvs
                @?= [ PartyMoved
                        (AtLocation (LocationId "site_timber_cut"))
                        (AtLocation (LocationId "loc_barricaded_portal"))
                    ]

              -- 4. Barricaded portal exit to sorting yard is blocked
              let portalLoc = wsAtPortal.locations Map.! LocationId "loc_barricaded_portal"
              let portalExits = fromMaybe [] portalLoc.exits
              let portalExitToYard = head [e | e <- portalExits, e.to == LocationId "loc_sorting_yard"]

              case transitionViaExit portalExitToYard wsAtPortal of
                Left err -> err @?= "Exit is blocked"
                Right _ -> assertFailure "Blocked exit unexpectedly permitted traversal"

              -- 5. Unblocking exit allows traversal
              let (wsUnblocked, unblockEvs) = unblockExit (LocationId "loc_barricaded_portal") (LocationId "loc_sorting_yard") wsAtPortal
              unblockEvs
                @?= [ExitStatusChanged (LocationId "loc_barricaded_portal") (LocationId "loc_sorting_yard") ExitOpen]
              case transitionViaExit portalExitToYard wsUnblocked of
                Left err -> assertFailure $ "Unblocked exit failed traversal: " ++ show err
                Right (wsAtYard, _, yardDur) -> do
                  yardDur @?= Duration 5 Minute
                  wsAtYard.focus @?= AtLocation (LocationId "loc_sorting_yard")

testLightFuelMechanics :: Assertion
testLightFuelMechanics = do
  let emptyWorld =
        WorldState
          { moduleId = Nothing
          , time = ExpeditionTime 480
          , focus = AtLocation (LocationId "test_loc")
          , locations = Map.empty
          , travelCards = Map.empty
          , locationStates = Map.empty
          , clockDecks = Map.empty
          , lightState = LightSourceState Nothing
          , activeTeamworkChallenge = Nothing
          , locationEncounters = Map.empty
          , actorTemplates = Map.empty
          }
  let (wsLit, litEvs) = setLightSource "Torch" 30 emptyWorld
  litEvs @?= [LightFuelDecreased (Just ("Torch", 30))]

  let gen = mkStdGen 42

  -- Advance 10 minutes: fuel decreases to 20
  let (ws10, evs10) = evalState (advanceTimeAndTriggerClocks (Duration 10 Minute) [] wsLit) gen
  ws10.time @?= ExpeditionTime 490
  ws10.lightState @?= LightSourceState (Just ("Torch", 20))
  assertBool
    "Emitted LightFuelDecreased (Just 20)"
    (LightFuelDecreased (Just ("Torch", 20)) `elem` evs10)

  -- Advance 25 minutes: fuel runs out, light extinguished
  let (ws35, evs35) = evalState (advanceTimeAndTriggerClocks (Duration 25 Minute) [] ws10) gen
  ws35.time @?= ExpeditionTime 515
  ws35.lightState @?= LightSourceState Nothing
  assertBool "Emitted LightExtinguished" (LightExtinguished "Torch" `elem` evs35)

testClockEffectExpiration :: Assertion
testClockEffectExpiration = do
  let locId = LocationId "loc_test"
  let initialLocSt =
        LocationRuntimeState
          { exitStatuses = Map.empty
          , activeEffects = []
          , enabledActions = []
          , modifiedStrengths = Map.empty
          , spawnedActors = []
          }
  let initialWorld =
        WorldState
          { moduleId = Nothing
          , time = ExpeditionTime 100
          , focus = AtLocation locId
          , locations = Map.empty
          , travelCards = Map.empty
          , locationStates = Map.singleton locId initialLocSt
          , clockDecks = Map.empty
          , lightState = LightSourceState Nothing
          , activeTeamworkChallenge = Nothing
          , locationEncounters = Map.empty
          , actorTemplates = Map.empty
          }

  let unguardedEffect =
        ClockEffect
          { target = "loc_test"
          , text = "Unguarded for 20 min"
          , duration = Just (Duration 20 Minute)
          , hazard = Nothing
          , setExitStatus = Nothing
          , unguarded = Just True
          , challengeModifier = Nothing
          , extinguishesLight = False
          , spawnActors = Nothing
          }

  let (wsWithEffect, _) = applyClockEffect locId unguardedEffect (Just (ClockEventId "test_clk")) initialWorld
  isLocationUnguarded locId wsWithEffect @?= True

  let gen = mkStdGen 123

  -- Advance 10 minutes (time 110 <= 120): effect still active
  let (ws110, _) = evalState (advanceTimeAndTriggerClocks (Duration 10 Minute) [] wsWithEffect) gen
  isLocationUnguarded locId ws110 @?= True

  -- Advance 15 minutes (time 125 > 120): effect expired
  let (ws125, evs125) = evalState (advanceTimeAndTriggerClocks (Duration 15 Minute) [] ws110) gen
  isLocationUnguarded locId ws125 @?= False
  assertBool "ClockEffectExpired event emitted" (any isClockExpired evs125)
  where
    isClockExpired (ClockEffectExpired _ _) = True
    isClockExpired _ = False

testClockTicksAndLoud :: Assertion
testClockTicksAndLoud = do
  let clockId = ClockDeckId "site_clock"
  let locId = LocationId "loc_site"
  let locCard =
        LocationCard
          { id = locId
          , name = unsafeNonEmptyText "Site"
          , cardType = "Location"
          , governingClock = Just clockId
          , baseTime = Duration 5 Minute
          , tags = Nothing
          , exits = Nothing
          , narrative = "Site"
          , actions = Nothing
          }
  let dummyNarrative = case parseText "Sample sensory narrative" of
        Right rt -> ClockNarrative rt Nothing
        Left err -> error err
  let sampleEvent =
        ClockEventCard
          { id = ClockEventId "clk_1"
          , name = unsafeNonEmptyText "Sample Event"
          , cardType = "ClockEvent"
          , clockDeck = clockId
          , urgency = Immediate
          , tags = Nothing
          , narrative = dummyNarrative
          , effects = []
          }
  let clockDeck =
        ClockDeckState
          { drawPile = [sampleEvent, sampleEvent, sampleEvent, sampleEvent]
          , discardPile = []
          , tickInterval = Duration 30 Minute
          , accumulatedMinutes = 0
          }
  let initialLocSt =
        LocationRuntimeState
          { exitStatuses = Map.empty
          , activeEffects = []
          , enabledActions = []
          , modifiedStrengths = Map.empty
          , spawnedActors = []
          }
  let ws =
        WorldState
          { moduleId = Nothing
          , time = ExpeditionTime 0
          , focus = AtLocation locId
          , locations = Map.singleton locId locCard
          , travelCards = Map.empty
          , locationStates = Map.singleton locId initialLocSt
          , clockDecks = Map.singleton clockId clockDeck
          , lightState = LightSourceState Nothing
          , activeTeamworkChallenge = Nothing
          , locationEncounters = Map.empty
          , actorTemplates = Map.empty
          }

  let gen = mkStdGen 999

  -- 1. Advance 10 minutes quietly: no tick crossed (0 -> 10, interval 30)
  let (ws10, evs10) = evalState (advanceTimeAndTriggerClocks (Duration 10 Minute) [] ws) gen
  filter isEffortFlush evs10 @?= []
  filter isClockDrawn evs10 @?= []

  -- 2. Advance 5 minutes with Loud tag: immediate draw fired! (10 -> 15 min)
  let (ws15, evs15) = evalState (advanceTimeAndTriggerClocks (Duration 5 Minute) ["Loud"] ws10) gen
  filter isEffortFlush evs15 @?= []
  length (filter isClockDrawn evs15) @?= 1

  -- 3. Advance 20 minutes quietly: crosses 30 min boundary (15 -> 35 min)
  let (ws35, evs35) = evalState (advanceTimeAndTriggerClocks (Duration 20 Minute) [] ws15) gen
  length (filter isEffortFlush evs35) @?= 1
  length (filter isClockDrawn evs35) @?= 1

  -- 4. Advance 30 minutes with Loud tag: 1 immediate Loud draw + 1 scheduled tick draw (35 -> 65 min)
  let (_, evs65) = evalState (advanceTimeAndTriggerClocks (Duration 30 Minute) ["[Loud]"] ws35) gen
  length (filter isEffortFlush evs65) @?= 1
  length (filter isClockDrawn evs65) @?= 2
  where
    isEffortFlush EffortCycleFlushed = True
    isEffortFlush _ = False

    isClockDrawn (ClockCardDrawn _ _) = True
    isClockDrawn _ = False

testClockReshuffle :: Assertion
testClockReshuffle = do
  let clockId = ClockDeckId "clk_deck"
  let dummyNarrative = case parseText "Card sensory narrative" of
        Right rt -> ClockNarrative rt Nothing
        Left err -> error err
  let makeCard cid =
        ClockEventCard
          { id = ClockEventId cid
          , name = unsafeNonEmptyText "Card"
          , cardType = "ClockEvent"
          , clockDeck = clockId
          , urgency = Immediate
          , tags = Nothing
          , narrative = dummyNarrative
          , effects = []
          }
  let c1 = makeCard "1"
  let c2 = makeCard "2"
  let c3 = makeCard "3"

  let deckSt =
        ClockDeckState
          { drawPile = [c1]
          , discardPile = [c2, c3]
          , tickInterval = Duration 30 Minute
          , accumulatedMinutes = 0
          }
  let ws =
        WorldState
          { moduleId = Nothing
          , time = ExpeditionTime 0
          , focus = AtLocation (LocationId "any")
          , locations = Map.empty
          , travelCards = Map.empty
          , locationStates = Map.empty
          , clockDecks = Map.singleton clockId deckSt
          , lightState = LightSourceState Nothing
          , activeTeamworkChallenge = Nothing
          , locationEncounters = Map.empty
          , actorTemplates = Map.empty
          }

  let gen = mkStdGen 777

  -- First draw pops c1, leaves draw pile empty
  let (ws1, mCard1, evs1) = evalState (drawClockCard clockId ws) gen
  fmap (\c -> c.id) mCard1 @?= Just (ClockEventId "1")
  evs1 @?= [ClockCardDrawn clockId c1]

  -- Second draw reshuffles discard pile ([c2, c3, c1]) and draws one
  let (ws2, mCard2, evs2) = evalState (drawClockCard clockId ws1) gen
  assertBool "Drew a card after reshuffle" (isJust mCard2)
  assertBool "Emitted ClockDeckShuffled" (ClockDeckShuffled clockId `elem` evs2)
