{-# LANGUAGE OverloadedStrings #-}

-- | Thin wrapper around Reflex.AtomicCss.Common that exposes generic element helpers
-- alongside CardPG game-specific icon and text styles.
module Frontend.Style.Common
  ( module Reflex.AtomicCss.Common

    -- * Composite Styles (multi-atom combinations)
  , iconBlock
  , iconResponsive
  , iconInline
  , resourceIcon
  , resourceTextBase
  , resourceTextPrint
  , textGoldBright
  , textGoldMuted
  , textCrimsonLight
  , bgCrimsonDim
  , textEmerald
  ) where

import Frontend.Style.DSL qualified as S
import Reflex.AtomicCss.Common

--------------------------------------------------------------------------------
-- Composite Styles (multi-atom combinations)
--------------------------------------------------------------------------------

-- | Block icon style (fixed size)
iconBlock :: Style
iconBlock = S.w (S.Rem 2.5) . S.h (S.Rem 2.5) . S.fontBold . S.textXl

-- | Responsive icon (percentage height)
iconResponsive :: Style
iconResponsive =
  S.css "h-30pct" "height" "30%"
    . S.css "w-auto" "width" "auto"
    . S.aspectSquare
    . S.fontBold

-- | Inline icon (fits text line height)
iconInline :: Style
iconInline =
  S.inlineBlock
    . S.css "h-0.8em" "height" "0.8em"
    . S.css "w-auto" "width" "auto"
    . S.alignTextBottom

-- | Resource icon size
resourceIcon :: Style
resourceIcon = S.w S.S4 . S.h S.S4

-- | Resource text base (bold, light gray for screen)
resourceTextBase :: Style
resourceTextBase = S.fontBold . S.text S.Gray 2

-- | Resource text for print (black/dark gray)
resourceTextPrint :: Style
resourceTextPrint = S.media "print" S.textBlack

textGoldBright :: Style
textGoldBright = S.css "text-gold-bright" "color" "var(--color-gold-bright)"

textGoldMuted :: Style
textGoldMuted = S.css "text-gold-muted" "color" "var(--color-gold-muted)"

textCrimsonLight :: Style
textCrimsonLight = S.css "text-crimson-light" "color" "#fca5a5"

bgCrimsonDim :: Style
bgCrimsonDim = S.css "bg-crimson-dim" "background-color" "rgba(153, 27, 27, 0.4)"

textEmerald :: Style
textEmerald = S.css "text-emerald" "color" "#10b981"
