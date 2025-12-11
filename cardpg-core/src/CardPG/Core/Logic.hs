{-# LANGUAGE ScopedTypeVariables #-}
{-# LANGUAGE TypeApplications #-}

module CardPG.Core.Logic
  ( performFatigueCycle
  ) where

import Data.Map.Strict qualified as Map
import Data.UUID (UUID)
import System.Random (Random (..), RandomGen)

import CardPG.Core.Hardcoded (fatigueCard)
import CardPG.Core.Primitives (CardInstanceId (..))
import CardPG.Core.State (ActorState (..), CoreCardState (..))
import CardPG.Core.Util (shuffleList)

-- | Perform the Fatigue Cycle
-- 1. Take Discard
-- 2. Generate (2 + burden) new Fatigue Cards with new UUIDs (requires RandomGen)
-- 3. Update Registry with new Fatigue Cards
-- 4. Shuffle (Discard + NewFatigue) -> Deck
-- 5. Clear Discard
performFatigueCycle :: (RandomGen g) => Int -> g -> ActorState -> (ActorState, g)
performFatigueCycle burden gen st =
  let
    core = _coreState st
    sources = _discard core

    countNeeded = 2 + burden

    -- Recursive generator to get N UUIDs and final generator state
    genUUIDs :: (RandomGen g) => Int -> g -> ([UUID], g)
    genUUIDs 0 g_ = ([], g_)
    genUUIDs n g_ =
      let (u, g1) = random @UUID g_
          (us, g2) = genUUIDs (n - 1) g1
       in (u : us, g2)

    (newFatigueUUIDs, gen2) = genUUIDs countNeeded gen
    newFatigueIds = map CardInstanceId newFatigueUUIDs

    -- Update Registry
    newRegistryEntries = Map.fromList [(cid, fatigueCard) | cid <- newFatigueIds]
    updatedRegistry = Map.union (_coreRegistry st) newRegistryEntries

    -- Shuffle
    toShuffle = sources ++ newFatigueIds
    (newDeck, gen3) = shuffleList toShuffle gen2

    newCore =
      core
        { _deck = newDeck
        , _discard = []
        }
   in
    (st{_coreState = newCore, _coreRegistry = updatedRegistry}, gen3)
