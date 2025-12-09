{-# LANGUAGE OverloadedStrings #-}

module CardPG.Server.Engine
  ( PlayerDeckState (..)
  , emptyDeckState
  , drawCards
  , performDefend
  , calculateStackStrength
  , shuffleList
  ) where

import CardPG.Core.Card (CoreCardMachine, CoreCardT (..), Stats (..), _stats)

import CardPG.Core.Types (ResourceType (..))
import CardPG.Server.Types (CardLibrary (..), PlayerDeckState (..))
import Data.List (find)

import Data.Maybe (mapMaybe)
import qualified Data.Text as T
import System.Random (RandomGen, StdGen, uniformR)

emptyDeckState :: PlayerDeckState
emptyDeckState = PlayerDeckState [] [] [] []

-- | Fisher-Yates shuffle for a list
shuffleList :: (RandomGen g) => [a] -> g -> ([a], g)
shuffleList [] g = ([], g)
shuffleList l g =
  let (i, g') = uniformR (0, length l - 1) g
      (lead, x : xs) = splitAt i l
      (rest, g'') = shuffleList (lead ++ xs) g'
   in (x : rest, g'')

-- | Helper to get a Status card template from the library
-- Uses the same lookup logic as the frontend (id or tag)
getStatusCard :: CardLibrary -> T.Text -> Maybe CoreCardMachine
getStatusCard lib name =
  find match (statuses lib)
  where
    match c =
      let cid = CardPG.Core.Card._id c
          tags = CardPG.Core.Card._tags c
       in cid == name
            || cid == ("status-" <> name)
            -- Simple tag check: checks if any tag equals the name (case-insensitive in frontend, here we'll aim for exact or close)
            -- The frontend does `t.toLowerCase() === type.toLowerCase()`. We should probably be reasonably robust.
            || maybe False (any ((== T.toLower name) . T.toLower)) tags

-- | Perform a Fatigue Cycle: Shuffle discard pile + 2 Fatigue cards into a new draw pile.
performFatigueCycle :: CardLibrary -> PlayerDeckState -> StdGen -> (PlayerDeckState, StdGen)
performFatigueCycle lib state gen =
  let fatigueCard = getStatusCard lib "fatigue"
      fatigueCards = case fatigueCard of
        Just fc -> [fc, fc]
        Nothing -> []
      toShuffle = discardPile state ++ fatigueCards
      (newDraw, gen') = shuffleList toShuffle gen
   in (state{drawPile = newDraw, discardPile = []}, gen')

-- | Draw N cards. Handles Fatigue Cycle if deck runs out.
-- Returns new state, drawn cards, whether fatigue triggered, and new RNG.
drawCards ::
  Int ->
  CardLibrary ->
  PlayerDeckState ->
  StdGen ->
  (PlayerDeckState, [CoreCardMachine], Bool, StdGen)
drawCards count lib state = go count state [] False
  where
    go 0 s drawn fatigue g = (s{hand = hand s ++ drawn}, drawn, fatigue, g)
    go n s drawn fatigue g =
      case drawPile s of
        (c : cs) -> go (n - 1) s{drawPile = cs} (drawn ++ [c]) fatigue g
        [] ->
          -- Fatigue Cycle
          let newFatigue = fatigue || True
              (s', g') = performFatigueCycle lib s g
           in if null (drawPile s')
                then (s', drawn, newFatigue, g') -- Nothing to draw even after shuffle
                else go n s' drawn newFatigue g'

-- | Check strength of a stack of cards
calculateStackStrength :: [CoreCardMachine] -> ResourceType -> Int -> Int
calculateStackStrength stack color modifier =
  let base = sum $ map (getStat color . _stats) stack
   in base + modifier
  where
    getStat Red (Stats r _ _) = r
    getStat Yellow (Stats _ y _) = y
    getStat Blue (Stats _ _ b) = b

-- | Flip cards from deck to defensive pile until target value is met or deck exhaused.
-- Returns: New State, Flipped Cards, Success (Bool), Total Value, New RNG
performDefend ::
  PlayerDeckState ->
  CardLibrary ->
  Int ->
  ResourceType ->
  StdGen ->
  (PlayerDeckState, [CoreCardMachine], Bool, Int, StdGen)
performDefend state lib targetVal color gen =
  let startValue = calculateStackStrength (flippedPile state) color 0
   in if startValue >= targetVal
        then (state, [], True, startValue, gen)
        else flipMore state lib targetVal color startValue [] gen

flipMore ::
  PlayerDeckState ->
  CardLibrary ->
  Int ->
  ResourceType ->
  Int ->
  [CoreCardMachine] ->
  StdGen ->
  (PlayerDeckState, [CoreCardMachine], Bool, Int, StdGen)
flipMore state lib targetVal color currentVal newlyFlipped gen
  | currentVal >= targetVal =
      (state{flippedPile = flippedPile state ++ newlyFlipped}, newlyFlipped, True, currentVal, gen)
  | otherwise =
      case drawPile state of
        (c : cs) ->
          let val = calculateStackStrength [c] color 0
           in flipMore state{drawPile = cs} lib targetVal color (currentVal + val) (newlyFlipped ++ [c]) gen
        [] ->
          -- Fatigue Cycle during Defense
          let (s', gen') = performFatigueCycle lib state gen
           in if null (drawPile s')
                then (s'{flippedPile = flippedPile state ++ newlyFlipped}, newlyFlipped, False, currentVal, gen') -- Nothing left
                else flipMore s' lib targetVal color currentVal newlyFlipped gen'
