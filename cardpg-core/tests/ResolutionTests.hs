{-# LANGUAGE OverloadedRecordDot #-}
{-# LANGUAGE OverloadedStrings #-}

module ResolutionTests where

import Control.Monad.RWS (runRWST)
import Control.Monad.State (runState)
import Data.Map.Strict qualified as Map
import System.Random (mkStdGen, StdGen)
import Test.Tasty
import Test.Tasty.HUnit

import CardPG.Core.Card (CoreCard (..), ItemCard, ItemCardT (..), Stats (..))
import CardPG.Core.Hardcoded (fatigueCard)
import CardPG.Core.Logic (GameM, runGameM)
import CardPG.Core.Logic qualified as Logic
import CardPG.Core.NonEmptyText (unsafeNonEmptyText)
import CardPG.Core.Primitives (CardInstanceId (..), ResourceType (..), ActorId (..))
import CardPG.Core.State
import Optics ((%), (&), (.~), (?~), (^.))

test_resolutionCycle :: TestTree
test_resolutionCycle = testCase "Full Resolution Cycle" $ do
  let
    gen = mkStdGen 42
    env = GameEnv{fatigueCardTemplate = fatigueCard}
    
    -- ids
    c1Id = CardInstanceId (read "00000000-0000-0000-0000-000000000001")
    c2Id = CardInstanceId (read "00000000-0000-0000-0000-000000000002")
    c3Id = CardInstanceId (read "00000000-0000-0000-0000-000000000003")
    
    dummyCard = fatigueCard -- simple card
    
    initialCore = CoreCardState
      { deck = []
      , hand = [c1Id, c2Id, c3Id]
      , discard = []
      , defending = []
      , inPlay = Map.empty
      , registry = Map.fromList [(c1Id, dummyCard), (c2Id, dummyCard), (c3Id, dummyCard)]
      , planned = Nothing
      }
      
    initialActor = ActorState
      { name = "Tester"
      , actorType = "PC"
      , coreState = initialCore
      , tableState = TableState Map.empty Map.empty
      , spatial = SpatialState 0 0 1 Nothing
      , plannedMove = Nothing
      }

  -- 1. Plan Action (c1 with c2 as resource)
  let planAction = Logic.planAction c1Id [c2Id]
      ((_, actorAfterPlan, _), _) = runState (runRWST (runGameM planAction) env initialActor) gen
  
  -- Verify plan
  case actorAfterPlan.coreState.planned of
    Just (ActionStack ac res) -> do
      assertEqual "Action card correct" c1Id ac
      assertEqual "Resource card correct" [c2Id] res
    Nothing -> assertFailure "Action should be planned"
    
  -- 2. Defend with c3
  let defendAction = Logic.flipCardToDefense :: GameM System.Random.StdGen ()
        -- Wait, flipCardToDefense pulls from DECK.
        -- My initial state has hand [c1, c2, c3], deck [].
        -- Let's put c3 in DECK for this test.
  
  let actorWithDeck = initialActor & #coreState % #hand .~ [c1Id, c2Id]
                                   & #coreState % #deck .~ [c3Id]
      
      -- Plan again on this state
      ((_, actorAfterPlan2, _), gen2) = runState (runRWST (runGameM planAction) env actorWithDeck) gen
      
      -- Defend
      ((_, actorAfterDefend, _), gen3) = runState (runRWST (runGameM Logic.flipCardToDefense) env actorAfterPlan2) gen2

  -- Verify defense
  assertEqual "Defending stack has c3" [c3Id] (actorAfterDefend.coreState.defending)
  
  -- 3. Resolve Round (End Defense + Discard Planned)
  let resolveAction = do
        Logic.endDefense
        Logic.discardPlannedActions
        
      ((_, actorFinal, events), _) = runState (runRWST (runGameM resolveAction) env actorAfterDefend) gen3
      
  -- Verify cleanup
  assertEqual "Defending stack empty" [] (actorFinal.coreState.defending)
  assertEqual "Planned action empty" Nothing (actorFinal.coreState.planned)
  
  let discard = actorFinal.coreState.discard
  assertBool "c1 (action) in discard" (c1Id `elem` discard)
  assertBool "c2 (resource) in discard" (c2Id `elem` discard)
  assertBool "c3 (defense) in discard" (c3Id `elem` discard)
