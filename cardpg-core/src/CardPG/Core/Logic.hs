{-# LANGUAGE ScopedTypeVariables #-}

module CardPG.Core.Logic
  ( performFatigueCycle
  ) where

import Control.Monad (replicateM)
import Control.Monad.State (MonadState, state)
import Data.Map.Strict qualified as Map
import Optics
import System.Random (RandomGen, uniform)

import CardPG.Core.Hardcoded (fatigueCard)
import CardPG.Core.State (CoreCardState (..), coreRegistry, deck, discard)
import CardPG.Core.Util (shuffleListM)

-- | Perform the Fatigue Cycle
-- 1. Take Discard
-- 2. Generate (2 + burden) new Fatigue Cards with new UUIDs (requires RandomGen)
-- 3. Update Registry with new Fatigue Cards
-- 4. Shuffle (Discard + NewFatigue) -> Deck
-- 5. Clear Discard
performFatigueCycle :: (RandomGen g, MonadState g m) => Int -> CoreCardState -> m CoreCardState
performFatigueCycle burden st = do
  let countNeeded = 2 + burden

  -- Generate UUIDs (CardInstanceIds via Uniform instance)
  newFatigueIds <- replicateM countNeeded (state uniform)

  -- Update Registry
  let newRegistryEntries = Map.fromList [(cid, fatigueCard) | cid <- newFatigueIds]

  -- Shuffle
  let currentDiscard = st ^. discard
  newDeck <- shuffleListM $ newFatigueIds ++ currentDiscard

  pure $ st
    & coreRegistry %~ (`Map.union` newRegistryEntries)
    & deck .~ newDeck
    & discard .~ []
