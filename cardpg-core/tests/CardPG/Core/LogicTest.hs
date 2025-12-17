module CardPG.Core.LogicTest where

import Control.Monad.RWS (runRWST)
import Control.Monad.State (evalState, runState)
import Data.List (sort)
import Data.Map.Strict qualified as Map
import System.Random (StdGen, mkStdGen)
import Test.Tasty (TestTree, testGroup)
import Test.Tasty.HUnit (assertBool, testCase, (@?=))

import CardPG.Core.Card
  ( ConsequenceCard
  , ConsequenceCardT (..)
  , CoreCard
  , CoreCardT (..)
  , ItemCard
  , ItemCardT (..)
  , NatureCard
  , Stats (..)
  , TalentCard
  )
import CardPG.Core.Logic
import CardPG.Core.NonEmptyText (unsafeNonEmptyText)
import CardPG.Core.Primitives
  ( CardInstanceId (..)
  , CardLocation (..)
  , EquipSlot (..)
  , TargetId (..)
  )
import CardPG.Core.State
import Data.Text qualified as T

-- Helper to create a dummy game logic execution
runLogic :: ActorState -> GameM StdGen a -> (a, ActorState, [GameEvent])
runLogic initialState action =
  let env = GameEnv{fatigueCardTemplate = undefined} -- Mock env if needed
      rng = mkStdGen 0
      ((res, finalState, events), _) = runState (runRWST (runGameM action) env initialState) rng
   in (res, finalState, events)

-- Helper to create a dummy actor state
mkActorState :: [CardInstanceId] -> ActorState
mkActorState handCards =
  ActorState
    { name = "TestActor"
    , actorType = "Player"
    , coreState =
        CoreCardState
          { deck = []
          , hand = handCards
          , discard = []
          , planned = Nothing
          , defending = []
          , inPlay = Map.empty
          , registry =
              Map.fromList
                [ (cid, CoreCard (unsafeNonEmptyText "Dummy") Nothing (Stats 0 0 0) (Just 1) Nothing Nothing)
                | cid <- handCards
                , cid == CardInstanceId (read "00000000-0000-0000-0000-000000000001")
                ]
                `Map.union` Map.fromList
                  [ (cid, CoreCard (unsafeNonEmptyText "Dummy") Nothing (Stats 0 0 0) Nothing Nothing Nothing)
                  | cid <- handCards
                  , cid /= CardInstanceId (read "00000000-0000-0000-0000-000000000001")
                  ]
          }
    , tableState = TableState Map.empty Map.empty [] Map.empty
    , spatial = SpatialState 0 0 1 Nothing
    , plannedMove = Nothing
    }

mockConsTemplate :: Int -> ConsequenceCard
mockConsTemplate sev =
  ConsequenceCard
    { name = unsafeNonEmptyText "Cons"
    , tags = Nothing
    , passive = Nothing
    , effects = Nothing
    , severity = sev
    , notes = Nothing
    , rules = Nothing
    }

mockItemRes :: Int -> ItemCard
mockItemRes res =
  ItemCard
    { name = unsafeNonEmptyText "Armor"
    , tags = Nothing
    , flavor = Nothing
    , weight = Nothing
    , value = Nothing
    , traits = Nothing
    , passive = Nothing
    , defense = Nothing
    , resilience = Just res
    , burden = Nothing
    }

mkEnv :: [ConsequenceCard] -> GameEnv
mkEnv consList =
  GameEnv
    { fatigueCardTemplate = undefined
    , statusCardTemplates = Map.empty
    , consequenceCardTemplates = Map.fromList [(T.pack (show c.severity), c) | c <- consList]
    }

runLogicWithEnv :: GameEnv -> ActorState -> GameM StdGen a -> (a, ActorState, [GameEvent])
runLogicWithEnv env state action =
  let rng = mkStdGen 0
      ((res, finalState, events), _) = runState (runRWST (runGameM action) env state) rng
   in (res, finalState, events)

test_logic :: TestTree
test_logic =
  testGroup
    "Logic Tests"
    [ test_plannedActions
    , test_consequenceLogic
    , test_statusLogic
    ]

test_plannedActions :: TestTree
test_plannedActions =
  let c1 = CardInstanceId (read "00000000-0000-0000-0000-000000000001")
      c2 = CardInstanceId (read "00000000-0000-0000-0000-000000000002")
      c3 = CardInstanceId (read "00000000-0000-0000-0000-000000000003")
      planActionC1C2 = PStandard (ActionStack c1 [c2])
   in testGroup
        "Planned Actions Logic"
        [ testCase "plans an action successfully" $ do
            let initialState = mkActorState [c1, c2, c3]
            let ((), finalState, events) = runLogic initialState (planAction c1 [c2])

            -- Removed from hand
            finalState.coreState.hand @?= [c3]

            -- Added to planned
            let expectedPlan = planActionC1C2
            finalState.coreState.planned @?= Just expectedPlan

            -- Event emitted
            assertBool "ActionPlanned event missing" (ActionPlanned expectedPlan `elem` events)
        , testCase "cancels a planned action" $ do
            let initialState = mkActorState [c3]
            let plannedState =
                  initialState
                    { coreState =
                        initialState.coreState
                          { planned = Just planActionC1C2
                          }
                    }

            let ((), finalState, events) = runLogic plannedState cancelPlan

            -- Returned to hand (order might vary depending on implementation, usually prepended)
            length finalState.coreState.hand @?= 3
            finalState.coreState.planned @?= Nothing

            -- We know the plan that was canceled is PStandard (ActionStack c1 [c2])
            -- because that's what we put in plannedState
            let expectedCanceledPlan = PStandard (ActionStack c1 [c2])
            assertBool "PlanCanceled missing" (PlanCanceled expectedCanceledPlan `elem` events)
        , testCase "discards planned actions" $ do
            let initialState = mkActorState [c3]
            let plannedState =
                  initialState
                    { coreState =
                        initialState.coreState
                          { planned = Just planActionC1C2
                          }
                    }

            let ((), finalState, events) = runLogic plannedState discardPlannedActions

            let d = finalState.coreState.discard
            assertBool "Expect c1 in discard" (c1 `elem` d)
            assertBool "Expect c2 in discard" (c2 `elem` d)
        ]

test_consequenceLogic :: TestTree
test_consequenceLogic =
  let cid1 = CardInstanceId (read "00000000-0000-0000-0000-000000000001")
      cid2 = CardInstanceId (read "00000000-0000-0000-0000-000000000002")
      cid3 = CardInstanceId (read "00000000-0000-0000-0000-000000000003")
      cidRes = CardInstanceId (read "00000000-0000-0000-0000-000000000009")
   in testGroup
        "Consequence Logic"
        [ testCase "adds specific severity consequence" $ do
            let env = mkEnv [mockConsTemplate 5]
            let state = mkActorState []
            let ((), finalState, events) = runLogicWithEnv env state (addConsequence (Just 5))

            length finalState.tableState.consequences @?= 1
            assertBool "ConsequenceAdded 5 missing" (ConsequenceAdded 5 `elem` events)
        , testCase "calculates default resilience of 1 and proper severity" $ do
            -- No items, Res=1. existing=0. Sev = 0/1 + 1 = 1.
            let env = mkEnv [mockConsTemplate 1]
            let state = mkActorState []
            let ((), finalState, events) = runLogicWithEnv env state (addConsequence Nothing)

            assertBool "ConsequenceAdded 1 missing" (ConsequenceAdded 1 `elem` events)
        , testCase "uses equipped resilience" $ do
            -- Item with Res=3. Existing=0. Sev = 0/3 + 1 = 1.
            let item = mockItemRes 3
            let tc = TCItem item
            let state0 = mkActorState []
            let state =
                  state0
                    { tableState =
                        state0.tableState
                          { registry = Map.singleton cidRes tc
                          , assets = Map.singleton cidRes (Equipped SlotBody)
                          }
                    }
            let env = mkEnv [mockConsTemplate 1]
            let ((), finalState, events) = runLogicWithEnv env state (addConsequence Nothing)

            assertBool "ConsequenceAdded 1 missing" (ConsequenceAdded 1 `elem` events)
        , testCase "calculates severity based on existing count and resilience" $ do
            -- Res=2. Existing=3 consequences. Sev = 3/2 + 1 = 1 + 1 = 2.
            let item = mockItemRes 2
            let tc = TCItem item

            let state0 = mkActorState []
            let state =
                  state0
                    { tableState =
                        state0.tableState
                          { registry = Map.singleton cidRes tc
                          , assets = Map.singleton cidRes (Equipped SlotBody)
                          , consequences = [cid1, cid2, cid3] -- 3 dummy existing
                          }
                    }
            let env = mkEnv [mockConsTemplate 2]
            let ((), finalState, events) = runLogicWithEnv env state (addConsequence Nothing)

            assertBool "ConsequenceAdded 2 missing" (ConsequenceAdded 2 `elem` events)
        ]

test_statusLogic :: TestTree
test_statusLogic =
  testGroup
    "Status Logic"
    [ testCase "adds status to hand" $ do
        let statusName = "Stunned"
        let env =
              GameEnv
                { fatigueCardTemplate = undefined
                , statusCardTemplates =
                    Map.singleton
                      statusName
                      (CoreCard (unsafeNonEmptyText "Stunned") Nothing (Stats 0 0 0) Nothing Nothing Nothing)
                , consequenceCardTemplates = Map.empty
                }
        let state = mkActorState []
        let ((), finalState, events) = runLogicWithEnv env state (addStatus statusName LocationHand)

        length finalState.coreState.hand @?= 1
        assertBool "StatusAdded missing" (StatusAdded statusName LocationHand `elem` events)
    ]
