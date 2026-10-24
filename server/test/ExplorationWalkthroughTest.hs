{-# LANGUAGE DuplicateRecordFields #-}
{-# LANGUAGE OverloadedRecordDot #-}
{-# LANGUAGE OverloadedStrings #-}

module ExplorationWalkthroughTest (test_exploration_walkthrough) where

import Control.Monad.State (runState)
import Data.Map.Strict qualified as Map
import Data.Maybe (isJust)
import System.Directory (doesDirectoryExist, doesFileExist)
import System.FilePath ((</>))
import Test.Tasty (TestTree, testGroup)
import Test.Tasty.HUnit (assertBool, testCase, (@?=))

import Api.Request (ApiRequest (..))
import Api.Types (Phase (..), PlayMode (..))
import Core.Card (CoreCard (..), Identified (..))
import Core.Card.Exploration
  ( ClockDeckId (..)
  , ExitStatus (..)
  , LocationId (..)
  , TravelId (..)
  )
import Core.NonEmptyText (unsafeNonEmptyText)
import Core.State
  ( ActiveChallenge (..)
  , ActorState (..)
  , ClockDeckState (..)
  , CoreCardState (..)
  , Direction (..)
  , ExplorationFocus (..)
  , ExplorationIntent (..)
  , LocationRuntimeState (..)
  , MapMode (..)
  , RevealedEffect (..)
  , WorldState (..)
  )
import Core.Time (Duration (..), ExpeditionTime (..), TimeUnit (..))
import Server.Dispatch (processCommand)
import Server.Game (GameState (..))
import Server.Scenario (loadScenario)

resolvePath :: FilePath -> IO FilePath
resolvePath rel = do
  dExists <- doesDirectoryExist rel
  fExists <- doesFileExist rel
  if dExists || fExists
    then pure rel
    else pure (".." </> rel)

test_exploration_walkthrough :: TestTree
test_exploration_walkthrough =
  testGroup
    "Exploration Module Walkthrough (Crag-Gallows)"
    [ testCase
        "Full Walkthrough: Crow's Roost -> Scree Path (Pace) -> Barricaded Portal (Breach) -> Sorting Yard (Crisis)"
        $ do
          modPath <- resolvePath "data/modules/crag_gallows"
          (initGame, gen0) <- loadScenario modPath (Just 42)

          -- 1. Initial State: haven_crow_roost
          initGame.playMode @?= ModeExploration
          initGame.phase @?= Planning
          initGame.roundNumber @?= 1

          let (valId, valInit) = head (Map.toList initGame.actors)
          valInit.coreState.hand @?= []
          valInit.coreState.vigilanceDial @?= 2
          length valInit.coreState.vigilancePool @?= 2

          case initGame.worldState of
            Nothing -> assertBool "Missing worldState" False
            Just ws -> do
              ws.focus @?= AtLocation (LocationId "haven_crow_roost")
              ws.time @?= ExpeditionTime 480 -- 08:00 AM

          -- 2. Traverse from haven_crow_roost to site_timber_cut (via trv_low_scree_path)
          let ((gPlan1, _, _, _), gen1) =
                runState
                  ( processCommand
                      (PlanExplorationIntent valId (IntentTraverseExit (LocationId "site_timber_cut")))
                      initGame
                  )
                  gen0
          let ((gRes1, _, _, _), gen2) =
                runState (processCommand StartResolution gPlan1) gen1
          gRes1.phase @?= Resolution

          let ((gAfterTravelStart, _, _, _), gen3) =
                runState (processCommand EndRound gRes1) gen2
          gAfterTravelStart.playMode @?= ModeExploration
          gAfterTravelStart.phase @?= Planning

          case gAfterTravelStart.worldState of
            Nothing -> assertBool "Missing worldState after travel start" False
            Just ws -> ws.focus @?= OnTravel (TravelId "trv_low_scree_path") Core.State.Forward

          -- 3. On Scree Path: Resolve travel pace 0 ("Measured Mountain March", Red 10, Fatigue)
          let ((gPlanPace, _, _, _), gen4) =
                runState (processCommand (PlanExplorationIntent valId (IntentPace 0)) gAfterTravelStart) gen3
          let ((gResPace, _, _, _logsPace), gen5) =
                runState (processCommand StartResolution gPlanPace) gen4
          gResPace.phase @?= Resolution

          -- Verify ActiveChallenge generated
          let mChal = case Map.lookup valId gResPace.actors >>= (.coreState.revealed) of
                Just (REChallenge ch) -> Just ch
                _ -> Nothing
          assertBool "Active challenge generated for travel pace" (isJust mChal)
          let Just ch = mChal
          ch.challengeStrength @?= 10
          let chalId = ch.id

          -- Vallhach defends against pace exertion
          let ((gDefended, _, _, _), gen6) =
                runState (processCommand (Defend valId chalId) gResPace) gen5
          let Just valDefending = Map.lookup valId gDefended.actors
          assertBool "Vallhach has active defense" (isJust valDefending.coreState.defending)

          -- Vallhach receives fatigue consequence from travel pace
          let ((gWithFatigue, _, _, _), gen7) =
                runState (processCommand (AddConsequence valId Nothing (Just chalId)) gDefended) gen6
          let Just valFatigued = Map.lookup valId gWithFatigue.actors
          assertBool
            "Fatigue status card added to discard"
            ( any
                (\(Identified _ (c :: CoreCard)) -> c.name == unsafeNonEmptyText "Fatigue")
                valFatigued.coreState.discard
            )

          -- Conclude pace: travel completes, party arrives at site_timber_cut, time advances by 45 min
          let ((gAfterPace, _, _, _), gen8) =
                runState (processCommand EndRound gWithFatigue) gen7
          gAfterPace.playMode @?= ModeExploration
          gAfterPace.phase @?= Planning

          case gAfterPace.worldState of
            Nothing -> assertBool "Missing worldState after pace" False
            Just ws -> do
              ws.focus @?= AtLocation (LocationId "site_timber_cut")
              ws.time @?= ExpeditionTime (480 + 45) -- 08:45 AM

          -- PC vigilance refilled to dial
          let Just valAfterPace = Map.lookup valId gAfterPace.actors
          length valAfterPace.coreState.vigilancePool @?= 2
          valAfterPace.coreState.hand @?= []

          -- 4. Move from site_timber_cut to loc_barricaded_portal (direct exit, 5 min)
          let ((gPlanPortal, _, _, _), gen9) =
                runState
                  ( processCommand
                      (PlanExplorationIntent valId (IntentTraverseExit (LocationId "loc_barricaded_portal")))
                      gAfterPace
                  )
                  gen8
          let ((gResPortal, _, _, _), gen10) =
                runState (processCommand StartResolution gPlanPortal) gen9
          let ((gAtPortal, _, _, _), gen11) =
                runState (processCommand EndRound gResPortal) gen10

          case gAtPortal.worldState of
            Nothing -> assertBool "Missing worldState at portal" False
            Just ws -> do
              ws.focus @?= AtLocation (LocationId "loc_barricaded_portal")
              ws.time @?= ExpeditionTime (480 + 45 + 5) -- 08:50 AM
              -- Exit to loc_sorting_yard is currently blocked
              let locSt = ws.locationStates Map.! LocationId "loc_barricaded_portal"
              Map.lookup (LocationId "loc_sorting_yard") locSt.exitStatuses @?= Just ExitBlocked

          -- 5. Clear barricade with Sledgehammer Breach (Action 0, Red 22, [Loud], unblocks loc_sorting_yard)
          let ((gPlanBreach, _, _, _), gen12) =
                runState (processCommand (PlanExplorationIntent valId (IntentAction 0)) gAtPortal) gen11
          let ((gResBreach, _, _, _), gen13) =
                runState (processCommand StartResolution gPlanBreach) gen12
          gResBreach.phase @?= Resolution

          -- End breach resolution: unblocks exit, advances 1 min, Loud triggers clock draw
          let ((gAfterBreach, _, _, _), gen14) =
                runState (processCommand EndRound gResBreach) gen13
          gAfterBreach.playMode @?= ModeExploration

          case gAfterBreach.worldState of
            Nothing -> assertBool "Missing worldState after breach" False
            Just ws -> do
              let locSt = ws.locationStates Map.! LocationId "loc_barricaded_portal"
              Map.lookup (LocationId "loc_sorting_yard") locSt.exitStatuses @?= Just ExitOpen
              ws.time @?= ExpeditionTime (480 + 45 + 5 + 1) -- 08:51 AM

          -- 6. Traverse unblocked exit into loc_sorting_yard -> triggers encounter -> transitions to ModeCrisis
          let ((gPlanYard, _, _, _), gen15) =
                runState
                  ( processCommand
                      (PlanExplorationIntent valId (IntentTraverseExit (LocationId "loc_sorting_yard")))
                      gAfterBreach
                  )
                  gen14
          let ((gResYard, _, _, _), gen16) =
                runState (processCommand StartResolution gPlanYard) gen15
          let ((gCrisis, _, _, _), _) =
                runState (processCommand EndRound gResYard) gen16

          -- Verify automatic transition to ModeCrisis
          gCrisis.playMode @?= ModeCrisis
          gCrisis.phase @?= Planning
          gCrisis.roundNumber @?= 1
          gCrisis.mapMode @?= Just MapModeRank

          -- Verify Vallhach hand has cards committed from vigilance
          let Just valCrisis = Map.lookup valId gCrisis.actors
          length valCrisis.coreState.hand @?= 2
          valCrisis.coreState.vigilancePool @?= []

          -- Verify goblins spawned and auto-planned (includes dynamic clock spawns)
          let hostiles = [a | a <- Map.elems gCrisis.actors, a.actorType /= "PC"]
          assertBool "Goblins spawned in crisis" (length hostiles >= 2)
          assertBool "Goblin lookout present" (any (\a -> a.name == "goblin_lookout") hostiles)
          assertBool "Goblin sentry present" (any (\a -> a.name == "goblin_sentry") hostiles)
          assertBool "Goblins auto-planned" (all (\a -> isJust a.coreState.planned) hostiles)
          assertBool "Goblins auto-planned" (all (\a -> isJust a.coreState.planned) hostiles)
    , testCase "GM Chronometer Controls: Manual Time Advance & Manual Clock Draw" $ do
        modPath <- resolvePath "data/modules/crag_gallows"
        (initGame, gen0) <- loadScenario modPath (Just 100)

        -- Advance time by 30 minutes
        let ((gAdvanced, _, _, _logsAdv), gen1) =
              runState (processCommand (AdvanceTimeManual (Duration 30 Minute)) initGame) gen0
        case gAdvanced.worldState of
          Nothing -> assertBool "Missing worldState" False
          Just ws -> ws.time @?= ExpeditionTime (480 + 30)

        -- Draw clock card manually
        let ((gClock, _, _, _logsClock), _) =
              runState (processCommand (DrawClockManual (ClockDeckId "wilderness_clock")) gAdvanced) gen1
        case gClock.worldState of
          Nothing -> assertBool "Missing worldState" False
          Just ws -> do
            let deck = ws.clockDecks Map.! ClockDeckId "wilderness_clock"
            length deck.discardPile @?= 1
    ]
