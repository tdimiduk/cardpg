{-# LANGUAGE OverloadedStrings #-}

module Frontend.Game.Staging where

import Control.Monad.Fix (MonadFix)
import Reflex.Dom.Core hiding (button)

import Api.Request (ApiRequest)
import Api.Request qualified as Req

import Core.Card (CoreCard (..), Identified (..))
import Core.Logic.Planning (PlanValidation (..))
import Core.Primitives (ActorId, CardInstanceId)
import Core.State (ActionStack (..))
import Core.Util (tshow)

import Data.Monoid (Sum (..))
import Frontend.Card
  ( CardDisplayMode (..)
  , CardSettings (..)
  , StatsDisplayMode (..)
  , StatsSettings (..)
  , renderCoreCardWith
  , renderStatsWith
  )
import Frontend.Game.Common (cardStackWidget)
import Frontend.Render.Common (IconMode (..))
import Frontend.Style (stagedActionCard, stagedResourceCard)
import Frontend.Style.Common
import Frontend.Style.DSL qualified as S

import Frontend.UI.Button

data StagingEvents t = StagingEvents
  { cancel :: Event t ()
  , unstage :: Event t CardInstanceId
  , commit :: Event t ()
  }

-- | The Staging Widget handles the UI for building a plan (ACTION + RESOURCE + TARGETS)
-- It appears as an overlay when an action card is selected.
stagingWidget
  :: ( DomBuilder t m
     , PostBuild t m
     , MonadHold t m
     , MonadFix m
     , Requester t m
     , Request m ~ ApiRequest
     )
  => ActorId
  -> Dynamic t ActionStack
  -> Dynamic t PlanValidation
  -> m (StagingEvents t)
stagingWidget actorId actionStackDyn validation = do
  -- Staging UI Container
  componentS
    "action-staging"
    ( S.flexCol
        . S.absolute
        . S.css "bottom-80" "bottom" "20rem"
        . S.css "left-1/2" "left" "50%"
        . S.css "-translate-x-1/2" "transform" "translateX(-50%)"
        . S.pointerEventsAuto
        . S.itemsCenter
        . S.gap 2 -- gap-3 doesn't exist? Using gap 2 or atom "gap-3" "gap" "0.75rem"
        -- DSL2 has gap 2 (0.5rem), gap 4 (1rem). gap-3 is 0.75rem.
        -- I'll use S.css "gap-3" "gap" "0.75rem" or stick to gap 2/gap 4.
        -- Original was "gap-3".
        . S.css "gap-3" "gap" "0.75rem"
        . S.css "min-w-[320px]" "min-width" "320px"
        . S.css "bg-slate-900/90" "background-color" "rgb(15 23 42 / 0.9)"
        . S.backdropBlurMd
        . S.border1
        . (S.border S.Gray 9)
        . S.rounded3Xl
        . S.p 4
        . S.shadow2Xl
    )
    $ do
      -- Header / Status
      stagingStatusHeader validation

      -- Live Stat Totals
      stagingStats actionStackDyn

      -- Staged Cards Row
      (clickAction, clickResource) <- stagedCardsRow actionStackDyn

      -- Controls
      (cancelClick, commitClick) <- stagingControls validation

      -- Commit Request logic
      let planReq =
            attachWith
              ( \inputStack _ ->
                  Req.PlanAction actorId inputStack.actionCard.id (map (.id) inputStack.resources)
              )
              (current actionStackDyn)
              commitClick

      _ <- requesting planReq

      -- Combine cancels (Clicking the ACTION card also cancels/unstages it)
      return $
        StagingEvents
          { cancel = leftmost [cancelClick, clickAction]
          , unstage = clickResource
          , commit = commitClick
          }

stagingStatusHeader
  :: (DomBuilder t m, PostBuild t m)
  => Dynamic t PlanValidation
  -> m ()
stagingStatusHeader validation = do
  divS (S.flexCol . S.itemsCenter . S.gap 2) $ do
    elAttr "div" (testId "staging-status") $ do
      text "Preparing Action"
      dyn_ $ ffor validation $ \case
        PlanIncomplete cost provided -> text $ " " <> tshow provided <> "/" <> tshow cost
        PlanValid _ -> text " ✅"
        _ -> blank

stagedCardsRow
  :: (DomBuilder t m, PostBuild t m, MonadHold t m, MonadFix m)
  => Dynamic t ActionStack
  -> m (Event t (), Event t CardInstanceId)
stagedCardsRow actionStackDyn = do
  divS (S.flex . S.justifyCenter) $ do
    -- Extract resources and action from the ActionStack dynamic
    let stagedResourcesDyn = fmap (.resources) actionStackDyn
        stagedActionDyn = fmap (.actionCard) actionStackDyn

    (clickResource, clickAction) <-
      cardStackWidget
        ( \rDyn -> do
            let stagedResourceCls = classNames stagedResourceCard
            (eRes, _) <- elDynAttr'
              "div"
              (constDyn ("class" =: stagedResourceCls <> testId "staged-resource"))
              $ do
                dyn_ $ fmap (renderCoreCardWith (CardSettings CardFull) . (.content)) rDyn
            return (switchDyn $ fmap (\r -> tag (constant r.id) (domEvent Click eRes)) rDyn)
        )
        ( \aDyn -> do
            let stagedActionCls = classNames stagedActionCard
            (eAct, _) <- elDynAttr'
              "div"
              (constDyn ("class" =: stagedActionCls <> testId "staged-action"))
              $ do
                dyn_ $ fmap (renderCoreCardWith (CardSettings CardFull) . (.content)) aDyn
            return (domEvent Click eAct)
        )
        stagedResourcesDyn
        stagedActionDyn
    return (clickAction, clickResource)

stagingControls
  :: (DomBuilder t m, PostBuild t m)
  => Dynamic t PlanValidation
  -> m (Event t (), Event t ())
stagingControls validation = do
  divS (S.flex . S.gap 2 . S.wFull) $ do
    let cfg = def{extraStyle = S.flex1, size = constDyn SizeSmall}
    -- Cancel Button (Secondary)
    cancelEvt <-
      button cfg{variant = constDyn VariantSecondary, testId = Just "staging-cancel"} $ text "Cancel"

    -- Commit Button (Primary, disabled if invalid)
    let validDyn = ffor validation $ \case PlanValid _ -> True; _ -> False
        commitDisabled = not <$> validDyn

    commitEvt <-
      button
        cfg{variant = constDyn VariantPrimary, disabled = commitDisabled, testId = Just "staging-commit"}
        $ text "Commit"

    return (cancelEvt, commitEvt)

stagingStats
  :: (DomBuilder t m, PostBuild t m)
  => Dynamic t ActionStack
  -> m ()
stagingStats stackDyn = do
  let totalStats = ffor stackDyn $ \planStack ->
        let toSum = fmap Sum
            fromSum = fmap getSum
            actionStats = toSum planStack.actionCard.content.stats
            resStats = mconcat $ map (toSum . (.content.stats)) planStack.resources
         in fromSum (actionStats <> resStats)

  divS (S.flex . S.gap 2 . S.itemsCenter . S.textWhite) $ do
    dyn_ $ ffor totalStats $ \s ->
      renderStatsWith (StatsSettings StatsRow IconBlock) s
