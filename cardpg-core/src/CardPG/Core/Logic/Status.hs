{-# LANGUAGE DuplicateRecordFields #-}
{-# LANGUAGE OverloadedRecordDot #-}

module CardPG.Core.Logic.Status
  ( addStatus
  , removeStatus
  , addConsequence
  , removeConsequence
  , isDefeated
  ) where

import Control.Monad (when)
import Control.Monad.RWS (ask, tell)
import Control.Monad.State (get, modify, put)
import Control.Monad.Trans.Class (lift)
import Data.Map.Strict qualified as Map
import Data.Text (Text)
import Data.Text qualified as T
import Optics
import System.Random (RandomGen, uniform, uniformR)

import CardPG.Core.Card (ConsequenceCard, ConsequenceCardT (..), CoreCardT (..))
import CardPG.Core.Logic.Combat (calculateResilience)
import CardPG.Core.Logic.Deck (createCards)
import CardPG.Core.Logic.Monad (GameM (..))
import CardPG.Core.NonEmptyText (getRawText)
import CardPG.Core.Primitives (CardInstanceId, CardLocation (..))
import CardPG.Core.State
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
      ids <- createCards template 1
      case ids of
        [cid] -> do
          case destination of
            LocationHand -> modify $ #coreState % #hand %~ (cid :)
            LocationDiscard -> modify $ #coreState % #discard %~ (cid :)
            LocationDeck -> modify $ #coreState % #deck %~ (cid :)
          tell [ActionPlanned (PStandard (ActionStack cid []))]
          tell [StatusAdded statusType destination]
        _ -> return ()

removeStatus :: Text -> Maybe CardInstanceId -> GameM g ()
removeStatus statusType maybeCardId = do
  registry <- use (#coreState % #registry)

  let matchFunc cid c =
        case maybeCardId of
          Just specificId -> specificId == cid
          Nothing -> getRawText c.name == statusType

  let findAndRemove :: Lens' CoreCardState [CardInstanceId] -> GameM g Bool
      findAndRemove location = do
        currentList <- use (#coreState % location)
        let (before, foundAndAfter) =
              break
                ( \cid -> case Map.lookup cid registry of
                    Just c -> matchFunc cid c
                    Nothing -> False
                )
                currentList
        case foundAndAfter of
          (_ : xs) -> do
            -- Found one element 'x'
            modify $ #coreState % location .~ (before ++ xs)
            return True
          [] -> return False

  -- Search order: Hand, Discard, Deck
  removedFromHand <- findAndRemove #hand
  if removedFromHand
    then do
      tell [StatusRemoved statusType (maybe "hand" (T.pack . show) maybeCardId)]
      return ()
    else do
      removedFromDiscard <- findAndRemove #discard
      if removedFromDiscard
        then do
          tell [StatusRemoved statusType (maybe "discard" (T.pack . show) maybeCardId)]
          return ()
        else do
          removed <- findAndRemove #deck
          when removed $
            tell [StatusRemoved statusType (maybe "deck" (T.pack . show) maybeCardId)]

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

      -- Add to TableState registry and list
      modify $ #tableState % #consequenceRegistry %~ Map.insert cid template
      modify $ #tableState % #consequences %~ (cid :)

      -- We might need a generic event for "AssetCreated" or reused CardsCreated?
      -- CardsCreated takes [CardInstanceId]. It doesn't imply CoreCard necessarily.
      tell [CardsCreated [cid]]
      tell [ConsequenceAdded finalSeverity]
      return ()

removeConsequence :: CardInstanceId -> GameM g ()
removeConsequence cid = do
  -- Remove from TableState
  modify $ #tableState % #consequences %~ filter (/= cid)
  modify $ #tableState % #consequenceRegistry %~ Map.delete cid
  tell [ConsequenceRemoved (T.pack $ show cid)]

isDefeated :: ActorState -> Bool
isDefeated actor =
  let registry = actor.tableState.consequenceRegistry
      isSev3 cid = case Map.lookup cid registry of
        Just card -> card.severity >= 3
        Nothing -> False
   in any isSev3 actor.tableState.consequences
