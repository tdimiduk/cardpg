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

import CardPG.Core.Card (CoreCard, ItemCardT (..))
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

createCards :: (RandomGen g) => CoreCard -> Int -> GameM g [CardInstanceId]
createCards template n = do
  newIds <- replicateM n $ liftRandom uniform
  modify $ #coreState % #registry %~ (`Map.union` Map.fromList [(cid, template) | cid <- newIds])
  tell [CardsCreated newIds]
  return newIds

calculateTotalBurden :: GameM g Int
calculateTotalBurden = do
  tblSt <- use #tableState
  let equippedItems =
        [ item
        | (cid, Equipped _) <- Map.toList (tblSt ^. #assets)
        , Just (TCItem item) <- [Map.lookup cid (tblSt ^. #registry)]
        ]
  let burden = sum [b | item <- equippedItems, let b = fromMaybe 0 (item ^. #burden)]
  return burden

performFatigueCycle :: (RandomGen g) => GameM g ()
performFatigueCycle = do
  env <- ask
  burden <- calculateTotalBurden

  newFatigueIds <- createCards (env ^. #fatigueCardTemplate) (2 + burden)

  currentDiscard <- use (#coreState % #discard)
  modify $ #coreState % #discard .~ []

  newDeck <- GameM . lift $ shuffleListM (newFatigueIds ++ currentDiscard)

  modify $ #coreState % #deck .~ newDeck
  tell [DeckShuffled]

deckCardTo ::
  (RandomGen g) =>
  Lens' CoreCardState [CardInstanceId] -> (CardInstanceId -> GameEvent) -> GameM g ()
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
  let (toDiscard, keep) = partition (`elem` cids) currentHand
  modify $ #coreState % #hand .~ keep
  modify $ #coreState % #discard %~ (toDiscard ++)

returnCardsToDeck :: (RandomGen g) => [CardInstanceId] -> GameM g ()
returnCardsToDeck cids = do
  currentHand <- use (#coreState % #hand)
  let (toReturn, keep) = partition (`elem` cids) currentHand
  modify $ #coreState % #hand .~ keep

  currentDeck <- use (#coreState % #deck)
  newDeck <- GameM . lift $ shuffleListM (toReturn ++ currentDeck)
  modify $ #coreState % #deck .~ newDeck
  tell [DeckShuffled]
