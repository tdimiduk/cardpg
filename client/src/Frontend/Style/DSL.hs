{-# LANGUAGE OverloadedStrings #-}

-- | Thin wrapper around Reflex.AtomicCss.DSL that exposes generic atomic styles
-- alongside CardPG game-specific layout constants.
module Frontend.Style.DSL
  ( module Reflex.AtomicCss.DSL

    -- * Game Sizing & Layout
  , wCard
  , hCard
  , wCardHand
  , mlCardOverlap
  , spaceXActionStackOverlap
  , spaceXTuckedOverlap
  , originBottom
  , translateYNeg4
  , translateYNeg8
  , scale105
  , aspectCard
  , w8mm
  , h8mm
  , altarStagingPanel
  , ringDiscard

    -- * Theme Tokens
  , textGoldBright
  , textGoldMuted
  , borderGoldBright
  , borderGoldMuted
  , bgStoneDark
  , borderStoneMed

    -- * Tooltip & Popover Tokens
  , groupHoverBlock
  , bottomFull
  , topFull
  ) where

import Reflex.AtomicCss.Core (Style, css)
import Reflex.AtomicCss.DSL

wCard :: Style
wCard = w (Mm 63)

hCard :: Style
hCard = h (Mm 88)

wCardHand :: Style
wCardHand = w (Vh 16)

mlCardOverlap :: Style
mlCardOverlap = ml (Vh (-12))

spaceXActionStackOverlap :: Style
spaceXActionStackOverlap =
  customSelector
    "space-x-action-stack-overlap"
    ".space-x-action-stack-overlap > * + *"
    [("margin-left", "calc(var(--size-9) * -0.6)")]

spaceXTuckedOverlap :: Style
spaceXTuckedOverlap =
  customSelector
    "space-x-tucked-overlap"
    ".space-x-tucked-overlap > * + *"
    [("margin-left", "-12.3vh")]

originBottom :: Style
originBottom = css "origin-bottom" "transform-origin" "bottom"

translateYNeg4 :: Style
translateYNeg4 = css "-translate-y-4" "transform" "translateY(calc(var(--size-4) * -1))"

translateYNeg8 :: Style
translateYNeg8 = css "-translate-y-8" "transform" "translateY(calc(var(--size-8) * -1))"

scale105 :: Style
scale105 = css "scale-105" "transform" "scale(1.05)"

aspectCard :: Style
aspectCard = css "aspect-card" "aspect-ratio" "63/88"

w8mm :: Style
w8mm = w (Mm 8)

h8mm :: Style
h8mm = h (Mm 8)

altarStagingPanel :: Style
altarStagingPanel =
  flexCol
    <> pointerEventsAuto
    <> itemsCenter
    <> gap S3
    <> minW (Px 320)
    <> cls "altar-glowing-gold"
    <> backdropBlurMd
    <> roundedXl
    <> p S4

ringDiscard :: Style
ringDiscard = css "ring-discard" "box-shadow" "0 0 0 3px #ef4444"

textGoldBright :: Style
textGoldBright = css "text-gold-bright" "color" "var(--color-gold-bright)"

textGoldMuted :: Style
textGoldMuted = css "text-gold-muted" "color" "var(--color-gold-muted)"

borderGoldBright :: Style
borderGoldBright = css "border-gold-bright" "border-color" "var(--color-gold-bright)"

borderGoldMuted :: Style
borderGoldMuted = css "border-gold-muted" "border-color" "var(--color-gold-muted)"

bgStoneDark :: Style
bgStoneDark = css "bg-stone-dark" "background-color" "var(--color-stone-dark)"

borderStoneMed :: Style
borderStoneMed = css "border-stone-med" "border-color" "var(--color-stone-med)"

groupHoverBlock :: Style
groupHoverBlock =
  customSelector
    "group-hover:block"
    ".group:hover .group-hover\\:block, .group:focus-within .group-hover\\:block"
    [("display", "block")]

bottomFull :: Style
bottomFull = css "bottom-full" "bottom" "100%"

topFull :: Style
topFull = css "top-full" "top" "100%"
