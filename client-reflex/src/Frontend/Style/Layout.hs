{-# LANGUAGE OverloadedStrings #-}

-- | Layout combinators and utilities.
module Frontend.Style.Layout
  ( -- * Layout Combinators
    row
  , rowGap
  , rowWith
  , col
  , colGap
  , colWith
  , spacer
  , overlay
  , overlayBottom
  , overlayBottomWith

    -- * Grid Layouts
  , cardPrintGrid
  , cardGrid
  , deckGrid
  ) where

import Reflex.Dom.Core

import Frontend.Style.Common

--------------------------------------------------------------------------------

-- * Layout Combinators

--------------------------------------------------------------------------------

-- | A horizontal flex container.
row :: (DomBuilder t m) => m a -> m a
row = divStyle [flex, flexRow]

-- | A horizontal flex container with a gap.
rowGap :: (DomBuilder t m) => CssClass -> m a -> m a
rowGap gap = divStyle [flex, flexRow, gap]

-- | A horizontal flex container with arbitrary classes.
rowWith :: (DomBuilder t m) => [CssClass] -> m a -> m a
rowWith cls = divStyle ([flex, flexRow] <> cls)

-- | A vertical flex container.
col :: (DomBuilder t m) => m a -> m a
col = divStyle [flex, flexCol]

-- | A vertical flex container with a gap.
colGap :: (DomBuilder t m) => CssClass -> m a -> m a
colGap gap = divStyle [flex, flexCol, gap]

-- | A vertical flex container with arbitrary classes.
colWith :: (DomBuilder t m) => [CssClass] -> m a -> m a
colWith cls = divStyle ([flex, flexCol] <> cls)

-- | A growing spacer element.
spacer :: (DomBuilder t m) => m ()
spacer = divStyle [grow] blank

-- | Full-size overlay container.
overlay :: (DomBuilder t m) => m a -> m a
overlay = divStyle [absolute, "inset-0"]

-- | Bottom-anchored overlay.
overlayBottom :: (DomBuilder t m) => m a -> m a
overlayBottom = divStyle [absolute, "bottom-0", "left-0", "right-0"]

-- | Bottom-anchored overlay with additional classes.
overlayBottomWith :: (DomBuilder t m) => [CssClass] -> m a -> m a
overlayBottomWith cls = divStyle ([absolute, "bottom-0", "left-0", "right-0"] <> cls)

--------------------------------------------------------------------------------

-- * Grid Layouts

--------------------------------------------------------------------------------

-- | Grid for printable cards (3x3 on standard paper).
cardPrintGrid :: [CssClass]
cardPrintGrid = [flex, "flex-wrap", "gap-0"]

-- | Responsive grid for card display.
cardGrid :: [CssClass]
cardGrid = [flex, "flex-wrap", "gap-[4mm]"]

-- | Grid for deck viewing.
deckGrid :: [CssClass]
deckGrid = [flex, "flex-wrap", "gap-4", "content-start"]
