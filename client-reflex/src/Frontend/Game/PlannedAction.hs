{-# LANGUAGE OverloadedRecordDot #-}

module Frontend.Game.PlannedAction
  ( plannedActionWidget
  ) where

import Control.Monad (void)
import Control.Monad.Fix (MonadFix)
import Reflex.Dom.Core hiding (button)

import Api.Request (ApiRequest)
import Api.Request qualified as Req
import Data.Map qualified as Map

import Core.Card (Identified (..))
import Core.Primitives (ActorId)
import Core.State (ActionStack (..), NarrativeStack (..), PlannedAction (..))

import Frontend.Card (CardDisplayMode (..), CardSettings (..), renderCoreCard, renderCoreCardWith)
import Frontend.Game.Common (cardStackWidget)
import Frontend.Style (cardHandWidth)
import Frontend.Style.Class (MonadStyle)
import Frontend.Style.Common (Style, classes, divT, elT, elT', testId)
import Frontend.Style.DSL qualified as S
import Frontend.Style.Layout
import Frontend.UI.Button

-- | "PLANNED" badge styling
plannedBadge :: Style
plannedBadge =
  S.absolute
    . S.atom "-top-3" "top" "-0.75rem"
    . S.atom "left-1/2" "left" "50%"
    . S.atom "-translate-x-1/2" "transform" "translateX(-50%)"
    . S.bgIndigo600
    . S.textWhite
    . S.atom "text-[10px]" "font-size" "10px"
    . S.uppercase
    . S.fontBold
    . S.px2
    . S.atom "py-0.5" "padding-block" "0.125rem"
    . S.rounded
    . S.shadowXl
    . S.atom "z-50" "z-index" "50"

-- | Action card hover effect
actionCardHover :: Style
actionCardHover =
  S.z20 . S.shadow2Xl . S.scale105 . S.transitionTransform

-- | Card hover for narrative stacks
narrativeCardHover :: Style
narrativeCardHover = S.relative . S.z10 . S.transitionTransform

plannedActionWidget
  :: ( DomBuilder t m
     , PostBuild t m
     , MonadHold t m
     , MonadFix m
     , MonadStyle m
     , Requester t m
     , Request m ~ ApiRequest
     )
  => Identified ActorId PlannedAction
  -> m ()
plannedActionWidget (Identified actorId planned) = colWith colStyle $ do
  e <-
    button
      def{variant = constDyn VariantDestructive, attributes = constDyn (testId "revise-action")}
      $ text "↺ Revise"
  _ <- requesting $ Req.CancelPlan actorId <$ e
  case planned of
    PStandard (ActionStack action res) -> do
      void $
        cardStackWidget
          ( \rDyn -> do
              (eRes, _) <-
                elT' "div" (cardHandWidth . S.shrink0 . S.transitionAll) Map.empty $
                  dyn_ $
                    fmap (renderCoreCardWith (CardSettings CardFull) . (.content)) rDyn
              return (tag (current (fmap (.id) rDyn)) (domEvent Click eRes))
          )
          ( \aDyn -> do
              (eAct, _) <- elT'
                "div"
                ((S.relative . cardHandWidth . S.shrink0) . actionCardHover)
                (testId "planned-action-card")
                $ do
                  dyn_ $ fmap (renderCoreCard . (.content)) aDyn
                  divT plannedBadge $ text "PLANNED"
              return (domEvent Click eAct)
          )
          (constDyn res)
          (constDyn action)
    PNarrative (NarrativeStack cards _color) -> do
      rowGap (S.atom "-space-x-8" "margin-left" "-2rem") $
        mapM_ (divT narrativeCardHover . renderCoreCard . (.content)) cards
    PPass -> do
      divT (S.textSlate400 . S.atom "italic" "font-style" "italic" . S.textSm) $ text "Passed turn"
  where
    colStyle = S.gap4 . S.itemsCenter . S.pointerEventsAuto
