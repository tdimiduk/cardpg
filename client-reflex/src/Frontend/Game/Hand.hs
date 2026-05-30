{-# LANGUAGE DataKinds #-}
{-# LANGUAGE OverloadedRecordDot #-}
{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE RecursiveDo #-}

module Frontend.Game.Hand where

import Control.Monad.Fix (MonadFix)
import Control.Monad.IO.Class (MonadIO)
import Data.Map qualified as Map
import Data.Maybe (fromMaybe, isJust)
import Reflex.Dom.Core

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
import Frontend.Game.Class
import Frontend.Game.PlannedAction (plannedActionWidget)
import Frontend.Game.Planning
import Frontend.Game.Staging (StagingEvents (..), stagingWidget)

import Frontend.Style qualified as FS
import Frontend.Style.Common (classNames, divS)
import Frontend.Style.DSL as S
import Frontend.Util (buildStableKeyMap)

-- | Styles for hand card hover interactions (transformer style)
cardHoverStyle :: Style
cardHoverStyle =
  S.transitionTransform
    . S.duration200
    . S.easeOut
    . S.originBottom
    . S.hover S.translateYNeg8
    . S.hover (S.z 40)
    . S.cursorPointer

-- | Styles for cards in staging mode (resource candidates)
resourceCandidateStyle :: Style
resourceCandidateStyle =
  S.hover S.translateYNeg4
    . S.hover S.ring2
    . S.hover (S.ring S.Amber 5)
    . S.cursorPointer

handWidget
  :: ( DomBuilder t m
     , PostBuild t m
     , MonadHold t m
     , MonadFix m
     , MonadIO m
     , MonadGame t m
     )
  => Maybe StagingState
  -- ^ Optional initial staging state
  -> Dynamic t (Identified ActorId ActorState)
  -> m ()
handWidget mInitialStaging actorDyn = do
  let safeActor = (.content) <$> actorDyn
      actorId = (.id) <$> actorDyn
      handDyn = (.coreState.hand) <$> safeActor

  keyMapDyn <- buildStableKeyMap (.id) handDyn

  rec (stagingState, validation) <-
        mkPlanBuilderLogic mInitialStaging safeActor selectEvt toggleEvt clearEvt

      -- Derived View Models
      let plannedActionDyn = (.coreState.planned) <$> safeActor
          stagingStackDyn = zipDynWith buildStagingStack safeActor stagingState

      -- Render UI
      (selectEvt, toggleEvt, clearEvt) <-
        divS
          ( S.absolute
              . S.bottom0
              . S.left0
              . S.right0
              . S.pointerEventsNone
              . S.z 40
              . S.flex
              . S.justifyBetween
              . S.itemsEnd
              . S.wFull
              . S.px S.S8
              . S.pb S.S4
          )
          $ do
            -- Layer 1: Main Layout (Flex Row) merged into parent
            (sel, tog, overlayEvts) <- do
              -- Left: Planned Action
              divS (S.flex1 . S.flex . S.justifyCenter) $ do
                dyn_ $ ffor (zipDyn actorId plannedActionDyn) $ \case
                  (aid, Just plan) -> plannedActionWidget (Identified aid plan)
                  _ -> blank

              -- Center: Hand & Staging Container
              (s, t, oEvts) <- divS (S.relative . S.flexCol . S.itemsCenter . S.pointerEventsNone . S.gap S.S4) $ do
                -- Layer 2: Staging Overlay (placed above hand cards)
                o <- dyn $ ffor (zipDyn actorId stagingStackDyn) $ \case
                  (aid, Just stk) -> stagingWidget aid (constDyn stk) validation
                  _ -> return (StagingEvents never never never)

                -- Center: Hand Cards
                (handS, handT) <-
                  handCardsWidget safeActor stagingStackDyn plannedActionDyn keyMapDyn

                return (handS, handT, o)

              -- Right: Spacer
              divS S.flex1 blank

              return (s, t, oEvts)

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

-- Additional atoms needed that weren't in DSL2

handCardsWidget
  :: (DomBuilder t m, PostBuild t m, MonadFix m, MonadHold t m)
  => Dynamic t ActorState
  -> Dynamic t (Maybe ActionStack)
  -- ^ Staging Stack (defines staging mode)
  -> Dynamic t (Maybe PlannedAction)
  -- ^ Planned Action (defines hidden cards)
  -> Dynamic t (Map.Map CardInstanceId Int)
  -- ^ Stable sequence mappings for cards
  -> m (Event t CardInstanceId, Event t CardInstanceId)
handCardsWidget actor stagingStack plannedAction keyMapDyn = do
  divS (S.flex . S.justifyCenter . S.itemsEnd . S.px S.S4 . S.pointerEventsAuto) $ do
    let visibleHand =
          (\a stk plan -> filter (isCardVisible stk plan) a.coreState.hand)
            <$> actor
            <*> stagingStack
            <*> plannedAction

        keyedHandMapDyn =
          ( \vis handKeys ->
              Map.fromList
                [ (StableHandKey seqNum c.id, c)
                | c <- vis
                , let seqNum = fromMaybe 0 (Map.lookup c.id handKeys)
                ]
          )
            <$> visibleHand
            <*> keyMapDyn

    cardClicksDyn <- divS (S.flex . S.itemsEnd . transitionOpacity . S.duration200) $ do
      listWithKey keyedHandMapDyn $ \_key cardDyn -> do
        let isCandidate = zipDynWith checkResourceCandidate stagingStack cardDyn
            isSelected = zipDynWith checkIsSelected stagingStack cardDyn

        let finalClassDyn =
              ffor ((,,) <$> isCandidate <*> isSelected <*> stagingStack) $ \(cand, sel, stk) ->
                let
                  inStaging = isJust stk
                  baseStyle = if cand then resourceCandidateStyle else cardHoverStyle

                  -- Interaction highlights
                  extraStyle
                    | inStaging = if sel then S.cls "staged-gold-ring" else id
                    | otherwise = id
                 in
                  -- Build final class string from composed styles
                  classNames $ S.relative . cardHandWidth . extraStyle . baseStyle . S.pointerEventsAuto . S.group

        (e, _) <- elDynAttr' "div" (fmap ("class" =:) finalClassDyn) $ do
          dyn_ $ ffor cardDyn $ renderCoreCardWith (CardSettings CardFull) . (.content)

        let effectiveClick = domEvent Click e

        return (effectiveClick, cardDyn)

    let clickEventsMapDyn =
          ffor cardClicksDyn $ \m ->
            Map.elems $ Map.mapWithKey (\_ (clickEvt, cardDyn) -> tag (current (fmap (.id) cardDyn)) clickEvt) m
        flatClickId = switchDyn (leftmost <$> clickEventsMapDyn)

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

-- Additional atoms needed
-- Re-export styles from Frontend.Style as transformers
cardHandWidth :: Style
cardHandWidth = FS.cardHandWidth

isCardVisible :: Maybe ActionStack -> Maybe PlannedAction -> CardInstance CoreCard -> Bool
isCardVisible stagingStack plannedAction c =
  let hiddenInPlan = case plannedAction of
        Just plan -> c.id `elem` map (.id) (plannedActionCards plan)
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
