{-# LANGUAGE DuplicateRecordFields #-}
{-# LANGUAGE OverloadedRecordDot #-}
{-# LANGUAGE OverloadedStrings #-}

module ModeTransitionTest (test_mode_transition) where

import Control.Monad.State (runState)
import Data.Map.Strict qualified as Map
import Data.Maybe (isJust)
import System.Directory (doesDirectoryExist, doesFileExist)
import System.FilePath ((</>))
import Test.Tasty (TestTree, testGroup)
import Test.Tasty.HUnit (assertBool, testCase, (@?=))

import Api.Request (ApiRequest (..))
import Api.Types (Phase (..), PlayMode (..))
import Core.Card.Exploration (LocationId (..))
import Core.State
  ( ActionStack (..)
  , ActorState (..)
  , BattleRank (..)
  , CoreCardState (..)
  , ExplorationFocus (..)
  , MapMode (..)
  , PlannedAction (..)
  , SpatialState (..)
  , WorldState (..)
  )
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

test_mode_transition :: TestTree
test_mode_transition =
  testGroup
    "Mode Transitions (Exploration <-> Crisis)"
    [ testCase
        "Transition to Crisis: moves Vigilance pool to hand, spawns encounter actors, sets MapModeRank"
        $ do
          modPath <- resolvePath "data/modules/crag_gallows"
          (initGame, gen0) <- loadScenario modPath (Just 42)

          initGame.playMode @?= ModeExploration
          Map.size initGame.actors @?= 1
          let (valId, vallhach) = head (Map.toList initGame.actors)
          vallhach.coreState.hand @?= []
          vallhach.coreState.vigilanceDial @?= 2
          length vallhach.coreState.vigilancePool @?= 2

          case initGame.worldState of
            Nothing -> assertBool "Missing worldState" False
            Just wsInit -> do
              assertBool "Has goblin_lookout template" (Map.member "goblin_lookout" wsInit.actorTemplates)
              assertBool "Has goblin_sentry template" (Map.member "goblin_sentry" wsInit.actorTemplates)

          -- Move party focus to loc_sorting_yard where an encounter is waiting
          let gameAtYard = case initGame.worldState of
                Just ws -> initGame{worldState = Just (ws{focus = AtLocation (LocationId "loc_sorting_yard")})}
                Nothing -> error "Missing worldState"

          -- Transition to Crisis mode
          let ((crisisGame, updatesRes, events, logs), gen1) =
                runState (processCommand (TransitionMode ModeCrisis) gameAtYard) gen0

          crisisGame.playMode @?= ModeCrisis
          crisisGame.phase @?= Planning
          crisisGame.roundNumber @?= 1
          crisisGame.mapMode @?= Just MapModeRank

          -- Check Vallhach: vigilance pool moved into hand
          case Map.lookup valId crisisGame.actors of
            Nothing -> assertBool "Vallhach missing in crisis game" False
            Just vCrisis -> do
              length vCrisis.coreState.hand @?= 2
              vCrisis.coreState.vigilancePool @?= []
              vCrisis.spatial.rank @?= Just FrontRank

          -- Check spawned goblins: goblin_lookout and goblin_sentry
          Map.size crisisGame.actors @?= 3
          let hostiles = [a | a <- Map.elems crisisGame.actors, a.actorType /= "PC"]
          length hostiles @?= 2
          let lookout = [a | a <- hostiles, a.name == "goblin_lookout"]
          let sentry = [a | a <- hostiles, a.name == "goblin_sentry"]
          length lookout @?= 1
          length sentry @?= 1

          -- Goblins committed their initial hand (3 cards) into their auto-planned action
          case lookout of
            [l] -> do
              assertBool "Lookout auto-planned" (isJust l.coreState.planned)
              case l.coreState.planned of
                Just (PStandard (ActionStack _ res)) -> (1 + length res) @?= 3
                _ -> assertBool "Expected PStandard action" False
              l.spatial.rank @?= Just FrontRank
            _ -> assertBool "Lookout missing" False

          case sentry of
            [s] -> do
              assertBool "Sentry auto-planned" (isJust s.coreState.planned)
              case s.coreState.planned of
                Just (PStandard (ActionStack _ res)) -> (1 + length res) @?= 3
                _ -> assertBool "Expected PStandard action" False
              s.spatial.rank @?= Just FrontRank
            _ -> assertBool "Sentry missing" False

          -- Location encounter cleared from worldState to prevent duplicate spawning
          case crisisGame.worldState of
            Nothing -> assertBool "Missing worldState after transition" False
            Just wsFinal ->
              Map.member (LocationId "loc_sorting_yard") wsFinal.locationEncounters @?= False
    , testCase "Transition to Exploration: discards PC hands, refills Vigilance, clears hostiles" $ do
        modPath <- resolvePath "data/modules/crag_gallows"
        (initGame, gen0) <- loadScenario modPath (Just 42)

        -- Transition to Crisis at sorting yard
        let gameAtYard = case initGame.worldState of
              Just ws -> initGame{worldState = Just (ws{focus = AtLocation (LocationId "loc_sorting_yard")})}
              Nothing -> error "Missing worldState"

        let ((crisisGame, _, _, _), gen1) =
              runState (processCommand (TransitionMode ModeCrisis) gameAtYard) gen0
        crisisGame.playMode @?= ModeCrisis
        Map.size crisisGame.actors @?= 3

        -- Now manually transition back to Exploration mode
        let ((expGame, updatesRes, events, logs), gen2) =
              runState (processCommand (TransitionMode ModeExploration) crisisGame) gen1

        expGame.playMode @?= ModeExploration
        expGame.phase @?= Planning
        expGame.mapMode @?= Nothing

        -- Hostiles removed, only Vallhach remains
        Map.size expGame.actors @?= 1
        case Map.elems expGame.actors of
          [vallhach] -> do
            vallhach.coreState.hand @?= []
            vallhach.coreState.vigilanceDial @?= 2
            length vallhach.coreState.vigilancePool @?= 2
          _ -> assertBool "Expected exactly 1 PC remaining" False
    , testCase "Auto-transition to Exploration when all hostile NPCs are defeated" $ do
        modPath <- resolvePath "data/modules/crag_gallows"
        (initGame, gen0) <- loadScenario modPath (Just 42)

        -- Transition to crisis at sorting yard
        let gameAtYard = case initGame.worldState of
              Just ws -> initGame{worldState = Just (ws{focus = AtLocation (LocationId "loc_sorting_yard")})}
              Nothing -> error "Missing worldState"

        let ((crisisGame, _, _, _), gen1) =
              runState (processCommand (TransitionMode ModeCrisis) gameAtYard) gen0

        let hostileIds = [aid | (aid, a) <- Map.toList crisisGame.actors, a.actorType /= "PC"]
        length hostileIds @?= 2

        -- Defeat the first hostile with severity 3 consequence
        let ((gameAfterDefeat1, _, _, _), gen2) =
              runState (processCommand (AddConsequence (head hostileIds) (Just 3) Nothing) crisisGame) gen1
        -- First hostile defeated, but second is still alive -> still in crisis mode
        gameAfterDefeat1.playMode @?= ModeCrisis

        -- Defeat the second hostile with severity 3 consequence
        let ((gameAfterDefeat2, _, _, _), gen3) =
              runState (processCommand (AddConsequence (last hostileIds) (Just 3) Nothing) gameAfterDefeat1) gen2

        -- All hostiles defeated -> automatically transitions to ModeExploration!
        gameAfterDefeat2.playMode @?= ModeExploration
        gameAfterDefeat2.mapMode @?= Nothing
        Map.size gameAfterDefeat2.actors @?= 1
        case Map.elems gameAfterDefeat2.actors of
          [pc] -> do
            pc.coreState.hand @?= []
            length pc.coreState.vigilancePool @?= 2
          _ -> assertBool "Expected only PC remaining" False
    ]
