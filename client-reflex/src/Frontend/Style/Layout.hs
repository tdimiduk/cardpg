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

import Frontend.Style.Class (StyledDomBuilder)
import Frontend.Style.Common
  ( Style
  , divT
  )
import Frontend.Style.DSL qualified as S

--------------------------------------------------------------------------------

-- * Layout Combinators

--------------------------------------------------------------------------------

-- | A horizontal flex container.
-- | A horizontal flex container.
row :: (StyledDomBuilder t m) => m a -> m a
row = divT S.flexRow

-- | A horizontal flex container with a gap.
rowGap :: (StyledDomBuilder t m) => Style -> m a -> m a
rowGap gap = divT (S.flexRow . gap)

-- | A horizontal flex container with arbitrary styles.
rowWith :: (StyledDomBuilder t m) => Style -> m a -> m a
rowWith s = divT (S.flexRow . s)

-- | A vertical flex container.
col :: (StyledDomBuilder t m) => m a -> m a
col = divT S.flexCol

-- | A vertical flex container with a gap.
colGap :: (StyledDomBuilder t m) => Style -> m a -> m a
colGap gap = divT (S.flexCol . gap)

-- | A vertical flex container with arbitrary styles.
colWith :: (StyledDomBuilder t m) => Style -> m a -> m a
colWith s = divT (S.flexCol . s)

-- | A growing spacer element.
spacer :: (StyledDomBuilder t m) => m ()
spacer = divT S.grow blank

-- | Full-size overlay container.
overlay :: (StyledDomBuilder t m) => m a -> m a
overlay = divT (S.absolute . S.inset0)

-- | Bottom-anchored overlay.
overlayBottom :: (StyledDomBuilder t m) => m a -> m a
overlayBottom = divT (S.absolute . S.bottom0 . S.left0 . S.right0)

-- | Bottom-anchored overlay with additional styles.
overlayBottomWith :: (StyledDomBuilder t m) => Style -> m a -> m a
overlayBottomWith s = divT (S.absolute . S.bottom0 . S.left0 . S.right0 . s)

--------------------------------------------------------------------------------

-- * Grid Layouts

--------------------------------------------------------------------------------

-- | Grid for printable cards (3x3 on standard paper).
cardPrintGrid :: Style
cardPrintGrid = S.flex . S.flexWrap . S.gap0

-- | Responsive grid for card display.
cardGrid :: Style
cardGrid = S.flex . S.flexWrap . S.gap4mm

-- | Grid for deck viewing.
deckGrid :: Style
deckGrid = S.flex . S.flexWrap . S.gap4 . S.contentStart
