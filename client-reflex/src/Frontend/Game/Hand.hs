{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE RecursiveDo #-}

module Frontend.Game.Hand where

import Control.Monad.Fix (MonadFix)
import Control.Monad.IO.Class (MonadIO)
import Data.Maybe (isJust)
import Data.Set qualified as Set
import Reflex.Dom.Core

import Api.Request (ApiRequest (..))
import Api.Types (Command (..))
import Core.Card (CardInstance, CoreCard, Identified (..))
import Core.Logic.Planning (PlanValidation (..))
import Core.Primitives (ActorId, CardInstanceId)
import Core.State
  ( ActionStack (..)
  , ActorState (..)
  , CoreCardState (..)
  , PlannedAction (..)
  , plannedActionCards
  )
import Frontend.Card (CardDisplayMode (..), CardSettings (..), renderWith)
import Frontend.Game.PlannedAction (plannedActionWidget)
import Frontend.Game.Planning
import Frontend.Game.Staging (stagingWidget)
import Frontend.Style

-- | Styles for hand card hover interactions
cardHover :: [CssClass]
cardHover =
  [ "transition-transform"
  , "duration-200"
  , "ease-out"
  , "origin-bottom"
  , "hover:-translate-y-8"
  , "hover:z-50"
  , cursorPointer
  ]

-- | Styles for cards in staging mode (resource candidates)
resourceCandidate :: [CssClass]
resourceCandidate =
  [ "hover:-translate-y-4"
  , "hover:ring-2"
  , "hover:ring-amber-400"
  , cursorPointer
  ]

-- | View modes for the hand logic
data ViewMode = VMPlanned PlannedAction | VMStaging CardInstanceId | VMDefault

-- | Determine the current view mode based on actor state and staging state
determineViewMode :: ActorState -> StagingState -> ViewMode
determineViewMode actor staging = case actor.coreState.planned of
  Just p -> VMPlanned p
  Nothing -> maybe VMDefault VMStaging staging.stagedActionId

handWidget
  :: ( DomBuilder t m
     , PostBuild t m
     , MonadHold t m
     , MonadFix m
     , MonadIO m
     , Requester t m
     , Request m ~ ApiRequest
     )
  => Dynamic t (Identified ActorId ActorState)
  -> m ()
handWidget actorDyn = do
  let safeActor = (.content) <$> actorDyn
      actorId = (.id) <$> actorDyn

  rec (stagingState, validation) <- mkPlanBuilderLogic safeActor selectEvt toggleEvt clearEvt

      let viewMode = zipDynWith determineViewMode safeActor stagingState

      -- Render UI
      (selectClick, toggleClick, cancelStaging, commitStaging, revisePlanned) <-
        divStyle [absolute, bottom0, left0, right0, pointerEventsNone, z40] $ do
          -- Layer 1: Main Layout (Flex Row)
          (sel, tog, rev) <- divStyle [flex, justifyBetween, itemsEnd, "w-full", "px-8", "pb-4"] $ do
            -- Left: Planned Action
            revEvt' <- divStyle [flex1, flex, "justify-start"] $ do
              dyn $ ffor viewMode $ \case
                VMPlanned plan -> do
                  -- Planned action is interactive
                  divStyle [pointerEventsAuto] $ plannedActionWidget plan
                _ -> return never
            revEvt <- switchHold never revEvt'

            -- Center: Hand
            -- We wrap in pointerEventsAuto so cards catch clicks
            (s, t) <-
              divStyle [pointerEventsAuto] $
                handCardsWidget safeActor stagingState viewMode

            -- Right: Spacer
            divStyle [flex1] blank

            return (s, t, revEvt)

          -- Layer 2: Staging Overlay
          -- This sits on top (dom order) but is transparent to clicks by default (controlled by Staging widget)
          overlayEvts <- dyn $ ffor viewMode $ \case
            VMStaging _ -> do
              (cancel, _, commit) <- stagingWidget safeActor stagingState validation
              return (cancel, commit)
            _ -> return (never, never)

          -- Flatten events
          cancel <- switchHold never (fmap fst overlayEvts)
          commit <- switchHold never (fmap snd overlayEvts)

          return (sel, tog, cancel, commit, rev)

      let selectEvt = leftmost [selectClick]
          toggleEvt = toggleClick
          clearEvt = leftmost [cancelStaging, commitStaging]

      let commitPlan =
            attachWithMaybe
              (\val _ -> case val of PlanValid p -> Just p; _ -> Nothing)
              (current validation)
              commitStaging

      -- Requests
      let planReq =
            attachWith
              ( \aid plan ->
                  case plan of
                    PStandard (ActionStack ac res) ->
                      GameAction $
                        PlanAction
                          { actorId = aid
                          , actionCardId = ac.id
                          , resourceCardIds = map (.id) res
                          }
                    _ -> error "Narrative not supported in Hand yet"
              )
              (current actorId)
              commitPlan

      _ <- requesting planReq

      -- Revise Request
      let reviseReq = ffor (current actorId) $ \aid -> GameAction $ CancelPlanIntent aid

      _ <- requesting $ tag reviseReq revisePlanned

      return ()

  return ()

handCardsWidget
  :: (DomBuilder t m, PostBuild t m, MonadFix m, MonadHold t m)
  => Dynamic t ActorState
  -> Dynamic t StagingState
  -> Dynamic t ViewMode
  -> m (Event t CardInstanceId, Event t CardInstanceId)
handCardsWidget actor staging viewMode = do
  divStyle [flex, justifyCenter, itemsEnd, "px-8", pointerEventsAuto] $ do
    let visibleHand =
          (\a s vm -> filter (isCardVisible s vm) a.coreState.hand)
            <$> actor
            <*> staging
            <*> viewMode

    cardClicks <- divStyle [flex, itemsEnd, "transition-opacity", "duration-300"] $ do
      simpleList visibleHand $ \cardDyn -> do
        let isResourceCandidate = zipDynWith (\s c -> isStagingMode s && not (isStagedAction s c)) staging cardDyn
            isStagingMode s = isJust s.stagedActionId
            isStagedAction s c = Just c.id == s.stagedActionId

        let cardClass = ffor isResourceCandidate $ \c -> if c then resourceCandidate else cardHover

        let isSelectedResource = zipDynWith (\s c -> Set.member c.id s.stagedResourceIds) staging cardDyn
            ringClass = ffor isSelectedResource $ \sel -> if sel then ["ring-2", "ring-indigo-400", "ring-offset-2"] else []

            finalClassDyn =
              (\base ring -> classes ([relative, pointerEventsAuto, group, cardHandWidth] ++ base ++ ring))
                <$> cardClass
                <*> ringClass

        (e, _) <- elDynAttr' "div" (fmap ("class" =:) finalClassDyn) $ do
          dyn_ $ ffor cardDyn $ renderWith (CardSettings CardFull)

        return (domEvent Click e, cardDyn)

    let flatClick = switchDyn $ fmap (leftmost . map (\(e, c) -> tag (current c) e)) cardClicks
        flatClickId = fmap (.id) flatClick

    let selectEvent =
          attachWithMaybe
            (\vm cid -> case vm of VMDefault -> Just cid; _ -> Nothing)
            (current viewMode)
            flatClickId

    let toggleEvent =
          attachWithMaybe
            (\vm cid -> case vm of VMStaging _ -> Just cid; _ -> Nothing)
            (current viewMode)
            flatClickId

    return (selectEvent, toggleEvent)

isCardVisible :: StagingState -> ViewMode -> CardInstance CoreCard -> Bool
isCardVisible s vm c = case vm of
  VMPlanned plan -> c.id `notElem` map (.id) (plannedActionCards plan)
  VMStaging _ -> Just c.id /= s.stagedActionId
  VMDefault -> True
