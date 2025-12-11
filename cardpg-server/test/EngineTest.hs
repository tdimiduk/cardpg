{-# LANGUAGE OverloadedStrings #-}

module EngineTest (tests) where

import Test.Tasty (TestTree, testGroup)
import Test.Tasty.HUnit (testCase, (@?=), assertBool)
import System.Random (mkStdGen, StdGen)
import CardPG.Core.Card (CoreCardT (..), CoreCardMachine, Stats (..))
import CardPG.Core.Primitives (ResourceType (..))
import CardPG.Server.Engine (PlayerDeckState (..), emptyDeckState, drawCards, performDefend)
import CardPG.Server.Types (CardLibrary (..))
import Data.List.NonEmpty (NonEmpty (..))
import CardPG.Core.NonEmptyText (unsafeNonEmptyText)
import qualified Data.Text as T



tests :: TestTree
tests = testGroup "Engine"
  [ testCase "Draw Cards - Simple" testSimpleDraw
  , testCase "Draw Cards - Fatigue Trigger" testFatigueDraw
  , testCase "Defend - Simple Success" testSimpleDefend
  , testCase "Defend - Reshuffle Discard" testDefendReshuffle
  ]

-- | Mock Card Library with a Fatigue card
mockLibrary :: CardLibrary
mockLibrary = CardLibrary [] [fatigueCard] []
 where
  fatigueCard = CoreCard
    { _id = "status-fatigue"
    , _name = unsafeNonEmptyText "Fatigue"
    , _tags = Just ("status" :| [])

    , _stats = Stats 0 0 0
    , _cost = Nothing
    , _rules = Nothing
    , _flavor = Nothing
    }



-- | Helper to create a dummy card with stats
dummyCard :: Int -> Int -> Int -> CoreCardMachine
dummyCard r y b = CoreCard
  { _id = "dummy"
  , _name = unsafeNonEmptyText "Dummy"
  , _tags = Nothing

  , _stats = Stats r y b
  , _cost = Nothing
  , _rules = Nothing
  , _flavor = Nothing
  }

testSimpleDraw :: IO ()
testSimpleDraw = do
  let deck = replicate 5 (dummyCard 1 1 1)
      state = emptyDeckState { drawPile = deck }
      gen = mkStdGen 42
      
      (newState, drawn, fatigue, _) = drawCards 2 mockLibrary state gen
  
  length drawn @?= 2
  length (drawPile newState) @?= 3
  length (hand newState) @?= 2
  fatigue @?= False

testFatigueDraw :: IO ()
testFatigueDraw = do
  let deck = [dummyCard 1 0 0] -- 1 card in deck
      discard = [dummyCard 0 1 0] -- 1 card in discard
      state = emptyDeckState { drawPile = deck, discardPile = discard }
      gen = mkStdGen 42
      
      -- Draw 2 cards: 1 from deck, triggers fatigue, reshuffles discard + 2 fatigue, draws 1 more
      (newState, drawn, fatigue, _) = drawCards 2 mockLibrary state gen
  
  length drawn @?= 2
  fatigue @?= True
  -- Initial deck had 1. Discard had 1. Added 2 fatigue. Total pool = 4.
  -- Drawn 2. Remaining in deck = 2.
  length (drawPile newState) @?= 2
  -- Verify logic:
  -- 1. Draw 1 (deck empty). Drawn=[A].
  -- 2. Need 1 more. Deck empty.
  -- 3. Shuffle Discard(1) + Fatigue(2) = 3 cards.
  -- 4. Draw 1 from new deck. Drawn=[A, B]. Remainder=2.
  
testSimpleDefend :: IO ()
testSimpleDefend = do
  let deck = [dummyCard 2 0 0, dummyCard 1 0 0] -- Top card is Red 2 (via pop or head? List is usually stack top at head for naive implementation, but `drawPile` usually implies top is head. Let's assume head is top.)
      -- `drawCards` implementation: removes from head.
      state = emptyDeckState { drawPile = deck }
      gen = mkStdGen 1
      
      -- Defend against 2 Red
      (newState, flipped, success, total, _) = performDefend state mockLibrary 2 Red gen
      
  -- Should flip the first card (2) and stop.
  length flipped @?= 1
  total @?= 2
  success @?= True
  length (drawPile newState) @?= 1
  length (flippedPile newState) @?= 1

testDefendReshuffle :: IO ()
testDefendReshuffle = do
   -- Empty draw, cards in discard.
   -- Discard has Red 3. Target is 3.
   let discard = [dummyCard 3 0 0]
       state = emptyDeckState { drawPile = [], discardPile = discard }
       gen = mkStdGen 1 -- Seed 1
       
       -- Defense runs out of cards immediately.
       -- Logic:
       -- 1. Check drawPile: Empty.
       -- 2. Trigger Fatigue Check.
       -- 3. Shuffle Discard(1) + Fatigue(2) = 3 cards.
       -- 4. Draw/Flip from new deck.
       
       (newState, flipped, success, total, _) = performDefend state mockLibrary 3 Red gen
   
   -- We expect to eventually find the 3 (or sum up to 3) from the new deck.
   -- Since discard had 3, and fatigue has 0, total potential value is 3.
   -- However, we mixed in 2 zeroes.
   -- If we hit zeroes first, we keep flipping.
   -- Eventually we hit the 3.
   
   success @?= True
   total @?= 3
   -- Flipped pile should contain the cards we flipped.
   -- Since we only have 1 card with value, and 2 zeroes:
   -- It might take 1, 2, or 3 flips to find the 3 depending on shuffle.
   -- With mkStdGen 1:
   -- Let's just assert we successfully defended.
   
   -- Also verify deck reconstruction:
   -- We started with 0 in draw, 1 in discard (total 1).
   -- Added 2 fatigue. Total system mass = 3.
   -- Flipped some number N. Remaining draw = 3 - N.
   length (flipped) + length (drawPile newState) @?= 3
   
   -- We expect discard to be empty after reshuffle
   null (discardPile newState) @?= True

