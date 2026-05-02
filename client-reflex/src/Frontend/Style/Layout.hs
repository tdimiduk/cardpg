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

import Frontend.Style.Common (Style, divS)
import Frontend.Style.DSL qualified as S

--------------------------------------------------------------------------------

-- * Layout Combinators

--------------------------------------------------------------------------------

-- | A horizontal flex container.
row :: (DomBuilder t m) => m a -> m a
row = divS S.flexRow

-- | A horizontal flex container with a gap.
rowGap :: (DomBuilder t m) => Style -> m a -> m a
rowGap gap = divS (S.flexRow . gap)

-- | A horizontal flex container with arbitrary styles.
rowWith :: (DomBuilder t m) => Style -> m a -> m a
rowWith s = divS (S.flexRow . s)

-- | A vertical flex container.
col :: (DomBuilder t m) => m a -> m a
col = divS S.flexCol

-- | A vertical flex container with a gap.
colGap :: (DomBuilder t m) => Style -> m a -> m a
colGap gap = divS (S.flexCol . gap)

-- | A vertical flex container with arbitrary styles.
colWith :: (DomBuilder t m) => Style -> m a -> m a
colWith s = divS (S.flexCol . s)

-- | A growing spacer element.
spacer :: (DomBuilder t m) => m ()
spacer = divS S.grow blank

-- | Full-size overlay container.
overlay :: (DomBuilder t m) => m a -> m a
overlay = divS (S.absolute . S.inset0)

-- | Bottom-anchored overlay.
overlayBottom :: (DomBuilder t m) => m a -> m a
overlayBottom = divS (S.absolute . S.bottom0 . S.left0 . S.right0)

-- | Bottom-anchored overlay with additional styles.
overlayBottomWith :: (DomBuilder t m) => Style -> m a -> m a
overlayBottomWith s = divS (S.absolute . S.bottom0 . S.left0 . S.right0 . s)

--------------------------------------------------------------------------------

-- * Grid Layouts

--------------------------------------------------------------------------------

-- | Grid for printable cards (3x3 on standard paper).
cardPrintGrid :: Style
cardPrintGrid = S.flex . S.flexWrap . S.gap 0

-- | Responsive grid for card display.
cardGrid :: Style
cardGrid = S.flex . S.flexWrap . S.gap4mm

-- | Grid for deck viewing.
deckGrid :: Style
deckGrid = S.flex . S.flexWrap . S.gap 4 . S.contentStart
