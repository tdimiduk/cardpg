module Frontend.Game.PlannedAction
  ( plannedActionWidget
  ) where

import Control.Monad.Fix (MonadFix)
import Reflex.Dom.Core

import Api.Request (ApiRequest (..))
import Api.Types (Command (..))
import Core.Card (Identified (..))
import Core.Primitives (ActorId)
import Core.State (ActionStack (..), NarrativeStack (..), PlannedAction (..))

import Frontend.Card (CardDisplayMode (..), CardSettings (..))
import Frontend.Game.Common (cardStackWidget)
import Frontend.Html (Render (..))
import Frontend.Style hiding (classes)

-- | Revise button styling (appears in all planned action variants)
buttonRevise :: [CssClass]
buttonRevise =
  [ "text-red-400"
  , "hover:text-red-300"
  , "text-[10px]"
  , fontBold
  , "uppercase"
  , flex
  , itemsCenter
  , "gap-1"
  , "bg-slate-900/80"
  , "px-3"
  , "py-1"
  , "rounded-full"
  , "border"
  , "border-slate-700/50"
  , "backdrop-blur"
  , "transition-colors"
  ]

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
  :: (DomBuilder t m, PostBuild t m, MonadHold t m, MonadFix m, Requester t m, Request m ~ ApiRequest)
  => Identified ActorId PlannedAction
  -> m ()
plannedActionWidget (Identified actorId planned) = do
  case planned of
    PStandard (ActionStack action res) -> do
      colWith ["gap-2", itemsCenter, pointerEventsAuto] $ do
        -- Revise Button
        (e, _) <- elStyle' "button" buttonRevise $ text "↺ Revise"
        let reviseReq = GameAction $ CancelPlanIntent actorId
        _ <- requesting $ tag (constant reviseReq) (domEvent Click e)

        -- Stack container
        _ <-
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

        return ()
    PNarrative (NarrativeStack cards _color) -> do
      colWith ["gap-2", itemsCenter, pointerEventsAuto] $ do
        (e, _) <- elStyle' "button" buttonRevise $ text "↺ Revise"
        let reviseReq = GameAction $ CancelPlanIntent actorId
        _ <- requesting $ tag (constant reviseReq) (domEvent Click e)
        rowGap "-space-x-8" $
          mapM_ (divStyle narrativeCardHover . render) cards
        return ()
    PPass -> do
      colWith ["gap-2", itemsCenter, pointerEventsAuto] $ do
        (e, _) <- elStyle' "button" buttonRevise $ text "↺ Revise"
        let reviseReq = GameAction $ CancelPlanIntent actorId
        _ <- requesting $ tag (constant reviseReq) (domEvent Click e)
        divStyle ["text-slate-500", "italic", textSm] $ text "Passed turn"
        return ()
