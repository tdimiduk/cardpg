{-# LANGUAGE DataKinds #-}
{-# LANGUAGE OverloadedRecordDot #-}
{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE RecursiveDo #-}

module Frontend.Game.Hand where

import Control.Monad (void)
import Control.Monad.Fix (MonadFix)
import Control.Monad.IO.Class (MonadIO)
import Data.List (find)
import Data.Map qualified as Map
import Data.Maybe (fromMaybe, isJust)
import Data.Text qualified as T
import Reflex.Dom.Core hiding (button)

import Core.Card (CardInstance, CoreCard (..), Identified (..))

import Core.Primitives (ActorId, CardInstanceId)
import Core.State
  ( ActionStack (..)
  , ActorState (..)
  , BattleRank
  , CoreCardState (..)
  , PlannedAction (..)
  , plannedActionCards
  )
import Frontend.Card (CardDisplayMode (..), CardSettings (..), renderCoreCardWith)
import Frontend.Game.Class
import Frontend.Game.PlannedAction (plannedActionWidget)
import Frontend.Game.Planning
import Frontend.Game.Staging (StagingEvents (..), stagingWidget)
import Frontend.Icons (iconSkipForward)
import Frontend.UI.Button (ButtonConfig (..), ButtonSize (..), ButtonVariant (..), button)

import Api.Request qualified as Req
import Api.Types (Phase (..))

import Frontend.Style qualified as FS
import Frontend.Style.Common (Style, classNames, componentS, divS, textGoldBright)
import Frontend.Style.DSL qualified as S
import Frontend.Util (buildStableKeyMap, dynE)

-- | Styles for hand card hover interactions (transformer style)
cardHoverStyle :: Style
cardHoverStyle =
  S.transitionTransform
    <> S.duration200
    <> S.easeOut
    <> S.originBottom
    <> S.hover S.translateYNeg8
    <> S.hover (S.z 40)
    <> S.cursorPointer

-- | Styles for cards in staging mode (resource candidates)
resourceCandidateStyle :: Style
resourceCandidateStyle =
  S.hover S.translateYNeg4
    <> S.hover S.ring2
    <> S.hover (S.ring S.Amber 5)
    <> S.cursorPointer

handWidget
  :: (GameWidget t m, MonadIO m)
  => Maybe StagingState
  -- ^ Optional initial staging state
  -> Event t BattleRank
  -- ^ Start rank move staging
  -> Dynamic t (Identified ActorId ActorState)
  -> m (Dynamic t (Maybe StagingState), Dynamic t (Maybe RankMoveStaging))
handWidget mInitialStaging rankMoveClickEvt actorDyn = do
  let safeActor = (.content) <$> actorDyn
      actorId = (.id) <$> actorDyn
      handDyn = (.coreState.hand) <$> safeActor

  phaseDyn <- askPhase
  keyMapDyn <- buildStableKeyMap (.id) handDyn

  rec (stagingState, validation) <-
        mkPlanBuilderLogic
          mInitialStaging
          safeActor
          selectEvt
          toggleEvt
          (leftmost [clearEvt, void rankMoveClickEvt])

      -- Rank Move Staging logic
      let rankMoveUpdateEvt =
            leftmost
              [ StartRankMove <$> rankMoveClickEvt
              , SelectDiscardId <$> discardEvt
              , ClearRankMove <$ cancelRankMoveEvt
              , ClearRankMove <$ commitRankMoveEvt
              , ClearRankMove <$ selectEvt
              ]
      rankMoveStaging <- foldDyn applyRankMoveUpdate Nothing rankMoveUpdateEvt

      -- Derived View Models
      let plannedActionDyn = (.coreState.planned) <$> safeActor
          stagingStackDyn = zipDynWith buildStagingStack safeActor stagingState

      -- Render UI
      (selectEvt, toggleEvt, discardEvt, cancelRankMoveEvt, commitRankMoveEvt, clearEvt) <-
        divS
          ( S.absolute
              <> S.bottom0
              <> S.left0
              <> S.right0
              <> S.pointerEventsNone
              <> S.z 40
              <> S.flex
              <> S.justifyBetween
              <> S.itemsEnd
              <> S.wFull
              <> S.px S.S8
              <> S.pb S.S4
          )
          $ do
            -- Layer 1: Main Layout (Flex Row) merged into parent
            (sel, tog, disc, overlayEvts, rankMoveOverlayEvts) <- do
              -- Left: Planned Action or No Action Button
              noActionClick <- divS (S.flex1 <> S.flex <> S.justifyCenter) $ do
                dynE $ ffor ((,,,) <$> actorId <*> plannedActionDyn <*> stagingState <*> phaseDyn) $ \case
                  (_, Nothing, Nothing, Planning) -> do
                    button
                      def
                        { variant = VariantSecondary
                        , size = SizeMedium
                        , testId = Just "plan-no-action"
                        , extraStyle = S.pointerEventsAuto
                        }
                      $ divS (S.flex <> S.itemsCenter <> S.gap S.S2)
                      $ do
                        divS (S.w S.S4 <> S.h S.S4) iconSkipForward
                        text "No Action"
                  (aid, Just plan, _, _) -> do
                    plannedActionWidget (Identified aid plan)
                    return never
                  _ -> do
                    blank
                    return never

              -- Dispatch Pass request when "No Action" clicked
              let passReq = attachWith (\aid _ -> Req.Pass aid) (current actorId) noActionClick
              _ <- requestGame passReq

              -- Center: Hand & Staging Container
              (s, t, d, oEvts, rmsOverlay) <- divS (S.relative <> S.flexCol <> S.itemsCenter <> S.pointerEventsNone <> S.gap S.S4) $ do
                -- Layer 2: Action Staging Overlay
                o <- dyn $ ffor (zipDyn actorId stagingStackDyn) $ \case
                  (aid, Just stk) -> stagingWidget aid (constDyn stk) validation
                  _ -> return (StagingEvents never never never)

                -- Layer 2b: Rank Move Staging Overlay
                rmsOv <- dyn $ ffor (zipDyn actorId rankMoveStaging) $ \case
                  (aid, Just rms) -> rankMoveStagingWidget aid (constDyn rms) safeActor
                  _ -> return (never, never)

                -- Center: Hand Cards
                (handS, handT, handD) <-
                  handCardsWidget safeActor stagingStackDyn rankMoveStaging plannedActionDyn keyMapDyn

                return (handS, handT, handD, o, rmsOv)

              -- Right: Spacer
              divS S.flex1 blank

              return (s, t, d, oEvts, rmsOverlay)

            cancel <- switchHold never ((.cancel) <$> overlayEvts)
            unstageResource' <- switchHold never ((.unstage) <$> overlayEvts)
            commit <- switchHold never ((.commit) <$> overlayEvts)
            cancelRankMove <- switchHold never (fst <$> rankMoveOverlayEvts)
            commitRankMove <- switchHold never (snd <$> rankMoveOverlayEvts)

            return
              ( sel
              , leftmost [tog, unstageResource']
              , disc
              , cancelRankMove
              , commitRankMove
              , leftmost [cancel, commit]
              )

  return (stagingState, rankMoveStaging)

rankMoveStagingWidget
  :: (GameWidget t m)
  => ActorId
  -> Dynamic t RankMoveStaging
  -> Dynamic t ActorState
  -> m (Event t (), Event t ())
rankMoveStagingWidget actorId rmsDyn actorDyn = do
  componentS
    "rank-move-staging"
    FS.altarStagingPanel
    $ do
      -- Header / Status
      divS (S.flexCol <> S.itemsCenter <> S.gap S.S1) $ do
        divS
          ( S.cls "fantasy-font"
              <> S.textSm
              <> S.fontBold
              <> textGoldBright
              <> S.uppercase
              <> S.trackingWider
          )
          $ text "Plan Rank Move"
        divS (S.text S.Gray 3 <> S.textXs) $ do
          dyn_ $ ffor rmsDyn $ \rms ->
            text $ "Moving to " <> T.pack (show rms.targetRank)

      -- Selected Card to Discard
      divS (S.flex <> S.justifyCenter <> S.itemsCenter <> S.mt S.S2 <> S.mb S.S2) $ do
        let selectedCardDyn = ffor2 rmsDyn actorDyn $ \rms actor ->
              rms.selectedDiscardId >>= \cid -> find (\c -> c.id == cid) actor.coreState.hand

        dyn_ $ ffor selectedCardDyn $ \case
          Nothing ->
            divS
              ( S.border1
                  <> S.border S.Gray 7
                  <> S.css "border-dashed" "border-style" "dashed"
                  <> S.rounded
                  <> S.p S.S4
                  <> S.w (S.Vh 9.6)
                  <> S.h (S.Vh 13.4)
                  <> S.flex
                  <> S.itemsCenter
                  <> S.justifyCenter
                  <> S.text S.Gray 4
                  <> S.textCenter
                  <> S.textXs
              )
              $ text "Select a card from hand to discard"
          Just card -> do
            divS
              ( S.relative
                  <> S.w (S.Vh 9.6)
                  <> S.h (S.Vh 13.4)
                  <> FS.ringDiscard
                  <> S.rounded
                  <> S.overflowHidden
              )
              $ divS
                ( S.absolute
                    <> S.css "origin-top-left" "transform-origin" "top left"
                    <> S.css "scale-card" "transform" "scale(0.6)"
                )
              $ renderCoreCardWith (CardSettings CardFull) card.content

      -- Controls
      divS (S.flex <> S.gap S.S2 <> S.wFull) $ do
        let cfg = def{extraStyle = S.flex1, size = SizeSmall}
        cancelEvt <-
          button cfg{variant = VariantSecondary, testId = Just "rank-staging-cancel"} $ text "Cancel"

        let validDyn = isJust . (.selectedDiscardId) <$> rmsDyn
            commitDisabled = not <$> validDyn

        commitEvt <-
          button cfg{variant = VariantPrimary, disabled = commitDisabled, testId = Just "rank-staging-commit"} $
            text "Commit"

        -- Commit request logic
        let planReq =
              attachWithMaybe
                ( \(rms, aid) _ -> do
                    Req.PlanRankMove aid rms.targetRank <$> rms.selectedDiscardId
                )
                (current ((,) <$> rmsDyn <*> constDyn actorId))
                commitEvt
        _ <- requestGame planReq

        return (cancelEvt, commitEvt)

handCardsWidget
  :: (DomBuilder t m, PostBuild t m, MonadFix m, MonadHold t m)
  => Dynamic t ActorState
  -> Dynamic t (Maybe ActionStack)
  -- ^ Staging Stack (defines staging mode)
  -> Dynamic t (Maybe RankMoveStaging)
  -- ^ Rank Move Staging
  -> Dynamic t (Maybe PlannedAction)
  -- ^ Planned Action (defines hidden cards)
  -> Dynamic t (Map.Map CardInstanceId Int)
  -- ^ Stable sequence mappings for cards
  -> m (Event t CardInstanceId, Event t CardInstanceId, Event t CardInstanceId)
handCardsWidget actor stagingStack rankMoveStaging plannedAction keyMapDyn = do
  divS (S.flex <> S.justifyCenter <> S.itemsEnd <> S.px S.S4 <> S.pointerEventsAuto) $ do
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

    cardClicksDyn <- divS (S.flex <> S.itemsEnd <> S.transitionOpacity <> S.duration200) $ do
      listWithKey keyedHandMapDyn $ \_key cardDyn -> do
        let isCandidate = checkResourceCandidate <$> stagingStack <*> cardDyn
            isSelected = checkIsSelected <$> stagingStack <*> cardDyn
            isDiscardSelected = ffor2 rankMoveStaging cardDyn $ \rms card ->
              case rms of
                Just r -> r.selectedDiscardId == Just card.id
                Nothing -> False

        let finalClassDyn =
              ffor
                ( (,,,)
                    <$> isCandidate
                    <*> isSelected
                    <*> isDiscardSelected
                    <*> ((,) <$> stagingStack <*> rankMoveStaging)
                )
                $ \(cand, sel, discSel, (stk, rms)) ->
                  let
                    inStaging = isJust stk
                    inRankStaging = isJust rms
                    baseStyle = if cand then resourceCandidateStyle else cardHoverStyle

                    -- Interaction highlights
                    extraStyle
                      | inStaging = if sel then S.cls "staged-gold-ring" else mempty
                      | inRankStaging = if discSel then FS.ringDiscard else mempty
                      | otherwise = mempty
                   in
                    classNames $
                      S.relative <> cardHandWidth <> extraStyle <> baseStyle <> S.pointerEventsAuto <> S.group

        (e, _) <- elDynAttr' "div" (fmap ("class" =:) finalClassDyn) $ do
          dyn_ $ ffor cardDyn $ renderCoreCardWith (CardSettings CardFull) . (.content)

        let effectiveClick = domEvent Click e

        return (effectiveClick, cardDyn)

    let clickEventsMapDyn =
          ffor cardClicksDyn $ \m ->
            Map.elems $ Map.mapWithKey (\_ (clickEvt, cardDyn) -> tag (current (fmap (.id) cardDyn)) clickEvt) m
        flatClickId = switchDyn (leftmost <$> clickEventsMapDyn)

    -- Select Action Event: Only fires when NEITHER action staging nor rank move staging is active
    let selectEvent =
          attachWithMaybe
            (\(stk, rms) cid -> if isJust stk || isJust rms then Nothing else Just cid)
            (current ((,) <$> stagingStack <*> rankMoveStaging))
            flatClickId

    -- Toggle Event: Only fires when IN staging mode
    let toggleEvent =
          attachWithMaybe
            (\stk cid -> if isJust stk then Just cid else Nothing)
            (current stagingStack)
            flatClickId

    -- Select Discard Event: Only fires when rank move staging is active
    let discardEvent =
          attachWithMaybe
            (\rms cid -> if isJust rms then Just cid else Nothing)
            (current rankMoveStaging)
            flatClickId

    return (selectEvent, toggleEvent, discardEvent)

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
