{-# LANGUAGE DataKinds #-}

module Frontend.Game.PlannedAction
  ( plannedActionWidget
  ) where

import Control.Monad (void)
import Control.Monad.Fix (MonadFix)
import Reflex.Dom.Core hiding (button)

import Api.Request (ApiRequest)
import Api.Request qualified as Req

import Core.Card (Identified (..))
import Core.Primitives (ActorId)
import Core.State (ActionStack (..), NarrativeStack (..), PlannedAction (..))

import Frontend.Card (CardDisplayMode (..), CardSettings (..))
import Frontend.Game.Common (cardStackWidget)
import Frontend.Html (Render (..), RenderHtml)
import Frontend.Style hiding (classes)
import Frontend.UI.Button

-- | "PLANNED" badge styling
plannedBadge :: [CssClass]
plannedBadge =
  [ absolute
  , "-top-3"
  , "left-1/2"
  , "-translate-x-1/2"
  , "bg-indigo-600"
  , "text-white"
  , "text-[10px]"
  , "uppercase"
  , fontBold
  , "px-2"
  , "py-0.5"
  , rounded
  , shadowXl
  , "z-50"
  ]

-- | Action card hover effect
actionCardHover :: [CssClass]
actionCardHover =
  ["z-20", "shadow-2xl", "hover:scale-105", "transition-transform"]

-- | Card hover for narrative stacks
narrativeCardHover :: [CssClass]
narrativeCardHover =
  [relative, "z-10", "hover:z-20", "transform", "hover:-translate-y-2", "transition-transform"]

plannedActionWidget
  :: ( DomBuilder t m
     , PostBuild t m
     , MonadHold t m
     , MonadFix m
     , Requester t m
     , Request m ~ ApiRequest
     , RenderHtml m
     )
  => Identified ActorId PlannedAction
  -> m ()
plannedActionWidget (Identified actorId planned) = colWith colStyle $ do
  e <- button def{variant = constDyn VariantDestructive} $ text "↺ Revise"
  _ <- requesting $ Req.CancelPlan actorId <$ e
  case planned of
    PStandard (ActionStack action res) -> do
      void $
        cardStackWidget
          ( \rDyn -> do
              (eRes, _) <-
                elStyle' "div" [cardHandWidth, "shrink-0", "transition-all", "hover:z-10"] $
                  dyn_ $
                    fmap (renderWith (CardSettings CardFull)) rDyn
              return (tag (current (fmap (.id) rDyn)) (domEvent Click eRes))
          )
          ( \aDyn -> do
              (eAct, _) <- elStyle' "div" ([relative, cardHandWidth, "shrink-0"] ++ actionCardHover) $ do
                dyn_ $ fmap render aDyn
                divStyle plannedBadge $ text "PLANNED"
              return (domEvent Click eAct)
          )
          (constDyn res)
          (constDyn action)
    PNarrative (NarrativeStack cards _color) -> do
      rowGap "-space-x-8" $
        mapM_ (divStyle narrativeCardHover . render) cards
    PPass -> do
      divStyle ["text-slate-500", "italic", textSm] $ text "Passed turn"
  where
    colStyle = ["gap-5", itemsCenter, pointerEventsAuto]
