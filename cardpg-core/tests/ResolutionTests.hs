{-# LANGUAGE DuplicateRecordFields #-}
{-# LANGUAGE OverloadedRecordDot #-}
{-# LANGUAGE OverloadedStrings #-}

module ResolutionTests where

import Control.Monad.RWS (runRWST)
import Control.Monad.State (runState)
import Data.Map.Strict qualified as Map
import System.Random (StdGen, mkStdGen)
import Test.Tasty
import Test.Tasty.HUnit

import CardPG.Core.Card (CoreCard (..), Identified (..))
import CardPG.Core.Hardcoded (fatigueCard)
import CardPG.Core.Logic.Deck qualified as Logic
import CardPG.Core.Logic.Monad (GameM, runGameM)
import CardPG.Core.Logic.Planning qualified as Logic
import CardPG.Core.Primitives (CardInstanceId (..), ChallengeId (..), ResourceType (..))
import CardPG.Core.State
import Optics ((%), (&), (.~))

test_resolutionCycle :: TestTree
test_resolutionCycle = testCase "Full Resolution Cycle" $ do
  let
    gen = mkStdGen 42
    env =
      GameEnv
        { fatigueCardTemplate = fatigueCard
        , statusCardTemplates = Map.empty
        , consequenceCardTemplates = Map.empty
        }

    -- ids
    c1Id = CardInstanceId (read "00000000-0000-0000-0000-000000000001")
    c2Id = CardInstanceId (read "00000000-0000-0000-0000-000000000002")
    c3Id = CardInstanceId (read "00000000-0000-0000-0000-000000000003")

    dummyCard = fatigueCard -- simple card

    -- Action card for planning test (ensure cost matches resource count)
    dummyActionCard =
      CoreCard
        { name = fatigueCard.name
        , tags = fatigueCard.tags
        , stats = fatigueCard.stats
        , cost = Just 1
        , rules = fatigueCard.rules
        , flavor = fatigueCard.flavor
        }

    card1 = Identified c1Id dummyActionCard
    card2 = Identified c2Id dummyCard
    card3 = Identified c3Id dummyCard

    initialCore =
      CoreCardState
        { deck = []
        , hand = [card1, card2, card3]
        , discard = []
        , defending = Nothing
        , inPlay = Map.empty
        , planned = Nothing
        , revealed = Nothing
        }

    initialActor =
      ActorState
        { name = "Tester"
        , actorType = "PC"
        , coreState = initialCore
        , tableState = TableState Map.empty []
        , spatial = SpatialState 0 0 1 Nothing
        , plannedMove = Nothing
        }

  -- 1. Plan Action (c1 with c2 as resource)
  let planAction = Logic.planAction c1Id [c2Id]
      ((_, actorAfterPlan, _), _) = runState (runRWST (runGameM planAction) env initialActor) gen

  -- Verify plan
  case actorAfterPlan.coreState.planned of
    Just (PStandard (ActionStack ac res)) -> do
      assertEqual "Action card correct" c1Id ac.id
      assertEqual "Resource card correct" [c2Id] (map (.id) res)
    Just _ -> assertFailure "unexpected action planned"
    Nothing -> assertFailure "Action should be planned"

  -- 2. Defend with c3
  let cid = ChallengeId (read "00000000-0000-0000-0000-000000000099")
  let dummyChallenge =
        ActiveChallenge
          { id = cid
          , source = CSAdHoc "Test Challenge" Nothing
          , challengeStrength = 5
          , challengeColor = Red
          }

  let _defendAction = Logic.flipCardToDefense dummyChallenge :: GameM System.Random.StdGen ()
  -- TODO: check something about this defend action

  let actorWithDeck =
        initialActor
          & #coreState
          % #hand
          .~ [card1, card2]
          & #coreState
          % #deck
          .~ [card3]

      -- Plan again on this state
      ((_, actorAfterPlan2, _), gen2) = runState (runRWST (runGameM planAction) env actorWithDeck) gen

      -- Defend
      ((_, actorAfterDefend, _), gen3) = runState (runRWST (runGameM (Logic.flipCardToDefense dummyChallenge)) env actorAfterPlan2) gen2

  -- Verify defense
  case actorAfterDefend.coreState.defending of
    Just (ActiveDefense c cards) -> do
      assertEqual "Challenge Id matches" cid c.id
      assertEqual "Defending stack has c3" [c3Id] (map (.id) cards)
    Nothing -> assertFailure "Expected defending state"

  -- 3. Resolve Round (End Defense + Discard Planned)
  let resolveAction = do
        Logic.endDefense
        Logic.discardPlannedActions

      ((_, actorFinal, _), _) = runState (runRWST (runGameM resolveAction) env actorAfterDefend) gen3

  -- Verify cleanup
  assertEqual "Defending stack empty" Nothing actorFinal.coreState.defending
  assertEqual "Planned action empty" Nothing actorFinal.coreState.planned

  let discard = map (.id) actorFinal.coreState.discard
  assertBool "c1 (action) in discard" (c1Id `elem` discard)
  assertBool "c2 (resource) in discard" (c2Id `elem` discard)
  assertBool "c3 (defense) in discard" (c3Id `elem` discard)
