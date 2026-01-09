module Frontend.Game.PlannedAction where

import Control.Monad (forM_)
import Reflex.Dom.Core

import Core.State (ActionStack (..), NarrativeStack (..), PlannedAction (..))

import Frontend.Card (CardDisplayMode (..), CardSettings (..))
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

plannedActionWidget :: (DomBuilder t m) => PlannedAction -> m (Event t ())
plannedActionWidget planned = case planned of
  PStandard (ActionStack action res) -> do
    colWith ["gap-2", itemsCenter] $ do
      -- Revise Button
      (e, _) <- elStyle' "button" buttonRevise $ text "↺ Revise"

      -- Stack container
      rowWith ["items-stretch", plannedCardOverlap] $ do
        -- Resources (vertical strips)
        forM_ res $ \r -> do
          divStyle [cardHandWidth, "shrink-0", "transition-all", "hover:z-10"] $
            renderWith (CardSettings CardFull) r

        -- Action card (top)
        divStyle [relative, cardHandWidth, "shrink-0"] $ do
          divStyle actionCardHover $ render action
          divStyle plannedBadge $ text "PLANNED"

      return (domEvent Click e)
  PNarrative (NarrativeStack cards _color) -> do
    colWith ["gap-2", itemsCenter] $ do
      (e, _) <- elStyle' "button" buttonRevise $ text "↺ Revise"
      rowGap "-space-x-8" $
        mapM_ (divStyle narrativeCardHover . render) cards
      return (domEvent Click e)
  PPass -> do
    colWith ["gap-2", itemsCenter] $ do
      (e, _) <- elStyle' "button" buttonRevise $ text "↺ Revise"
      divStyle ["text-slate-500", "italic", textSm] $ text "Passed turn"
      return (domEvent Click e)
