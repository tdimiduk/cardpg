{- HLINT ignore "Redundant id" -}

module Core.Logic.Deck
  ( drawCard
  , flipCardToDefense
  , reshuffleDeck
  , performFatigueCycle
  , createCards
  , discardCards
  , returnCardsToDeck
  , setVigilanceDial
  , syncVigilanceToDial
  , searchDeckForReadiedCard
  , commitVigilancePool
  , flushVigilanceCycle
  ) where

import Control.Lens
import Control.Monad (replicateM, replicateM_, when)
import Control.Monad.RWS (ask, tell)
import Control.Monad.State (modify)
import Control.Monad.Trans.Class (lift)
import Data.Generics.Labels ()
import Data.List (partition)
import Data.Map.Strict qualified as Map
import Data.Maybe (fromMaybe, maybeToList)
import Data.Text (Text)
import System.Random (RandomGen, uniform)

import Core.Card (CardInstance, CoreCard, Identified (..))
import Core.Logic.Monad (GameM (..), liftRandom)
import Core.Primitives (CardInstanceId)
import Core.State
  ( ActiveChallenge (..)
  , ActiveDefense (..)
  , AssetState (..)
  , CoreCardState (..)
  , GameEvent (..)
  , TableCard (..)
  )
import Core.Util (shuffleListM)

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
  let burden = sum [b | item <- equippedItems, let b = fromMaybe 0 item.burden]
  return burden

performFatigueCycle :: (RandomGen g) => GameM g ()
performFatigueCycle = do
  env <- ask
  burden <- calculateTotalBurden

  newFatigueCards <- createCards (env ^. #fatigueCardTemplate) (2 + burden)

  currentDiscard <- use (#coreState . #discard)
  modify $ #coreState . #discard .~ []

  newDeck <- GameM . lift $ shuffleListM (newFatigueCards ++ currentDiscard)

  modify $ #coreState . #deck .~ newDeck
  tell [DeckShuffled]

deckCardTo
  :: (RandomGen g)
  => Lens' CoreCardState [CardInstance CoreCard] -> (CardInstance CoreCard -> GameEvent) -> GameM g ()
deckCardTo dst gameLog = do
  currentDeck <- use (#coreState . #deck)
  case currentDeck of
    [] -> do
      performFatigueCycle
      deckCardTo dst gameLog
    (top : rest) -> do
      modify $ #coreState . #deck .~ rest
      modify $ #coreState . dst %~ (top :)
      tell [gameLog top]

drawCard :: (RandomGen g) => GameM g ()
drawCard = deckCardTo #hand CardDrawn

flipCardToDefense :: (RandomGen g) => ActiveChallenge -> GameM g ()
flipCardToDefense challenge = do
  currentDeck <- use (#coreState . #deck)
  case currentDeck of
    [] -> do
      performFatigueCycle
      flipCardToDefense challenge
    (top : rest) -> do
      currentDefense <- use (#coreState . #defending)
      case currentDefense of
        Nothing -> do
          modify $ #coreState . #deck .~ rest
          modify $ (#coreState . #defending) ?~ ActiveDefense challenge [top]
          tell [CardDefended challenge top]
        Just (ActiveDefense existingChallenge cards) ->
          Control.Monad.when (existingChallenge.id == challenge.id) $ do
            modify $ #coreState . #deck .~ rest
            modify $ (#coreState . #defending) ?~ ActiveDefense existingChallenge (top : cards)
            tell [CardDefended existingChallenge top]

reshuffleDeck :: (RandomGen g) => GameM g ()
reshuffleDeck = do
  discarded <- use (#coreState . #discard)
  currentDeck <- use (#coreState . #deck)
  newDeck <- GameM . lift $ shuffleListM (discarded ++ currentDeck)
  modify $ #coreState . #discard .~ []
  modify $ #coreState . #deck .~ newDeck
  tell [DeckShuffled]

discardCards :: [CardInstanceId] -> GameM g ()
discardCards cids = do
  currentHand <- use (#coreState . #hand)
  let (toDiscard, keep) = partition (\c -> c.id `elem` cids) currentHand
  modify $ #coreState . #hand .~ keep
  modify $ #coreState . #discard %~ (toDiscard ++)

returnCardsToDeck :: (RandomGen g) => [CardInstanceId] -> GameM g ()
returnCardsToDeck cids = do
  currentHand <- use (#coreState . #hand)
  let (toReturn, keep) = partition (\c -> c.id `elem` cids) currentHand
  modify $ #coreState . #hand .~ keep

  currentDeck <- use (#coreState . #deck)
  newDeck <- GameM . lift $ shuffleListM (toReturn ++ currentDeck)
  modify $ #coreState . #deck .~ newDeck
  tell [DeckShuffled]

-- | Set vigilance dial (clamped 0 to 4).
setVigilanceDial :: Int -> GameM g ()
setVigilanceDial d = do
  let clamped = max 0 (min 4 d)
  modify $ #coreState . #vigilanceDial .~ clamped
  tell [VigilanceDialSet clamped]

-- | Draw or trim face-down cards to match vigilance dial.
syncVigilanceToDial :: (RandomGen g) => GameM g ()
syncVigilanceToDial = do
  dial <- use (#coreState . #vigilanceDial)
  pool <- use (#coreState . #vigilancePool)
  let curLen = length pool
  if
    | curLen < dial -> replicateM_ (dial - curLen) drawCardToVigilancePool
    | curLen > dial -> do
        let (excess, keep) = splitAt (curLen - dial) pool
        modify $ #coreState . #vigilancePool .~ keep
        modify $ #coreState . #discard %~ (excess ++)
    | otherwise -> pure ()
  where
    drawCardToVigilancePool = do
      curDeck <- use (#coreState . #deck)
      case curDeck of
        [] -> do
          performFatigueCycle
          drawCardToVigilancePool
        (top : rest) -> do
          modify $ #coreState . #deck .~ rest
          modify $ #coreState . #vigilancePool %~ (top :)

-- | Search deck for a card to place face-up in the Readied Card slot (costs 1 min in exploration).
searchDeckForReadiedCard :: CardInstanceId -> GameM g (Either Text (CardInstance CoreCard))
searchDeckForReadiedCard targetId = do
  curDeck <- use (#coreState . #deck)
  let (matches, remaining) = partition (\c -> c.id == targetId) curDeck
  case matches of
    [] -> pure $ Left "Card not found in deck"
    (found : _) -> do
      mExisting <- use (#coreState . #readiedCard)
      case mExisting of
        Just old -> modify $ #coreState . #discard %~ (old :)
        Nothing -> pure ()
      modify $ #coreState . #deck .~ remaining
      modify $ #coreState . #readiedCard ?~ found
      tell [CardReadied (Just found)]
      pure $ Right found

-- | Commit vigilance: moves face-down vigilance pool and readied card into hand during General Actions.
commitVigilancePool :: GameM g ()
commitVigilancePool = do
  pool <- use (#coreState . #vigilancePool)
  mReadied <- use (#coreState . #readiedCard)
  let cardsToAdd = pool ++ maybeToList mReadied
  modify $ #coreState . #hand %~ (cardsToAdd ++)
  modify $ #coreState . #vigilancePool .~ []
  modify $ #coreState . #readiedCard .~ Nothing
  modify $ #coreState . #committedVigilance .~ True
  tell [VigilanceCommitted]

-- | Flush vigilance cycle: discards committed hand (or vigilance pool if uncommitted),
-- optionally pays 2 deck cards to retain readied card, and redraws pool up to vigilance dial.
flushVigilanceCycle :: (RandomGen g) => Bool -> GameM g ()
flushVigilanceCycle retainReadied = do
  isCommitted <- use (#coreState . #committedVigilance)
  if isCommitted
    then do
      curHand <- use (#coreState . #hand)
      modify $ #coreState . #discard %~ (curHand ++)
      modify $ #coreState . #hand .~ []
      modify $ #coreState . #committedVigilance .~ False
    else do
      pool <- use (#coreState . #vigilancePool)
      modify $ #coreState . #discard %~ (pool ++)
      modify $ #coreState . #vigilancePool .~ []

  mReadied <- use (#coreState . #readiedCard)
  case mReadied of
    Just rc ->
      if retainReadied
        then discardFromDeck (2 :: Int)
        else do
          modify $ #coreState . #discard %~ (rc :)
          modify $ #coreState . #readiedCard .~ Nothing
          tell [CardReadied Nothing]
    Nothing -> pure ()

  syncVigilanceToDial
  tell [VigilanceFlushed]
  where
    discardFromDeck :: (RandomGen g') => Int -> GameM g' ()
    discardFromDeck 0 = pure ()
    discardFromDeck n = do
      curDeck <- use (#coreState . #deck)
      case curDeck of
        [] -> do
          performFatigueCycle
          discardFromDeck n
        (top : rest) -> do
          modify $ #coreState . #deck .~ rest
          modify $ #coreState . #discard %~ (top :)
          discardFromDeck (n - 1)
