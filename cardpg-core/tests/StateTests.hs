{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE TypeApplications #-}
{-# LANGUAGE OverloadedLabels #-}
{-# LANGUAGE DuplicateRecordFields #-}

module StateTests where

import Data.Aeson (eitherDecode, encode)
import Control.Monad.RWS (runRWST)
import Control.Monad.State (runState)
import System.Random (mkStdGen)
import Test.Tasty
import Test.Tasty.QuickCheck hiding (discard)

import ArbitraryInstances ()
import CardPG.Core.Hardcoded (fatigueCard)
import CardPG.Core.Logic (performFatigueCycle, GameM(..))
import CardPG.Core.State
import Optics ((^.))

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
prop_fatigueCycleCounts :: Small Int -> CoreCardState -> Property
prop_fatigueCycleCounts (Small burdenRaw) st =
  let
    burden = abs burdenRaw -- Ensure non-negative burden for logic

    initialDiscardSize = length (st ^. #discard)
    expectedDeckSize = initialDiscardSize + 2 + burden

    gen = mkStdGen 42
    env = GameEnv { fatigueCardTemplate = fatigueCard }
    
    -- Run GameM
    action = performFatigueCycle burden
    stateAction = runRWST (runGameM action) env st
    ((_, newState, _events), _) = runState stateAction gen

   in
    length (newState ^. #deck) === expectedDeckSize
      .&&. length (newState ^. #discard) === 0

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
