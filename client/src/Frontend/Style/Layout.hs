-- | Thin wrapper around Reflex.AtomicCss.Layout that exposes generic layout helpers
-- alongside CardPG game-specific grid definitions.
module Frontend.Style.Layout
  ( module Reflex.AtomicCss.Layout

    -- * Grid Layouts
  , cardPrintGrid
  , cardGrid
  , deckGrid
  ) where

import Frontend.Style.Common (Style)
import Frontend.Style.DSL qualified as S
import Reflex.AtomicCss.Layout

--------------------------------------------------------------------------------
-- Grid Layouts
--------------------------------------------------------------------------------

-- | Grid for printable cards (3x3 on standard paper).
cardPrintGrid :: Style
cardPrintGrid = S.flex . S.flexWrap . S.gap S.S0

-- | Responsive grid for card display.
cardGrid :: Style
cardGrid = S.flex . S.flexWrap . S.gap (S.Mm 4)

-- | Grid for deck viewing.
deckGrid :: Style
deckGrid = S.flex . S.flexWrap . S.gap S.S4 . S.contentStart
