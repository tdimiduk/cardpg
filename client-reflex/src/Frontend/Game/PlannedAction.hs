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
import Frontend.Game.Class
import Frontend.Game.Common (staticActionStackWidget)
import Frontend.Style (cardHandWidth)
import Frontend.Style.Common (Style, divS, elS', testId)
import Frontend.Style.DSL qualified as S
import Frontend.Style.Layout
import Frontend.UI.Button

-- | "PLANNED" badge styling
plannedBadge :: Style
plannedBadge =
  S.absolute
    . S.top (S.Rem (-0.75))
    . S.left (S.Percent 50)
    . S.css "-translate-x-1/2" "transform" "translateX(-50%)"
    . S.bg S.Indigo 8
    . S.textWhite
    . S.css "text-[10px]" "font-size" "10px"
    . S.uppercase
    . S.fontBold
    . S.px S.S2
    . S.py S.S0_5
    . S.rounded
    . S.shadowXl
    . S.z 50

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
     , MonadGame t m
     )
  => Identified ActorId PlannedAction
  -> m ()
plannedActionWidget (Identified actorId planned) = colWith colStyle $ do
  e <-
    button
      def{variant = constDyn VariantDestructive, attributes = constDyn (testId "revise-action")}
      $ text "↺ Revise"
  _ <- requestGame $ Req.CancelPlan actorId <$ e
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
      rowGap (S.ml (S.Rem (-2))) $
        mapM_ (divS (narrativeCardHover . cardHandWidth) . renderCoreCard . (.content)) cards
    PPass -> do
      divS (S.text S.Gray 4 . S.css "italic" "font-style" "italic" . S.textSm) $ text "Passed turn"
  where
    colStyle = S.gap S.S4 . S.itemsCenter . S.pointerEventsAuto
