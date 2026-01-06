{-# LANGUAGE FlexibleContexts #-}

module Core.Util
  ( shuffleList
  , shuffleListM
  , tshow
  ) where

import Control.Monad (replicateM)
import Control.Monad.State (MonadState, state)
import Data.List (sortOn)
import Data.Text qualified as T
import System.Random (Random (..), RandomGen)

-- | Helper to shuffle a list
-- Uses O(N log N) sort-based shuffle which is sufficient for game logic
shuffleList :: (RandomGen g) => [a] -> g -> ([a], g)
shuffleList xs gen =
  let len = length xs
      (randomInts, gen') = splitGenList len gen
      shuffled = map snd $ sortOn fst $ zip randomInts xs
   in (shuffled, gen')

-- | Monadic version of shuffleList
shuffleListM :: forall g m a. (RandomGen g, MonadState g m) => [a] -> m [a]
shuffleListM xs = do
  let len = length xs
  randomInts <- replicateM len (state (random @Int @g) :: m Int)
  pure $ map snd $ sortOn fst $ zip randomInts xs

splitGenList :: (RandomGen g) => Int -> g -> ([Int], g)
splitGenList 0 g = ([], g)
splitGenList n g =
  let (i, g1) = random g
      (is, g2) = splitGenList (n - 1) g1
   in (i : is, g2)

tshow :: (Show a) => a -> T.Text
tshow = T.pack . show
