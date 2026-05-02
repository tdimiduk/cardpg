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
import Frontend.Game.Common (staticActionStackWidget)
import Frontend.Style (cardHandWidth)
import Frontend.Style.Common (Style, classNames, divS, elS, elS', testId)
import Frontend.Style.DSL qualified as S
import Frontend.Style.Layout
import Frontend.UI.Button

-- | "PLANNED" badge styling
plannedBadge :: Style
plannedBadge =
  S.absolute
    . S.css "-top-3" "top" "-0.75rem"
    . S.css "left-1/2" "left" "50%"
    . S.css "-translate-x-1/2" "transform" "translateX(-50%)"
    . (S.bg S.Indigo 8)
    . S.textWhite
    . S.css "text-[10px]" "font-size" "10px"
    . S.uppercase
    . S.fontBold
    . S.px 2
    . S.css "py-0.5" "padding-block" "0.125rem"
    . S.rounded
    . S.shadowXl
    . S.css "z-50" "z-index" "50"

-- | Action card hover effect
actionCardHover :: Style
actionCardHover =
  S.z 20 . S.shadow2Xl . S.scale105 . S.transitionTransform

-- | Card hover for narrative stacks
narrativeCardHover :: Style
narrativeCardHover = S.relative . S.z 10 . S.transitionTransform

plannedActionWidget
  :: ( DomBuilder t m
     , PostBuild t m
     , MonadHold t m
     , MonadFix m
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
    PStandard (ActionStack action resources) -> do
      void $
        staticActionStackWidget
          ( \r -> do
              (eRes, _) <-
                elS' "div" (cardHandWidth . S.shrink0 . S.transitionAll) Map.empty $
                  renderCoreCardWith (CardSettings CardFull) r.content
              return (tag (constant r.id) (domEvent Click eRes))
          )
          ( \a -> do
              (eAct, _) <- elS'
                "div"
                ((S.relative . cardHandWidth . S.shrink0) . actionCardHover)
                (testId "planned-action-card")
                $ do
                  renderCoreCard a.content
                  divS plannedBadge $ text "PLANNED"
              return (domEvent Click eAct)
          )
          resources
          action
    PNarrative (NarrativeStack cards _color) -> do
      rowGap (S.css "-space-x-8" "margin-left" "-2rem") $
        mapM_ (divS narrativeCardHover . renderCoreCard . (.content)) cards
    PPass -> do
      divS ((S.text S.Gray 4) . S.css "italic" "font-style" "italic" . S.textSm) $ text "Passed turn"
  where
    colStyle = S.gap 4 . S.itemsCenter . S.pointerEventsAuto
