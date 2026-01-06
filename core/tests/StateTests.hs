{-# LANGUAGE DuplicateRecordFields #-}
{-# LANGUAGE OverloadedLabels #-}
{-# LANGUAGE OverloadedStrings #-}

module StateTests where

import Control.Monad.RWS (runRWST)
import Control.Monad.State (runState)
import Data.Aeson (eitherDecode, encode)
import System.Random (mkStdGen)
import Test.Tasty
import Test.Tasty.QuickCheck hiding (discard)

import ArbitraryInstances ()
import Core.Card (Identified (..), ItemCard (..))
import Core.Hardcoded (fatigueCard)
import Core.Logic.Deck (performFatigueCycle)
import Core.Logic.Monad (runGameM)
import Core.NonEmptyText (unsafeNonEmptyText)
import Core.Primitives (CardInstanceId (..), EquipSlot (..))
import Core.State
import Data.Map.Strict qualified as Map

import Optics ((%), (^.))

-- Bring instances into scope

test_stateTests :: TestTree
test_stateTests =
  testGroup
    "ActorState Logic"
    [ testProperty "Fatigue Cycle Increases Deck Size correctly" prop_fatigueCycleCounts
    , testProperty "ActorState JSON Roundtrip" prop_jsonRoundtrip
    ]

-- | Property: performFatigueCycle should result in a new deck size equal to
-- the old discard size + 2 (base fatigue) + burden.
-- We verify this for any initial state and any burden (>= 0).
prop_fatigueCycleCounts :: Small Int -> CoreCardState -> CardInstanceId -> Property
prop_fatigueCycleCounts (Small burdenRaw) coreSt itemId =
  let
    burden = abs burdenRaw -- Ensure non-negative burden for logic

    -- Construct ActorState with specific burden
    dummyItem :: ItemCard
    dummyItem =
      ItemCard
        { name = unsafeNonEmptyText "Heavy Armor"
        , tags = Nothing
        , flavor = Nothing
        , weight = Nothing
        , value = Nothing
        , traits = Nothing
        , passive = Nothing
        , defense = Nothing
        , resilience = Nothing
        , burden = Just burden
        }

    tableSt =
      TableState
        { assets = Map.singleton itemId (Identified itemId (TCItem dummyItem), Equipped SlotMainHand)
        , consequences = []
        }

    actorSt =
      ActorState
        { coreState = coreSt
        , tableState = tableSt
        , name = "Dummy"
        , actorType = "NPC"
        , spatial = SpatialState 0 0 1 Nothing
        , plannedMove = Nothing
        }

    initialDiscardSize = length (coreSt ^. #discard)
    expectedDeckSize = initialDiscardSize + 2 + burden

    gen = mkStdGen 42
    env = GameEnv{fatigueCardTemplate = fatigueCard}

    -- Run GameM
    action = performFatigueCycle
    stateAction = runRWST (runGameM action) env actorSt
    ((_, newState, _events), _) = runState stateAction gen
   in
    length (newState ^. #coreState % #deck) === expectedDeckSize
      .&&. length (newState ^. #coreState % #discard) === 0

-- | Property: ActorState should roundtrip through JSON encoding/decoding.
-- We resize the generator because the full unchecked recursion with default
-- arbitrary instances creates massive objects that are slow to process.
prop_jsonRoundtrip :: Property
prop_jsonRoundtrip = forAll (resize 15 arbitrary :: Gen ActorState) $ \st ->
  let
    json = encode st
    decoded = eitherDecode json :: Either String ActorState
   in
    case decoded of
      Right st' -> st' === st
      Left err -> counterexample ("Decode failed: " ++ err ++ "\nJSON: " ++ show json) False
