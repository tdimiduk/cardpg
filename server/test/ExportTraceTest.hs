{-# LANGUAGE OverloadedStrings #-}

module ExportTraceTest (test_export_trace) where

import Data.Aeson (toJSON)
import Data.List.NonEmpty (NonEmpty (..))
import Data.Map.Strict qualified as Map
import Data.Text (Text)
import Data.Text qualified as T
import Data.Time (UTCTime (..), fromGregorian)
import Data.UUID (UUID)
import Data.UUID qualified as UUID
import Data.Word (Word32)
import Database.Beam.Postgres (PgJSONB (..))
import Test.Tasty (TestTree, testGroup)
import Test.Tasty.HUnit (assertBool, testCase, (@?=))

import Api.Types (ActorGameEvent (..))
import Core.Card (AttackDef (..), ConsequenceCard (..), CoreCard (..), Identified (..), Stats (..))
import Core.DSL (parseText)
import Core.NonEmptyText (unsafeNonEmptyText)
import Core.Primitives (CardInstanceId (..), ChallengeId (..))
import Core.Rules (Rule)
import Core.State
  ( ActionStack (..)
  , ActiveChallenge (..)
  , ChallengeSource (..)
  , GameEnv (..)
  , GameEvent (..)
  , PlannedAction (..)
  , RevealedEffect (..)
  )
import Core.Stats (ResourceType (..), StackPower (..))
import Server.DB
  ( SqlSerial (..)
  , initInMemoryDB
  , saveGame
  , saveGameEvents
  )
import Server.DB.Schema (GameEventRecordT (..), GameT (..))
import Server.ExportTrace
  ( generateTrace
  , getEventCounts
  )
import Server.Game (emptyGame)

testTime :: UTCTime
testTime = UTCTime (fromGregorian 2026 10 3) 0

mkId :: Word32 -> UUID
mkId = UUID.fromWords 0 0 0

mkCoreCard :: Text -> Stats Int -> CoreCard
mkCoreCard cardName cardStats =
  CoreCard
    { name = unsafeNonEmptyText cardName
    , cost = Just 1
    , tags = Nothing
    , stats = cardStats
    , attack =
        Just $
          AttackDef
            { power = StackPower Red 4 Nothing
            , resistedBy = Red
            , effect = Nothing
            }
    , rules = Nothing
    , flavor = Nothing
    }

mkConsequence :: Text -> Int -> Maybe Text -> ConsequenceCard
mkConsequence consName sev pass =
  let parsedRule = case parseText "Task: First Aid (Check {Blue} 3) → Remove this" of
        Right (r :: Rule) -> Just (r :| [])
        Left _ -> Nothing
   in ConsequenceCard
        { name = unsafeNonEmptyText consName
        , tags = Just ("Combat" :| ["Condition"])
        , passive = pass
        , effects = Nothing
        , severity = sev
        , notes = Nothing
        , rules = parsedRule
        }

test_export_trace :: TestTree
test_export_trace =
  testGroup
    "Trace Exporter & Target Inference"
    [ testCase "Filter noise: ignores PlanCanceled and retains authoritative ActionRevealed" $ do
        let wolfId = UUID.toText (mkId 1)
            vallhachId = UUID.toText (mkId 2)
            wolfCard = Identified (CardInstanceId (mkId 10)) (mkCoreCard "Bite" (Stats 4 2 2))
            wolfPlan = PStandard (ActionStack wolfCard [])
            wolfChal = ActiveChallenge (ChallengeId (mkId 100)) (CSCard (CardInstanceId (mkId 10))) 18 Red

            events =
              [ GameEventRecord
                  (SqlSerial 1)
                  "game-1"
                  1
                  testTime
                  (Just wolfId)
                  "ActionPlanned"
                  (PgJSONB (toJSON (ActionPlanned wolfPlan)))
              , GameEventRecord
                  (SqlSerial 2)
                  "game-1"
                  1
                  testTime
                  (Just wolfId)
                  "PlanCanceled"
                  (PgJSONB (toJSON (PlanCanceled wolfPlan)))
              , GameEventRecord
                  (SqlSerial 3)
                  "game-1"
                  1
                  testTime
                  (Just wolfId)
                  "ActionRevealed"
                  (PgJSONB (toJSON (ActionRevealed wolfPlan (REChallenge wolfChal))))
              , GameEventRecord
                  (SqlSerial 4)
                  "game-1"
                  1
                  testTime
                  (Just vallhachId)
                  "ActionRevealed"
                  (PgJSONB (toJSON (ActionRevealed PPass REPass)))
              ]

            gameRec =
              Game
                { gameId = "game-1"
                , scenarioName = "starter"
                , gameStatus = "Active"
                , actorNames = PgJSONB ["Wolf", "Vallhach"]
                , currentRound = 1
                , gameState = PgJSONB (toJSON ())
                , gameStartedAt = testTime
                , gameUpdatedAt = testTime
                }

            trace = generateTrace gameRec Nothing events

        assertBool "Trace contains Wolf's final attack" (T.isInfixOf "Red Strength = 18" trace)
        assertBool "Trace contains Vallhach's passed declaration" (T.isInfixOf "Passed" trace)
        assertBool "Trace contains Action Card: `Bite`" (T.isInfixOf "Action Card: `Bite`" trace)
    , testCase "Target inference & Defense Flips: calculates cumulative defense values" $ do
        let wolfId = UUID.toText (mkId 1)
            vallhachId = UUID.toText (mkId 2)
            wolfCard = Identified (CardInstanceId (mkId 10)) (mkCoreCard "Bite" (Stats 4 2 2))
            wolfPlan = PStandard (ActionStack wolfCard [])
            wolfChal = ActiveChallenge (ChallengeId (mkId 100)) (CSCard (CardInstanceId (mkId 10))) 18 Red
            defCard1 = Identified (CardInstanceId (mkId 20)) (mkCoreCard "Overheated" (Stats 5 2 2))
            defCard2 = Identified (CardInstanceId (mkId 21)) (mkCoreCard "Fireball" (Stats 3 1 4))
            consCard =
              Identified
                (CardInstanceId (mkId 30))
                (mkConsequence "Rattled Guard" 1 (Just "Impact of Defense +1"))

            events =
              [ GameEventRecord
                  (SqlSerial 1)
                  "game-1"
                  1
                  testTime
                  (Just wolfId)
                  "ActionRevealed"
                  (PgJSONB (toJSON (ActionRevealed wolfPlan (REChallenge wolfChal))))
              , GameEventRecord
                  (SqlSerial 2)
                  "game-1"
                  1
                  testTime
                  (Just vallhachId)
                  "ActionRevealed"
                  (PgJSONB (toJSON (ActionRevealed PPass REPass)))
              , GameEventRecord
                  (SqlSerial 3)
                  "game-1"
                  1
                  testTime
                  (Just vallhachId)
                  "CardDefended"
                  (PgJSONB (toJSON (CardDefended wolfChal defCard1)))
              , GameEventRecord
                  (SqlSerial 4)
                  "game-1"
                  1
                  testTime
                  (Just vallhachId)
                  "CardDefended"
                  (PgJSONB (toJSON (CardDefended wolfChal defCard2)))
              , GameEventRecord
                  (SqlSerial 5)
                  "game-1"
                  1
                  testTime
                  (Just vallhachId)
                  "ConsequenceAdded"
                  (PgJSONB (toJSON (ConsequenceAdded consCard)))
              ]

            gameRec =
              Game
                { gameId = "game-1"
                , scenarioName = "starter"
                , gameStatus = "Active"
                , actorNames = PgJSONB ["Wolf", "Vallhach"]
                , currentRound = 1
                , gameState = PgJSONB (toJSON ())
                , gameStartedAt = testTime
                , gameUpdatedAt = testTime
                }

            trace = generateTrace gameRec Nothing events

        assertBool
          "Contains Flip 1 with cumulative 5"
          (T.isInfixOf "Flip 1: `Overheated` ({Red: 5}) -> Cumulative: 5" trace)
        assertBool
          "Contains Flip 2 with cumulative 8"
          (T.isInfixOf "Flip 2: `Fireball` ({Red: 3}) -> Cumulative: 8" trace)
        assertBool "Contains Total Flipped Cards" (T.isInfixOf "Total Flipped Cards**: 2 cards." trace)
        assertBool "Contains Impact Generated" (T.isInfixOf "Impact Generated**: **2 Impact**." trace)
        assertBool "Contains Consequence name and tier" (T.isInfixOf "**`Rattled Guard`** (Tier 1" trace)
        assertBool "Contains Consequence passive" (T.isInfixOf "_Passive_: Impact of Defense +1" trace)
    , testCase "1v1 Target Inference: Infers other combatant when no defense flips yet" $ do
        let wolfId = UUID.toText (mkId 1)
            wolfCard = Identified (CardInstanceId (mkId 10)) (mkCoreCard "Bite" (Stats 4 2 2))
            wolfPlan = PStandard (ActionStack wolfCard [])
            wolfChal = ActiveChallenge (ChallengeId (mkId 100)) (CSCard (CardInstanceId (mkId 10))) 10 Red

            events =
              [ GameEventRecord
                  (SqlSerial 1)
                  "game-2"
                  1
                  testTime
                  (Just wolfId)
                  "ActionRevealed"
                  (PgJSONB (toJSON (ActionRevealed wolfPlan (REChallenge wolfChal))))
              ]

            gameRec =
              Game
                { gameId = "game-2"
                , scenarioName = "starter"
                , gameStatus = "Active"
                , actorNames = PgJSONB ["Wolf", "Vallhach"]
                , currentRound = 1
                , gameState = PgJSONB (toJSON ())
                , gameStartedAt = testTime
                , gameUpdatedAt = testTime
                }

            trace = generateTrace gameRec Nothing events

        assertBool
          "Pending resolution shown when no flips occurred"
          (T.isInfixOf "Pending resolution" trace)
    , testCase "In-Memory Event Counts" $ do
        backend <- initInMemoryDB
        let env = GameEnv (mkCoreCard "fatigue" (Stats 0 0 0)) Map.empty Map.empty
            gs = emptyGame env
        saveGame backend "game-mem" "starter" gs
        let dummyEvt = ActorGameEvent Nothing (RoundStarted 1)
        saveGameEvents backend "game-mem" 1 [dummyEvt, dummyEvt] []
        counts <- getEventCounts backend
        Map.lookup "game-mem" counts @?= Just 2
    ]
