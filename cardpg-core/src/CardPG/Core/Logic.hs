{-# LANGUAGE ScopedTypeVariables #-}

module CardPG.Core.Logic
  ( performFatigueCycle
  ) where

import Control.Monad (replicateM)
import Control.Monad.State (MonadState, state)
import Data.Map.Strict qualified as Map
import System.Random (RandomGen, uniform)

import CardPG.Core.Hardcoded (fatigueCard)
import CardPG.Core.State (ActorState (..), CoreCardState (..))
import CardPG.Core.Util (shuffleListM)

-- | Perform the Fatigue Cycle
-- 1. Take Discard
-- 2. Generate (2 + burden) new Fatigue Cards with new UUIDs (requires RandomGen)
-- 3. Update Registry with new Fatigue Cards
-- 4. Shuffle (Discard + NewFatigue) -> Deck
-- 5. Clear Discard
performFatigueCycle :: (RandomGen g, MonadState g m) => Int -> ActorState -> m ActorState
performFatigueCycle burden st = do
  let
    core = _coreState st
    sources = _discard core

    countNeeded = 2 + burden

  -- Generate UUIDs (CardInstanceIds via Uniform instance)
  newFatigueIds <- replicateM countNeeded (state uniform)

  -- Update Registry
  let newRegistryEntries = Map.fromList [(cid, fatigueCard) | cid <- newFatigueIds]
  let updatedRegistry = Map.union (_coreRegistry st) newRegistryEntries

  -- Shuffle
  let toShuffle = sources ++ newFatigueIds
  newDeck <- shuffleListM toShuffle

  let newCore =
        core
          { _deck = newDeck
          , _discard = []
          }
  pure st{_coreState = newCore, _coreRegistry = updatedRegistry}
