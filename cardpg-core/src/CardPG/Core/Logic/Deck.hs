{- HLINT ignore "Redundant id" -}

module CardPG.Core.Logic.Deck
  ( drawCard
  , flipCardToDefense
  , reshuffleDeck
  , performFatigueCycle
  , createCards
  , discardCards
  , returnCardsToDeck
  ) where

import Control.Monad (replicateM)
import Control.Monad.RWS (ask, tell)
import Control.Monad.State (modify)
import Control.Monad.Trans.Class (lift)
import Data.List (partition)
import Data.Map.Strict qualified as Map
import Data.Maybe (fromMaybe)
import Optics
import System.Random (RandomGen, uniform)

import CardPG.Core.Card (CardInstance, CoreCard, Identified (..), ItemCardT (..))
import CardPG.Core.Logic.Monad (GameM (..), liftRandom)
import CardPG.Core.Primitives (CardInstanceId)
import CardPG.Core.State
  ( ActorState (..)
  , AssetState (..)
  , CoreCardState (..)
  , GameEnv (..)
  , GameEvent (..)
  , TableCard (..)
  , TableState (..)
  )
import CardPG.Core.Util (shuffleListM)

createCards :: (RandomGen g) => CoreCard -> Int -> GameM g [CardInstance CoreCard]
createCards template n = do
  newIds <- replicateM n $ liftRandom uniform
  let newCards = [Identified cid template | cid <- newIds]
  tell [CardsCreated newCards]
  return newCards

calculateTotalBurden :: GameM g Int
calculateTotalBurden = do
  tblSt <- use #tableState
  let equippedItems =
        [ item
        | (_, (Identified _ (TCItem item), Equipped _)) <- Map.toList (tblSt ^. #assets)
        ]
  let burden = sum [b | item <- equippedItems, let b = fromMaybe 0 (item ^. #burden)]
  return burden

performFatigueCycle :: (RandomGen g) => GameM g ()
performFatigueCycle = do
  env <- ask
  burden <- calculateTotalBurden

  newFatigueCards <- createCards (env ^. #fatigueCardTemplate) (2 + burden)

  currentDiscard <- use (#coreState % #discard)
  modify $ #coreState % #discard .~ []

  newDeck <- GameM . lift $ shuffleListM (newFatigueCards ++ currentDiscard)

  modify $ #coreState % #deck .~ newDeck
  tell [DeckShuffled]

deckCardTo ::
  (RandomGen g) =>
  Lens' CoreCardState [CardInstance CoreCard] -> (CardInstance CoreCard -> GameEvent) -> GameM g ()
deckCardTo dst gameLog = do
  currentDeck <- use (#coreState % #deck)
  case currentDeck of
    [] -> do
      performFatigueCycle
      deckCardTo dst gameLog
    (top : rest) -> do
      modify $ #coreState % #deck .~ rest
      modify $ #coreState % dst %~ (top :)
      tell [gameLog top]

drawCard :: (RandomGen g) => GameM g ()
drawCard = deckCardTo #hand CardDrawn

flipCardToDefense :: (RandomGen g) => GameM g ()
flipCardToDefense = deckCardTo #defending CardDefended

reshuffleDeck :: (RandomGen g) => GameM g ()
reshuffleDeck = do
  discarded <- use (#coreState % #discard)
  currentDeck <- use (#coreState % #deck)
  newDeck <- GameM . lift $ shuffleListM (discarded ++ currentDeck)
  modify $ #coreState % #discard .~ []
  modify $ #coreState % #deck .~ newDeck
  tell [DeckShuffled]

discardCards :: [CardInstanceId] -> GameM g ()
discardCards cids = do
  currentHand <- use (#coreState % #hand)
  let (toDiscard, keep) = partition (\c -> c.id `elem` cids) currentHand
  modify $ #coreState % #hand .~ keep
  modify $ #coreState % #discard %~ (toDiscard ++)

returnCardsToDeck :: (RandomGen g) => [CardInstanceId] -> GameM g ()
returnCardsToDeck cids = do
  currentHand <- use (#coreState % #hand)
  let (toReturn, keep) = partition (\c -> c.id `elem` cids) currentHand
  modify $ #coreState % #hand .~ keep

  currentDeck <- use (#coreState % #deck)
  newDeck <- GameM . lift $ shuffleListM (toReturn ++ currentDeck)
  modify $ #coreState % #deck .~ newDeck
  tell [DeckShuffled]
