module CardPG.Core.Util
  ( shuffleList
  ) where

import Data.List (sortOn)
import System.Random (Random (..), RandomGen)

-- | Helper to shuffle a list
-- Uses O(N log N) sort-based shuffle which is sufficient for game logic
shuffleList :: (RandomGen g) => [a] -> g -> ([a], g)
shuffleList xs gen =
  let len = length xs
      (randomInts, gen') = splitGenList len gen
      shuffled = map snd $ sortOn fst $ zip randomInts xs
   in (shuffled, gen')

splitGenList :: (RandomGen g) => Int -> g -> ([Int], g)
splitGenList 0 g = ([], g)
splitGenList n g =
  let (i, g1) = random g
      (is, g2) = splitGenList (n - 1) g1
   in (i : is, g2)
