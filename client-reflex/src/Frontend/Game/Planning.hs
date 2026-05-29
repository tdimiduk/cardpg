{-# LANGUAGE OverloadedStrings #-}

module Frontend.Game.Planning
  ( StagingState (..)
  , mkPlanBuilderLogic
  , StagUpdate (..)
  , applyUpdate
  , buildStagingStack
  ) where

import Control.Monad.Fix (MonadFix)
import Data.List (find)
import Data.Maybe (fromMaybe)
import Data.Set (Set)
import Data.Set qualified as Set
import Reflex

import Core.Card (CoreCard, Identified (..))
import Core.Logic.Planning (PlanValidation (..), validateStandardPlan)
import Core.Primitives (CardInstanceId)
import Core.State (ActionStack (..), ActorState (..), CoreCardState (..))

-- The action card cannot also be a resource (stagedActionId should not be a member of stagedResourceIds)
data StagingState = StagingState
  { stagedActionId :: Maybe CardInstanceId
  , stagedResourceIds :: Set CardInstanceId
  }
  deriving (Eq, Show)

emptyStaging :: StagingState
emptyStaging = StagingState Nothing Set.empty

data StagUpdate
  = SelectAction CardInstanceId
  | ToggleResource CardInstanceId
  | Clear

applyUpdate :: StagUpdate -> StagingState -> StagingState
applyUpdate (SelectAction cid) st =
  if st.stagedActionId == Just cid
    then st{stagedActionId = Nothing}
    else st{stagedActionId = Just cid, stagedResourceIds = Set.delete cid st.stagedResourceIds}
applyUpdate (ToggleResource cid) st
  | st.stagedActionId == Just cid = st
  | Set.member cid st.stagedResourceIds = st{stagedResourceIds = Set.delete cid st.stagedResourceIds}
  | otherwise = st{stagedResourceIds = Set.insert cid st.stagedResourceIds}
applyUpdate Clear _ = emptyStaging

mkPlanBuilderLogic
  :: (Reflex t, MonadHold t m, MonadFix m)
  => Maybe StagingState
  -- ^ Optional initial staging state
  -> Dynamic t ActorState
  -> Event t CardInstanceId -- Select Action Click
  -> Event t CardInstanceId -- Toggle Resource Click
  -> Event t () -- Clear/Cancel Click
  -> m (Dynamic t StagingState, Dynamic t PlanValidation)
mkPlanBuilderLogic mInitialStaging actorState actionClick resourceClick clearClick = do
  let initialStaging = fromMaybe emptyStaging mInitialStaging
      updateEvent =
        leftmost
          [ fmap SelectAction actionClick
          , fmap ToggleResource resourceClick
          , fmap (const Clear) clearClick
          ]

  currentStaging <- foldDyn applyUpdate initialStaging updateEvent

  let validation = zipDynWith validateStaging actorState currentStaging

  return (currentStaging, validation)

-- | Safely build the ActionStack for staging mode
-- Returns Nothing if the staged action card is not in hand
buildStagingStack :: ActorState -> StagingState -> Maybe ActionStack
buildStagingStack actor staging = do
  actId <- staging.stagedActionId
  actCard <- find (\(Identified i _) -> i == actId) actor.coreState.hand
  let resources = filter (\(Identified i _) -> i `Set.member` staging.stagedResourceIds) actor.coreState.hand
  return $ ActionStack actCard resources

validateStaging :: ActorState -> StagingState -> PlanValidation
validateStaging actor st =
  case buildStagingStack actor st of
    Nothing -> PlanInvalid "No action selected"
    Just stack -> validateStandardPlan stack.actionCard stack.resources
