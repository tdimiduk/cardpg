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

performFatigueCycle :: RandomGen g => Int -> GameM g ()
performFatigueCycle burden = do
  env <- ask
  let fatigueTemplate = env ^. #fatigueCardTemplate
  
  let countNeeded = 2 + burden

  newFatigueIds <- replicateM countNeeded $ liftRandom uniform

  let newRegistryEntries = Map.fromList [(cid, fatigueTemplate) | cid <- newFatigueIds]
  
  tell [CardsCreated newFatigueIds]

  modify $ #registry %~ (`Map.union` newRegistryEntries)

  currentDiscard <- use #discard
  modify $ #discard .~ []

  newDeck <- GameM . lift $ shuffleListM (newFatigueIds ++ currentDiscard)
  
  modify $ #deck .~ newDeck
  tell [DeckShuffled]
