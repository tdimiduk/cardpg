{- HLINT ignore "Redundant id" -}

module Core.Logic.Status
  ( addStatus
  , destroyStatus
  , addConsequence
  , destroyConsequence
  , isDefeated
  ) where

import Control.Monad.RWS (ask, tell)
import Control.Monad.State (get, modify, put)
import Control.Monad.Trans.Class (lift)
import Data.Map.Strict qualified as Map
import Data.Text (Text)
import Data.Text qualified as T
import Optics
import System.Random (RandomGen, uniform, uniformR)

import Core.Card
  ( CardInstance
  , ConsequenceCard (..)
  , CoreCard (..)
  , Identified (..)
  )
import Core.Logic.Combat (calculateResilience)
import Core.Logic.Deck (createCards)
import Core.Logic.Monad (GameM (..))
import Core.NonEmptyText (getRawText)
import Core.Primitives (CardInstanceId, CardLocation (..))
import Core.State
  ( ActionStack (..)
  , ActorState (..)
  , CoreCardState (..)
  , GameEnv (..)
  , GameEvent (..)
  , PlannedAction (..)
  , TableState (..)
  )

addStatus :: (RandomGen g) => Text -> CardLocation -> GameM g ()
addStatus statusType destination = do
  env <- ask
  let maybeTemplate = Map.lookup statusType (env ^. #statusCardTemplates)
  case maybeTemplate of
    Nothing -> return () -- Invalid status type?
    Just template -> do
      cards <- createCards template 1
      case cards of
        [card] -> do
          case destination of
            LocationHand -> modify $ #coreState % #hand %~ (card :)
            LocationDiscard -> modify $ #coreState % #discard %~ (card :)
            LocationDeck -> modify $ #coreState % #deck %~ (card :)
          tell [ActionPlanned (PStandard (ActionStack card []))]
          tell [StatusAdded statusType destination]
        _ -> return ()

destroyStatus :: Text -> Maybe CardInstanceId -> GameM g ()
destroyStatus statusType maybeCardId = do
  let matchFunc c =
        case maybeCardId of
          Just specificId -> specificId == c.id
          Nothing -> getRawText c.content.name == statusType

  let findAndRemove ::
        Lens' CoreCardState [CardInstance CoreCard] -> GameM g (Maybe (CardInstance CoreCard))
      findAndRemove location = do
        currentList <- use (#coreState % location)
        let (before, foundAndAfter) = break matchFunc currentList
        case foundAndAfter of
          (foundCard : xs) -> do
            -- Found one element 'x'
            modify $ #coreState % location .~ (before ++ xs)
            return (Just foundCard)
          [] -> return Nothing

  -- Search order: Hand, Discard, Deck
  removedHand <- findAndRemove #hand
  case removedHand of
    Just _ -> do
      tell [StatusRemoved statusType "hand"]
    Nothing -> do
      removedDiscard <- findAndRemove #discard
      case removedDiscard of
        Just _ -> do
          tell [StatusRemoved statusType "discard"]
        Nothing -> do
          removedDeck <- findAndRemove #deck
          case removedDeck of
            Just _ -> do
              tell [StatusRemoved statusType "deck"]
            Nothing -> return ()

addConsequence :: (RandomGen g) => Maybe Int -> GameM g ()
addConsequence maybeSeverity = do
  finalSeverity <- case maybeSeverity of
    Just s -> return s
    Nothing -> do
      res <- calculateResilience
      tblSt <- use #tableState
      let count = length (tblSt ^. #consequences)
      return $ (count `div` res) + 1

  env <- ask
  let candidates = filter (\c -> c.severity == finalSeverity) (Map.elems (env ^. #consequenceCardTemplates))

  -- If no exact match for severity, maybe we should clamp or fallback?
  -- For now, explicit filter as before.
  case candidates of
    [] -> return ()
    _ -> do
      -- Pick random index
      g <- GameM . lift $ get
      let (idx, g') = uniformR (0, length candidates - 1) g
      GameM . lift $ put g'
      let template = candidates !! idx

      -- Create a new ID
      let (cid, g'') = uniform g'
      GameM . lift $ put g''

      let newConsequence = Identified cid template

      -- Add to TableState list (no registry)
      modify $ #tableState % #consequences %~ (newConsequence :)

      tell [ConsequenceAdded newConsequence]
      return ()

destroyConsequence :: CardInstanceId -> GameM g ()
destroyConsequence cid = do
  -- Remove from TableState
  modify $ #tableState % #consequences %~ filter (\c -> c.id /= cid)
  tell [ConsequenceRemoved (T.pack $ show cid)]

isDefeated :: ActorState -> Bool
isDefeated actor =
  let isSev3 c = c.content.severity >= 3
   in any isSev3 actor.tableState.consequences
