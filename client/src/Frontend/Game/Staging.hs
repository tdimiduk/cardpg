{-# LANGUAGE OverloadedStrings #-}

module Frontend.Game.Staging where

import Control.Monad.Fix (MonadFix)
import Reflex.Dom.Core hiding (button)

import Api.Request qualified as Req

import Core.Card (CoreCard (..), Identified (..))
import Core.Logic.Planning (PlanValidation (..))
import Core.Primitives (ActorId, CardInstanceId)
import Core.State (ActionStack (..))
import Core.Util (tshow)

import Data.Map qualified as Map
import Data.Maybe (fromMaybe)
import Data.Monoid (Sum (..))
import Frontend.Card
  ( CardDisplayMode (..)
  , CardSettings (..)
  , StatsDisplayMode (..)
  , StatsSettings (..)
  , renderCoreCardWith
  , renderStatsWith
  )
import Frontend.Render.Common (IconMode (..))
import Frontend.Style
  ( altarStagingPanel
  , plannedCardOverlap
  , stagedActionCard
  , stagedResourceCard
  )
import Frontend.Style.Common
import Frontend.Style.DSL qualified as S
import Frontend.Style.Layout (rowWith)

import Frontend.Game.Class
import Frontend.Game.Planning (StableHandKey (..))
import Frontend.UI.Button
import Frontend.Util (buildStableKeyMap)

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
     , MonadGame t m
     )
  => ActorId
  -> Dynamic t ActionStack
  -> Dynamic t PlanValidation
  -> m (StagingEvents t)
stagingWidget actorId actionStackDyn validation = do
  -- Staging UI Container
  componentS
    "action-staging"
    altarStagingPanel
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

      _ <- requestGame planReq

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
  divS (S.flexCol <> S.itemsCenter <> S.gap S.S2) $ do
    elAttr
      "div"
      ( testId "staging-status"
          <> "class"
            =: classNames
              ( S.cls "fantasy-font"
                  <> S.textSm
                  <> S.fontBold
                  <> textGoldBright
                  <> S.uppercase
                  <> S.trackingWider
              )
      )
      $ do
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
  divS (S.flex <> S.justifyCenter) $ do
    let stagedResourcesDyn = fmap (.resources) actionStackDyn
        stagedActionDyn = fmap (.actionCard) actionStackDyn

    resourceKeyMapDyn <- buildStableKeyMap (.id) stagedResourcesDyn

    let stagedResourceMapDyn =
          ( \vis resourceKeys ->
              Map.fromList
                [ (StableHandKey (-seqNum) c.id, c)
                | c <- vis
                , let seqNum = fromMaybe 0 (Map.lookup c.id resourceKeys)
                ]
          )
            <$> stagedResourcesDyn
            <*> resourceKeyMapDyn

    rowWith (S.itemsCenter <> plannedCardOverlap) $ do
      clickResourceMapDyn <- listWithKey stagedResourceMapDyn $ \_key rDyn -> do
        let stagedResourceCls = classNames stagedResourceCard
        (eRes, _) <- elDynAttr'
          "div"
          (constDyn ("class" =: stagedResourceCls <> testId "staged-resource"))
          $ do
            dyn_ $ fmap (renderCoreCardWith (CardSettings CardFull) . (.content)) rDyn
        return (switchDyn $ fmap (\r -> tag (constant r.id) (domEvent Click eRes)) rDyn)

      let clickResource = switchDyn (leftmost . Map.elems <$> clickResourceMapDyn)

      -- Action card (top/right)
      let stagedActionCls = classNames stagedActionCard
      (eAct, _) <- elDynAttr'
        "div"
        (constDyn ("class" =: stagedActionCls <> testId "staged-action"))
        $ do
          dyn_ $ fmap (renderCoreCardWith (CardSettings CardFull) . (.content)) stagedActionDyn
      let clickAction = domEvent Click eAct

      return (clickAction, clickResource)

stagingControls
  :: (DomBuilder t m, PostBuild t m)
  => Dynamic t PlanValidation
  -> m (Event t (), Event t ())
stagingControls validation = do
  divS (S.flex <> S.gap S.S2 <> S.wFull) $ do
    let cfg = def{extraStyle = S.flex1, size = SizeSmall}
    -- Cancel Button (Secondary)
    cancelEvt <-
      button cfg{variant = VariantSecondary, testId = Just "staging-cancel"} $ text "Cancel"

    -- Commit Button (Primary, disabled if invalid)
    let validDyn = ffor validation $ \case PlanValid _ -> True; _ -> False
        commitDisabled = not <$> validDyn

    commitEvt <-
      button
        cfg{variant = VariantPrimary, disabled = commitDisabled, testId = Just "staging-commit"}
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

  divS (S.flex <> S.gap S.S2 <> S.itemsCenter <> S.textWhite) $ do
    dyn_ $ ffor totalStats $ \s ->
      renderStatsWith (StatsSettings StatsRow IconBlock) s
