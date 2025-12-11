{-# LANGUAGE ScopedTypeVariables #-}

module CardPG.Core.Logic
  ( GameM(..)
  , runGameM
  , performFatigueCycle
  , drawCard
  , flipCardToDefense
  ) where

import Control.Monad (replicateM)
import Control.Monad.RWS (RWST, ask, tell, MonadReader, MonadWriter)
import Control.Monad.State (MonadState, state, State, modify)
import Control.Monad.Trans.Class (lift)
import Data.Map.Strict qualified as Map
import Optics
import System.Random (RandomGen, uniform)

import CardPG.Core.State (ActorState (..), CoreCardState (..), GameEnv (..), GameEvent (..), TableState (..), AssetState (..), TableCard (..))
import CardPG.Core.Card (ItemCardT (..))
import CardPG.Core.Util (shuffleListM)

-- | The Game Monad
-- Stack:
--   Reader: GameEnv (static context)
--   Writer: [GameEvent] (log of events)
--   State: ActorState (game state)
--   Base: State g (random number generator state)
newtype GameM g a = GameM
  { runGameM :: RWST GameEnv [GameEvent] ActorState (State g) a
  }
  deriving newtype
    ( Functor
    , Applicative
    , Monad
    , MonadReader GameEnv
    , MonadWriter [GameEvent]
    , MonadState ActorState
    )

runGameM :: GameM g a -> RWST GameEnv [GameEvent] ActorState (State g) a
runGameM (GameM x) = x

-- | Helper to access the random generator from the base monad
liftRandom :: (g -> (a, g)) -> GameM g a
liftRandom f = GameM . lift $ state f

calculateTotalBurden :: GameM g Int
calculateTotalBurden = do
  tblSt <- use #tableState
  let equippedItems = [ item | (cid, Equipped _) <- Map.toList (tblSt ^. #assets)
                             , Just (TCItem item) <- [Map.lookup cid (tblSt ^. #registry)]
                             ]
  let burden = sum [ b | item <- equippedItems, let b = maybe 0 id (item ^. #burden) ]
  return burden

performFatigueCycle :: RandomGen g => GameM g ()
performFatigueCycle = do
  env <- ask
  burden <- calculateTotalBurden
  let fatigueTemplate = env ^. #fatigueCardTemplate
  
  let countNeeded = 2 + burden

  newFatigueIds <- replicateM countNeeded $ liftRandom uniform

  let newRegistryEntries = Map.fromList [(cid, fatigueTemplate) | cid <- newFatigueIds]
  
  tell [CardsCreated newFatigueIds]

  modify $ #coreState % #registry %~ (`Map.union` newRegistryEntries)

  currentDiscard <- use (#coreState % #discard)
  modify $ #coreState % #discard .~ []

  newDeck <- GameM . lift $ shuffleListM (newFatigueIds ++ currentDiscard)
  
  modify $ #coreState % #deck .~ newDeck
  tell [DeckShuffled]

drawCard :: RandomGen g => GameM g ()
drawCard = do
  currentDeck <- use (#coreState % #deck)
  case currentDeck of
    [] -> do
      performFatigueCycle
      drawCard
    (top:rest) -> do
      modify $ #coreState % #deck .~ rest
      modify $ #coreState % #hand %~ (top :)
      tell [CardDrawn top]

flipCardToDefense :: RandomGen g => GameM g ()
flipCardToDefense = do
  currentDeck <- use (#coreState % #deck)
  case currentDeck of
    [] -> do
      performFatigueCycle
      flipCardToDefense
    (top:rest) -> do
      modify $ #coreState % #deck .~ rest
      modify $ #coreState % #defending %~ (top :)
      tell [CardDefended top]
