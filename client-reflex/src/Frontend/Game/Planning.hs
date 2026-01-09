{-# LANGUAGE OverloadedStrings #-}

module Frontend.Game.Planning
  ( StagingState (..)
  , mkPlanBuilderLogic
  , StagUpdate (..)
  , applyUpdate
  ) where

import Control.Monad.Fix (MonadFix)
import Data.List (find)
import Data.Set (Set)
import Data.Set qualified as Set
import Reflex

import Core.Card (Identified (..))
import Core.Logic.Planning (PlanValidation (..), validateStandardPlan)
import Core.Primitives (CardInstanceId)
import Core.State (ActorState (..), CoreCardState (..))

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
  => Dynamic t ActorState
  -> Event t CardInstanceId -- Select Action Click
  -> Event t CardInstanceId -- Toggle Resource Click
  -> Event t () -- Clear/Cancel Click
  -> m (Dynamic t StagingState, Dynamic t PlanValidation)
mkPlanBuilderLogic actorState actionClick resourceClick clearClick = do
  let updateEvent =
        leftmost
          [ fmap SelectAction actionClick
          , fmap ToggleResource resourceClick
          , fmap (const Clear) clearClick
          ]

  currentStaging <- foldDyn applyUpdate emptyStaging updateEvent

  let validation = zipDynWith validateStaging actorState currentStaging

  return (currentStaging, validation)

validateStaging :: ActorState -> StagingState -> PlanValidation
validateStaging actor st =
  case st.stagedActionId of
    Nothing -> PlanInvalid "No action selected"
    Just aid ->
      let hand = actor.coreState.hand
          maybeAction = find (\c -> c.id == aid) hand
          resources = filter (\c -> Set.member c.id st.stagedResourceIds) hand
       in case maybeAction of
            Nothing -> PlanInvalid "Action card not in hand"
            Just actionCard -> validateStandardPlan actionCard resources
