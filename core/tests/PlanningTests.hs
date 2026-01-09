{-# LANGUAGE OverloadedStrings #-}

module PlanningTests where

import Test.Tasty
import Test.Tasty.HUnit

import Core.Card (CardInstance, CoreCard (..), Identified (..))
import Core.Logic.Planning
import Core.NonEmptyText (unsafeNonEmptyText)
import Core.Primitives (CardInstanceId (..))
import Core.State (ActionStack (..), NarrativeStack (..), PlannedAction (..))
import Core.Stats (ResourceType (..), Stats (..))

import Data.List.NonEmpty (NonEmpty (..))

test_planningLogic :: TestTree
test_planningLogic =
  testGroup
    "Planning Logic"
    [ testCase "Standard Plan - Valid" test_standardValid
    , testCase "Standard Plan - Incomplete (Underpaid)" test_standardIncomplete
    , testCase "Standard Plan - Incomplete (Overpaid)" test_standardOverpaid
    , testCase "Narrative Plan - Valid" test_narrativeValid
    , testCase "Narrative Plan - Invalid (Empty)" test_narrativeInvalid
    ]

-- Helpers
dummyId :: Int -> CardInstanceId
dummyId i = CardInstanceId $ read $ "00000000-0000-0000-0000-0000000000" <> showOne i
  where
    showOne x = if x < 10 then "0" <> show x else show x

mkCard :: Int -> Int -> CardInstance CoreCard
mkCard i costVal =
  Identified
    (dummyId i)
    CoreCard
      { name = unsafeNonEmptyText "Test Card"
      , tags = Nothing
      , stats = Stats 0 0 0
      , cost = Just costVal
      , rules = Nothing
      , flavor = Nothing
      }

-- Tests

test_standardValid :: Assertion
test_standardValid = do
  let actionCard = mkCard 1 2 -- Cost 2
      r1 = mkCard 2 0
      r2 = mkCard 3 0
      result = validateStandardPlan actionCard [r1, r2]

  case result of
    PlanValid (PStandard (ActionStack ac res)) -> do
      assertEqual "Action card matches" (dummyId 1) ac.id
      assertEqual "Resources count matches" 2 (length res)
    _ -> assertFailure $ "Expected PlanValid, got " <> show result

test_standardIncomplete :: Assertion
test_standardIncomplete = do
  let actionCard = mkCard 1 2 -- Cost 2
      r1 = mkCard 2 0
      result = validateStandardPlan actionCard [r1] -- Only 1 provided
  case result of
    PlanIncomplete need have -> do
      assertEqual "Needed" 2 need
      assertEqual "Have" 1 have
    _ -> assertFailure $ "Expected PlanIncomplete, got " <> show result

test_standardOverpaid :: Assertion
test_standardOverpaid = do
  let actionCard = mkCard 1 1 -- Cost 1
      r1 = mkCard 2 0
      r2 = mkCard 3 0
      result = validateStandardPlan actionCard [r1, r2] -- 2 provided

  -- Currently implementation requires exact match
  case result of
    PlanIncomplete need have -> do
      assertEqual "Needed" 1 need
      assertEqual "Have" 2 have
    _ -> assertFailure $ "Expected PlanIncomplete (Overpaid), got " <> show result

test_narrativeValid :: Assertion
test_narrativeValid = do
  let c1 = mkCard 1 0
      result = validateNarrativePlan [c1] Red

  case result of
    PlanValid (PNarrative (NarrativeStack ne col)) -> do
      assertEqual "Correct color" Red col
      assertEqual "Correct card count" 1 (length ne)
    _ -> assertFailure $ "Expected PlanValid, got " <> show result

test_narrativeInvalid :: Assertion
test_narrativeInvalid = do
  let result = validateNarrativePlan [] Red
  case result of
    PlanInvalid msg -> assertEqual "Error message" "no cards selected" msg
    _ -> assertFailure $ "Expected PlanInvalid, got " <> show result
