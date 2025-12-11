{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE TypeApplications #-}

module StateTests where

import Data.Aeson (eitherDecode, encode)
import Control.Monad.State (runState)
import System.Random (mkStdGen)
import Test.Tasty
import Test.Tasty.QuickCheck

import ArbitraryInstances ()
import CardPG.Core.Logic (performFatigueCycle)
import CardPG.Core.State

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
prop_fatigueCycleCounts :: Small Int -> ActorState -> Property
prop_fatigueCycleCounts (Small burdenRaw) st =
  let
    burden = abs burdenRaw -- Ensure non-negative burden for logic

    -- We force the deck to be empty?
    -- The logic of performFatigueCycle replaces the deck.
    -- So strictly speaking, it doesn't matter if deck was empty or not,
    -- the result size is deterministic based on discard.

    initialDiscardSize = length (_discard (_coreState st))
    expectedDeckSize = initialDiscardSize + 2 + burden

    gen = mkStdGen 42 -- We can use a fixed seed for the cycle itself, the randomness comes from 'st'.
    -- Or we could take a seed as input, but it doesn't verify the size property.
    (newState, _) = runState (performFatigueCycle burden st) gen
    newCore = _coreState newState
   in
    length (_deck newCore) === expectedDeckSize
      .&&. length (_discard newCore) === 0

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
