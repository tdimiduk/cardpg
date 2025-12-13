module CardPG.Core.LogicTest where

import Control.Monad.RWS (runRWST)
import Control.Monad.State (evalState)
import Data.List (sort)
import qualified Data.Map.Strict as Map
import System.Random (mkStdGen)
import Test.Hspec

import CardPG.Core.Card (ConsequenceCard, CoreCard (..), ItemCard, NatureCard, TalentCard)
import CardPG.Core.Logic
import CardPG.Core.Primitives (CardInstanceId (..), TargetId (..))
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

      (planned $ coreState finalState) `shouldBe` Nothing
      (discard $ coreState finalState) `shouldContain` [c1, c2]
