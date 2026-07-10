{-# LANGUAGE FlexibleContexts #-}

module Core.Util
  ( shuffleListM
  , tshow
  ) where

import Control.Monad (replicateM)
import Control.Monad.State (MonadState, state)
import Data.List (sortOn)
import Data.Text qualified as T
import System.Random (Random (..), RandomGen)

-- | Monadic version of shuffleList
shuffleListM :: forall g m a. (RandomGen g, MonadState g m) => [a] -> m [a]
shuffleListM xs = do
  let len = length xs
  randomInts <- replicateM len (state (random @Int @g) :: m Int)
  pure $ map snd $ sortOn fst $ zip randomInts xs

tshow :: (Show a) => a -> T.Text
tshow = T.pack . show
