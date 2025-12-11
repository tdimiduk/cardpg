{-# LANGUAGE ScopedTypeVariables #-}

module CardPG.Core.Logic
  ( GameM(..)
  , performFatigueCycle
  ) where

import Control.Monad (replicateM)
import Control.Monad.RWS (RWST, ask, tell, MonadReader, MonadWriter)
import Control.Monad.State (MonadState, state, State, modify)
import Control.Monad.Trans.Class (lift)
import Data.Map.Strict qualified as Map
import Optics
import System.Random (RandomGen, uniform)

import CardPG.Core.State (CoreCardState (..), GameEnv (..), GameEvent (..))
import CardPG.Core.Util (shuffleListM)

-- | The Game Monad
-- Stack:
--   Reader: GameEnv (static context)
--   Writer: [GameEvent] (log of events)
--   State: CoreCardState (game state)
--   Base: State g (random number generator state)
newtype GameM g a = GameM
  { runGameM :: RWST GameEnv [GameEvent] CoreCardState (State g) a
  }
  deriving newtype
    ( Functor
    , Applicative
    , Monad
    , MonadReader GameEnv
    , MonadWriter [GameEvent]
    , MonadState CoreCardState
    )

-- | Helper to access the random generator from the base monad
liftRandom :: (g -> (a, g)) -> GameM g a
liftRandom f = GameM . lift $ state f

-- | Perform the Fatigue Cycle
performFatigueCycle :: RandomGen g => Int -> GameM g ()
performFatigueCycle burden = do
  env <- ask
  let fatigueTemplate = env ^. #fatigueCardTemplate
  
  let countNeeded = 2 + burden

  -- Generate UUIDs
  newFatigueIds <- replicateM countNeeded $ liftRandom uniform

  -- Update Registry
  let newRegistryEntries = Map.fromList [(cid, fatigueTemplate) | cid <- newFatigueIds]
  
  -- Log Event
  tell [CardsCreated newFatigueIds]

  -- Modify State: Update Registry
  modify $ #registry %~ (`Map.union` newRegistryEntries)

  -- Get Discard and set it to empty
  currentDiscard <- use #discard
  modify $ #discard .~ []

  -- Shuffle (Discard + NewFatigue) -> Deck
  -- shuffleListM :: (RandomGen g, MonadState g m) => [a] -> m [a]
  -- We specialized GameM base monad to (State g), so we can lift directly.
  newDeck <- GameM . lift $ shuffleListM (newFatigueIds ++ currentDiscard)
  
  modify $ #deck .~ newDeck
  tell [DeckShuffled]
