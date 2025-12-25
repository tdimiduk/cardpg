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
  , Identified (..)
  , CardInstance
  )
import CardPG.Core.Logic.Deck qualified as Deck
import CardPG.Core.Logic.Monad (GameM (..), runGameM)
import CardPG.Core.Logic.Planning
import CardPG.Core.Logic.Status
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
mkActorState :: [CardInstance CoreCard] -> ActorState
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
          , revealed = Nothing
          }
    , tableState = TableState Map.empty []
    , spatial = SpatialState 0 0 1 Nothing
    , plannedMove = Nothing
    }

mkConsTemplate :: Int -> ConsequenceCard
mkConsTemplate sev =
  ConsequenceCard
    { name = unsafeNonEmptyText "Cons"
    , tags = Nothing
    , passive = Nothing
    , effects = Nothing
    , severity = sev
    , notes = Nothing
    , rules = Nothing
    }

mkItemRes :: Int -> ItemCard
mkItemRes res =
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
      
      dummyCard = CoreCard (unsafeNonEmptyText "Dummy") Nothing (Stats 0 0 0) Nothing Nothing Nothing
      dummyActionCard = CoreCard (unsafeNonEmptyText "Dummy") Nothing (Stats 0 0 0) (Just 1) Nothing Nothing
      
      card1 = Identified c1 dummyActionCard
      card2 = Identified c2 dummyCard
      card3 = Identified c3 dummyCard
      
      planActionC1C2 = PStandard (ActionStack card1 [card2])
   in testGroup
        "Planned Actions Logic"
        [ testCase "plans an action successfully" $ do
            let initialState = mkActorState [card1, card2, card3]
            let ((), finalState, events) = runLogic initialState (planAction c1 [c2])

            -- Removed from hand
            finalState.coreState.hand @?= [card3]

            -- Added to planned
            let expectedPlan = planActionC1C2
            finalState.coreState.planned @?= Just expectedPlan

            -- Event emitted
            assertBool "ActionPlanned event missing" (ActionPlanned expectedPlan `elem` events)
        , testCase "cancels a planned action" $ do
            let initialState = mkActorState [card3]
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
            let expectedCanceledPlan = PStandard (ActionStack card1 [card2])
            assertBool "PlanCanceled missing" (PlanCanceled expectedCanceledPlan `elem` events)
        , testCase "discards planned actions" $ do
            let initialState = mkActorState [card3]
            let plannedState =
                  initialState
                    { coreState =
                        initialState.coreState
                          { planned = Just planActionC1C2
                          }
                    }

            let ((), finalState, _) = runLogic plannedState discardPlannedActions

            let d = finalState.coreState.discard
            assertBool "Expect c1 in discard" (card1 `elem` d)
            assertBool "Expect c2 in discard" (card2 `elem` d)
        ]

test_consequenceLogic :: TestTree
test_consequenceLogic =
  let cid1 = CardInstanceId (read "00000000-0000-0000-0000-000000000001")
      cid2 = CardInstanceId (read "00000000-0000-0000-0000-000000000002")
      cid3 = CardInstanceId (read "00000000-0000-0000-0000-000000000003")
      cidRes = CardInstanceId (read "00000000-0000-0000-0000-000000000009")
      
      cons1 = Identified cid1 (mkConsTemplate 0)
      cons2 = Identified cid2 (mkConsTemplate 0)
      cons3 = Identified cid3 (mkConsTemplate 0)
   in testGroup
        "Consequence Logic"
        [ testCase "adds specific severity consequence" $ do
            let env = mkEnv [mkConsTemplate 5]
            let state = mkActorState []
            let ((), finalState, events) = runLogicWithEnv env state (addConsequence (Just 5))

            length finalState.tableState.consequences @?= 1
            assertBool "ConsequenceAdded 5 missing" (any (\evt -> case evt of ConsequenceAdded c -> c.content.severity == 5; _ -> False) events)
        , testCase "calculates default resilience of 1 and proper severity" $ do
            -- No items, Res=1. existing=0. Sev = 0/1 + 1 = 1.
            let env = mkEnv [mkConsTemplate 1]
            let state = mkActorState []
            let ((), finalState, events) = runLogicWithEnv env state (addConsequence Nothing)

            assertBool "ConsequenceAdded 1 missing" (any (\evt -> case evt of ConsequenceAdded c -> c.content.severity == 1; _ -> False) events)
        , testCase "uses equipped resilience" $ do
            -- Item with Res=3. Existing=0. Sev = 0/3 + 1 = 1.
            let item = mkItemRes 3
            let tc = TCItem item
            let state0 = mkActorState []
            let state =
                  state0
                    { tableState =
                        state0.tableState
                          { assets = Map.singleton cidRes (Identified cidRes tc, Equipped SlotBody)
                          }
                    }
            let env = mkEnv [mkConsTemplate 1]
            let ((), finalState, events) = runLogicWithEnv env state (addConsequence Nothing)

            assertBool "ConsequenceAdded 1 missing" (any (\evt -> case evt of ConsequenceAdded c -> c.content.severity == 1; _ -> False) events)
        , testCase "calculates severity based on existing count and resilience" $ do
            -- Res=2. Existing=3 consequences. Sev = 3/2 + 1 = 1 + 1 = 2.
            let item = mkItemRes 2
            let tc = TCItem item

            let state0 = mkActorState []
            let state =
                  state0
                    { tableState =
                        state0.tableState

                          { assets = Map.singleton cidRes (Identified cidRes tc, Equipped SlotBody)
                          , consequences = [cons1, cons2, cons3] -- 3 dummy existing
                          }
                    }
            let env = mkEnv [mkConsTemplate 2]
            let ((), finalState, events) = runLogicWithEnv env state (addConsequence Nothing)

            assertBool "ConsequenceAdded 2 missing" (any (\evt -> case evt of ConsequenceAdded c -> c.content.severity == 2; _ -> False) events)
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
    , testCase "removes status from registry (regression test)" $ do
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
        let state0 = mkActorState []

        -- 1. Add Status
        let ((), state1, _) = runLogicWithEnv env state0 (addStatus statusName LocationHand)
        let handCardId = head state1.coreState.hand

        -- 2. Remove Status
        let ((), state2, _) = runLogicWithEnv env state1 (destroyStatus statusName (Just handCardId.id))

        -- 3. Verify
        -- The registry size should decrease by 1
        length state2.coreState.hand @?= 0
    ]
