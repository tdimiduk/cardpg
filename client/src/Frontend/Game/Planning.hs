{-# LANGUAGE OverloadedStrings #-}

module Frontend.Game.Planning
  ( StagingState (..)
  , StableHandKey (..)
  , mkPlanBuilderLogic
  , StagUpdate (..)
  , applyUpdate
  , buildStagingStack
  ) where

import Control.Monad.Fix (MonadFix)
import Data.List (find)
import Data.Set (Set)
import Data.Set qualified as Set
import Reflex

import Core.Card (Identified (..))
import Core.Logic.Planning (PlanValidation (..), validateStandardPlan)
import Core.Primitives (CardInstanceId)
import Core.State (ActionStack (..), ActorState (..), CoreCardState (..))

-- Structural safety: An active staging state MUST have a strict action card
data StagingState = StagingState
  { stagedActionId :: !CardInstanceId
  , stagedResourceIds :: !(Set CardInstanceId)
  }
  deriving (Eq, Show)

-- | Represents a card's stable position in the hand.
-- The Int is a monotonic sequence number that governs stable rendering order.
-- The CardInstanceId preserves the card's DOM identity for transition animations.
data StableHandKey = StableHandKey
  { sequenceNum :: !Int
  , instanceId :: !CardInstanceId
  }
  deriving (Eq)

instance Ord StableHandKey where
  compare k1 k2 = compare k1.sequenceNum k2.sequenceNum

data StagUpdate
  = SelectAction CardInstanceId
  | ToggleResource CardInstanceId
  | Clear

applyUpdate :: StagUpdate -> Maybe StagingState -> Maybe StagingState
applyUpdate (SelectAction cid) Nothing = Just $ StagingState cid Set.empty
applyUpdate (SelectAction cid) (Just st) =
  if st.stagedActionId == cid
    then Nothing
    else Just $ StagingState cid (Set.delete cid st.stagedResourceIds)
applyUpdate (ToggleResource _) Nothing = Nothing
applyUpdate (ToggleResource cid) (Just st)
  | st.stagedActionId == cid = Just st
  | Set.member cid st.stagedResourceIds =
      Just $ st{stagedResourceIds = Set.delete cid st.stagedResourceIds}
  | otherwise = Just $ st{stagedResourceIds = Set.insert cid st.stagedResourceIds}
applyUpdate Clear _ = Nothing

mkPlanBuilderLogic
  :: (Reflex t, MonadHold t m, MonadFix m)
  => Maybe StagingState
  -- ^ Optional initial staging state
  -> Dynamic t ActorState
  -> Event t CardInstanceId -- Select Action Click
  -> Event t CardInstanceId -- Toggle Resource Click
  -> Event t () -- Clear/Cancel Click
  -> m (Dynamic t (Maybe StagingState), Dynamic t PlanValidation)
mkPlanBuilderLogic mInitialStaging actorState actionClick resourceClick clearClick = do
  let updateEvent =
        leftmost
          [ fmap SelectAction actionClick
          , fmap ToggleResource resourceClick
          , fmap (const Clear) clearClick
          ]

  currentStaging <- foldDyn applyUpdate mInitialStaging updateEvent

  let validation = zipDynWith validateStaging actorState currentStaging

  return (currentStaging, validation)

-- | Safely build the ActionStack for staging mode
-- Returns Nothing if the staged action card is not in hand
buildStagingStack :: ActorState -> Maybe StagingState -> Maybe ActionStack
buildStagingStack actor = \case
  Nothing -> Nothing
  Just staging -> do
    let actId = staging.stagedActionId
    actCard <- find (\(Identified i _) -> i == actId) actor.coreState.hand
    let resources = filter (\(Identified i _) -> i `Set.member` staging.stagedResourceIds) actor.coreState.hand
    return $ ActionStack actCard resources

validateStaging :: ActorState -> Maybe StagingState -> PlanValidation
validateStaging actor st =
  case buildStagingStack actor st of
    Nothing -> PlanInvalid "No action selected"
    Just stack -> validateStandardPlan stack.actionCard stack.resources
