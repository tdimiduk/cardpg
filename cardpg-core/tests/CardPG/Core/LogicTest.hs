module CardPG.Core.LogicTest where

import Control.Monad.RWS (runRWST)
import Control.Monad.State (evalState)
import Data.List (sort)
import qualified Data.Map.Strict as Map
import System.Random (mkStdGen)
import Test.Hspec

import qualified Data.Text as T
import CardPG.Core.Card (ConsequenceCard, ConsequenceCardT(..), CoreCard (..), ItemCard, ItemCardT (..), NatureCard, TalentCard)
import CardPG.Core.Logic
import CardPG.Core.Primitives (CardInstanceId (..), TargetId (..), EquipSlot (..))
import CardPG.Core.NonEmptyText (unsafeNonEmptyText)
import CardPG.Core.State

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
          , registry = Map.empty
          }
    , tableState = TableState Map.empty Map.empty
    , spatial = SpatialState 0 0 1 Nothing
    , plannedMove = Nothing
    }

spec :: Spec
spec = do
  describe "Planned Actions Logic" $ do
    let c1 = CardInstanceId (read "00000000-0000-0000-0000-000000000001")
    let c2 = CardInstanceId (read "00000000-0000-0000-0000-000000000002")
    let c3 = CardInstanceId (read "00000000-0000-0000-0000-000000000003")

    it "plans an action successfully" $ do
      let initialState = mkActorState [c1, c2, c3]
      let ((), finalState, events) = runLogic initialState (planAction c1 [c2])

      -- Removed from hand
      (hand $ coreState finalState) `shouldBe` [c3]

      -- Added to planned
      let expectedPlan = PlannedAction c1 [c2]
      (planned $ coreState finalState) `shouldBe` Just expectedPlan

      -- Event emitted
      events `shouldContain` [ActionPlanned expectedPlan]

    it "cancels a planned action" $ do
      let initialState = mkActorState [c3]
      let plannedState =
            initialState
              { coreState =
                  (coreState initialState)
                    { planned = Just (PlannedAction c1 [c2])
                    }
              }

      let ((), finalState, events) = runLogic plannedState cancelPlan

      -- Returned to hand (order might vary depending on implementation, usually prepended)
      length (hand $ coreState finalState) `shouldBe` 3
      (planned $ coreState finalState) `shouldBe` Nothing

      events `shouldContain` [PlanCanceled]

    it "discards planned actions" $ do
      let initialState = mkActorState [c3]
      let plannedState =
            initialState
              { coreState =
                  (coreState initialState)
                    { planned = Just (PlannedAction c1 [c2])
                    }
              }

      let ((), finalState, events) = runLogic plannedState discardPlannedActions

      (discard $ coreState finalState) `shouldContain` [c1, c2]

  describe "Consequence Logic" $ do
    let cid1 = CardInstanceId (read "00000000-0000-0000-0000-000000000001")
    let cid2 = CardInstanceId (read "00000000-0000-0000-0000-000000000002")
    let cid3 = CardInstanceId (read "00000000-0000-0000-0000-000000000003")
    let cidRes = CardInstanceId (read "00000000-0000-0000-0000-000000000009")

    let mockConsTemplate sev =
          ConsequenceCard
            { name = unsafeNonEmptyText "Cons"
            , tags = Nothing
            , passive = Nothing
            , effects = Nothing
            , severity = sev
            , notes = Nothing
            , rules = Nothing
            }

    let mockItemRes res =
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

    let mkEnv consList =
          GameEnv
            { fatigueCardTemplate = undefined
            , statusCardTemplates = Map.empty
            , consequenceCardTemplates = Map.fromList [(T.pack (show c.severity), c) | c <- consList]
            }

    let runLogicWithEnv env state action =
          let rng = mkStdGen 0
              ((res, finalState, events), _) = runState (runRWST (runGameM action) env state) rng
           in (res, finalState, events)

    it "adds specific severity consequence" $ do
      let env = mkEnv [mockConsTemplate 5]
      let state = mkActorState []
      let ((), finalState, events) = runLogicWithEnv env state (addConsequence (Just 5))

      length (consequences $ tableState finalState) `shouldBe` 1
      events `shouldContain` [ConsequenceAdded 5]

    it "calculates default resilience of 1 and proper severity" $ do
      -- No items, Res=1. existing=0. Sev = 0/1 + 1 = 1.
      let env = mkEnv [mockConsTemplate 1]
      let state = mkActorState []
      let ((), finalState, events) = runLogicWithEnv env state (addConsequence Nothing)

      events `shouldContain` [ConsequenceAdded 1]

    it "uses equipped resilience" $ do
      -- Item with Res=3. Existing=0. Sev = 0/3 + 1 = 1.
      let item = mockItemRes 3
      let tc = TCItem item
      let state0 = mkActorState []
      let state =
            state0
              { tableState =
                  (tableState state0)
                    { registry = Map.singleton cidRes tc
                    , assets = Map.singleton cidRes (Equipped Body)
                    }
              }
      let env = mkEnv [mockConsTemplate 1]
      let ((), finalState, events) = runLogicWithEnv env state (addConsequence Nothing)

      events `shouldContain` [ConsequenceAdded 1]

    it "calculates severity based on existing count and resilience" $ do
      -- Res=2. Existing=3 consequences. Sev = 3/2 + 1 = 1 + 1 = 2.
      let item = mockItemRes 2
      let tc = TCItem item

      let state0 = mkActorState []
      let state =
            state0
              { tableState =
                  (tableState state0)
                    { registry = Map.singleton cidRes tc
                    , assets = Map.singleton cidRes (Equipped Body)
                    , consequences = [cid1, cid2, cid3] -- 3 dummy existing
                    }
              }
      let env = mkEnv [mockConsTemplate 2]
      let ((), finalState, events) = runLogicWithEnv env state (addConsequence Nothing)

      events `shouldContain` [ConsequenceAdded 2]
