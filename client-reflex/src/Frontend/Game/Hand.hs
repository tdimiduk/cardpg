{-# LANGUAGE DataKinds #-}
{-# LANGUAGE OverloadedRecordDot #-}
{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE RecursiveDo #-}

module Frontend.Game.Hand where

import Control.Monad.Fix (MonadFix)
import Control.Monad.IO.Class (MonadIO)
import Data.List (find)
import Data.Maybe (isJust)
import Data.Set qualified as Set
import Reflex.Dom.Core

import Api.Request (ApiRequest (..))
import Core.Card (CardInstance, CoreCard (..), Identified (..))

import Core.Primitives (ActorId, CardInstanceId)
import Core.State
  ( ActionStack (..)
  , ActorState (..)
  , CoreCardState (..)
  , PlannedAction (..)
  , plannedActionCards
  )
import Frontend.Card (CardDisplayMode (..), CardSettings (..), renderCoreCardWith)
import Frontend.Game.PlannedAction (plannedActionWidget)
import Frontend.Game.Planning
import Frontend.Game.Staging (StagingEvents (..), stagingWidget)

import Frontend.Style hiding (stack)

-- | Styles for hand card hover interactions
cardHover :: [CssClass]
cardHover =
  [ "transition-transform"
  , "duration-200"
  , "ease-out"
  , "origin-bottom"
  , "hover:-translate-y-8"
  , "hover:z-40"
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

-- | Safely build the ActionStack for staging mode
-- Returns Nothing if the staged action card is not in hand
buildStagingStack :: ActorState -> StagingState -> Maybe ActionStack
buildStagingStack actor staging = do
  actId <- staging.stagedActionId
  actCard <- find (\(Identified i _) -> i == actId) actor.coreState.hand
  let resources = filter (\(Identified i _) -> i `Set.member` staging.stagedResourceIds) actor.coreState.hand
  return $ ActionStack actCard resources

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

      -- Derived View Models
      let plannedActionDyn = (.coreState.planned) <$> safeActor
          stagingStackDyn = zipDynWith buildStagingStack safeActor stagingState

      -- Render UI
      (selectEvt, toggleEvt, clearEvt) <-
        divStyle
          [ absolute
          , bottom0
          , left0
          , right0
          , pointerEventsNone
          , z40
          , flex
          , justifyBetween
          , itemsEnd
          , "w-full"
          , "px-8"
          , "pb-4"
          ]
          $ do
            -- Layer 1: Main Layout (Flex Row) merged into parent
            (sel, tog) <- do
              -- Left: Planned Action
              divStyle [flex1, flex, "justify-start"] $ do
                dyn_ $ ffor (zipDyn actorId plannedActionDyn) $ \case
                  (aid, Just plan) -> plannedActionWidget (Identified aid plan)
                  _ -> blank

              -- Center: Hand
              (s, t) <-
                handCardsWidget safeActor stagingStackDyn plannedActionDyn

              -- Right: Spacer
              divStyle [flex1] blank

              return (s, t)

            -- Layer 2: Staging Overlay
            overlayEvts <- dyn $ ffor (zipDyn actorId stagingStackDyn) $ \case
              (aid, Just stk) -> stagingWidget aid (constDyn stk) validation
              _ -> return (StagingEvents never never never)

            -- Flatten events
            cancel <- switchHold never (fmap (.cancel) overlayEvts)
            unstageResource' <- switchHold never (fmap (.unstage) overlayEvts)
            commit <- switchHold never (fmap (.commit) overlayEvts)

            return
              ( sel
              , leftmost [tog, unstageResource']
              , leftmost [cancel, commit]
              )

      return ()

  return ()

handCardsWidget
  :: (DomBuilder t m, PostBuild t m, MonadFix m, MonadHold t m)
  => Dynamic t ActorState
  -> Dynamic t (Maybe ActionStack)
  -- ^ Staging Stack (defines staging mode)
  -> Dynamic t (Maybe PlannedAction)
  -- ^ Planned Action (defines hidden cards)
  -> m (Event t CardInstanceId, Event t CardInstanceId)
handCardsWidget actor stagingStack plannedAction = do
  divStyle [flex, justifyCenter, itemsEnd, "px-8", pointerEventsAuto] $ do
    let visibleHand =
          (\a stk plan -> filter (isCardVisible stk plan) a.coreState.hand)
            <$> actor
            <*> stagingStack
            <*> plannedAction

    let handSizeDyn = length . (.coreState.hand) <$> actor

    cardClicks <- divStyle [flex, itemsEnd, "transition-opacity", "duration-300"] $ do
      simpleList visibleHand $ \cardDyn -> do
        let isCandidate = zipDynWith checkResourceCandidate stagingStack cardDyn
            isSelected = zipDynWith checkIsSelected stagingStack cardDyn
            isPlayableDyn = zipDynWith (\size c -> isPlayable size c.content) handSizeDyn cardDyn

        let finalClassDyn =
              ffor ((,,,) <$> isCandidate <*> isSelected <*> isPlayableDyn <*> stagingStack) $ \(cand, sel, playable, stk) ->
                let
                  inStaging = isJust stk
                  baseStyle = if cand then resourceCandidate else cardHover

                  -- Interaction highlights
                  extraStyle
                    | inStaging = if sel then ["ring-2", "ring-indigo-400", "ring-offset-2"] else []
                    | playable = cardPlayable
                    | otherwise = cardNotPlayable
                 in
                  classes ([relative, pointerEventsAuto, group, cardHandWidth] ++ baseStyle ++ extraStyle)

        (e, _) <- elDynAttr' "div" (fmap ("class" =:) finalClassDyn) $ do
          dyn_ $ ffor cardDyn $ renderCoreCardWith (CardSettings CardFull) . (.content)

        -- Only allow clicking if playable (or if in staging mode)
        let clickEnabled = ffor ((,) <$> isPlayableDyn <*> stagingStack) $ \(p, stk) -> isJust stk || p
            effectiveClick = gate (current clickEnabled) (domEvent Click e)

        return (effectiveClick, cardDyn)

    let flatClick = switchDyn $ fmap (leftmost . map (\(e, c) -> tag (current c) e)) cardClicks
        flatClickId = fmap (.id) flatClick

    -- Select Event: Only fires when NOT in staging mode
    let selectEvent =
          attachWithMaybe
            (\stk cid -> if isJust stk then Nothing else Just cid)
            (current stagingStack)
            flatClickId

    -- Toggle Event: Only fires when IN staging mode
    let toggleEvent =
          attachWithMaybe
            (\stk cid -> if isJust stk then Just cid else Nothing)
            (current stagingStack)
            flatClickId

    return (selectEvent, toggleEvent)

isCardVisible :: Maybe ActionStack -> Maybe PlannedAction -> CardInstance CoreCard -> Bool
isCardVisible stagingStack plannedAction c =
  let hiddenInPlan = case plannedAction of
        Just p -> c.id `elem` map (.id) (plannedActionCards p)
        Nothing -> False
      hiddenInStaging = case stagingStack of
        Just s -> Just c.id == Just s.actionCard.id
        Nothing -> False
   in not hiddenInPlan && not hiddenInStaging

-- | Check if a card is a valid resource candidate (not the action itself)
checkResourceCandidate :: Maybe ActionStack -> CardInstance CoreCard -> Bool
checkResourceCandidate stk c = case stk of
  Just s -> c.id /= s.actionCard.id
  Nothing -> False

-- | Check if a card is currently selected as a resource in staging
checkIsSelected :: Maybe ActionStack -> CardInstance CoreCard -> Bool
checkIsSelected stk c = case stk of
  Just s -> any (\r -> r.id == c.id) s.resources
  Nothing -> False

-- | Check if a card can be played as an action
-- Must have a cost, and cost must be <= available resources (hand size - 1)
isPlayable :: Int -> CoreCard -> Bool
isPlayable handSize CoreCard{cost} = case cost of
  Just c -> c <= handSize - 1
  Nothing -> False
