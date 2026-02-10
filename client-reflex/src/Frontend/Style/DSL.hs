{-# LANGUAGE OverloadedStrings #-}

-- | Transformer-style CSS atoms.
--
-- This module provides CSS utilities as style transformers (CSS h -> CSS h)
-- following the atomic-css library's native pattern. Compose with (.) and
-- apply to mempty or other CSS values.
--
-- @
-- cardHover :: Style
-- cardHover = transitionTransform . duration200 . hover translateYNeg8
-- @
module Frontend.Style.DSL
  ( -- * Selector Modifiers
    hover
  , active
  , pseudo
  , media

    -- * Atom helper
  , atom

    -- * Layout
  , flex
  , flexRow
  , flexCol
  , itemsCenter
  , itemsEnd
  , itemsStretch
  , justifyStart
  , justifyCenter
  , justifyBetween
  , justifyBetween
  , justifyAround
  , grow
  , grow0
  , shrink0
  , absolute
  , relative
  , fixed
  , hidden
  , overflowHidden
  , overflowYAuto
  , z10
  , z20
  , z30
  , z40
  , cursorPointer
  , cursorNotAllowed
  , pointerEventsNone
  , pointerEventsAuto
  , group
  , inlineBlock
  , alignTextBottom
  , flexWrap
  , contentStart

    -- * Sizing
  , wFull
  , hFull
  , wFit
  , w4
  , h4
  , w6
  , h6
  , w8
  , h8
  , w10
  , h10
  , w40
  , w72
  , w80
  , wCard
  , hCard
  , w8mm
  , h8mm
  , hScreen
  , h2_5

    -- * Spacing
  , p1
  , p2mm
  , p2_5mm
  , p4
  , p1_5
  , pb1
  , pr1
  , px1
  , px2
  , py1
  , px4
  , py2
  , p2
  , px6
  , px8
  , top1
  , right1
  , py3
  , p3
  , p3
  , mb2mm
  , mt2
  , mt1
  , mb1
  , mb2
  , top2mm
  , right2mm
  , gap0
  , gap1
  , gap2
  , gap4
  , gap4mm
  , bottom0
  , left0
  , right0
  , inset0

    -- * Colors
  , bgSlate900
  , bgSlate800
  , bgSlate700
  , bgSlate600
  , bgSlate950
  , bgSlate800_50
  , bgGray300
  , bgWhite
  , bgTransparent
  , bgIndigo600
  , bgIndigo500
  , bgIndigo700
  , textIndigo400
  , bgRed900_50
  , bgRed800_50
  , textSlate100
  , textSlate200
  , textSlate300
  , textBlue300
  , textBlue400
  , textSlate400
  , textSlate500
  , textSlate600
  , textSlate700
  , textBlack
  , textWhite
  , textRed500
  , textRed200
  , textRed100
  , textRed300
  , textRed400
  , textYellow400
  , textBlue500
  , textBlue5
  , borderSlate500
  , borderSlate600
  , borderSlate700
  , borderSlate800
  , borderBlack
  , borderTransparent
  , borderRed800

    -- * Borders
  , border
  , border0
  , border2
  , borderB
  , borderT
  , borderL
  , borderR
  , border02mm
  , rounded
  , roundedNone
  , roundedXl
  , rounded3Xl
  , roundedFull
  , rounded3mm
  , rounded2mm
  , rounded1mm

    -- * Typography
  , fontBold
  , textSm
  , textXs
  , textXl
  , text2Xl
  , textLg
  , textBase
  , textCenter
  , leadingTight
  , uppercase
  , trackingWider
  , whitespaceNowrap
  , textTruncate
  , textLeft

    -- * Effects
  , shadow2Xl
  , shadowXl
  , shadowLg
  , shadowSm
  , grayscale
  , grayscale50
  , opacity75
  , opacity50
  , backdropBlurMd

    -- * Aspect Ratios
  , aspect43
  , aspectCard
  , aspectSquare

    -- * Card Layout
  , wCardHand
  , mlCardOverlap
  , originBottom
  , translateYNeg4
  , translateYNeg8
  , scale105

    -- * Transitions
  , transitionAll
  , transitionTransform
  , transitionColors
  , duration200
  , easeOut

    -- * Interactions
  , selectNone

    -- * Ring/Outline
  , ring2
  , ringBlue400
  , ringAmber400
  , ringIndigo400
  , ringOffset2

    -- * Compound Styles
  , flex1
  , full
  ) where

import Data.Text (Text)
import Data.Text qualified as T
import Web.Atomic qualified hiding (active, hover, media, truncate)
import Web.Atomic.CSS.Box qualified as Box
import Web.Atomic.CSS.Layout qualified as Layout
import Web.Atomic.CSS.Select (active, hover, media, pseudo)
import Web.Atomic.CSS.Text qualified as Text
import Web.Atomic.Types
  ( Auto (..)
  , ClassName (..)
  , Length (..)
  , None (..)
  , Rule
  , Sides (..)
  , Styleable
  )
import Web.Atomic.Types.Styleable (CSS (..))

-- | Style transformer type (library pattern)
type Style = CSS [Rule] -> CSS [Rule]

-- | Helper to define an atomic style transformer
atom :: Text -> Text -> String -> Style
atom name prop val =
  ( Web.Atomic.utility
      (ClassName name)
      [Web.Atomic.Property prop Web.Atomic.:. Web.Atomic.Style val]
      mempty
      <>
  )

--------------------------------------------------------------------------------
-- Layout
--------------------------------------------------------------------------------

flex :: Style
flex = Layout.display Layout.Flex

flexCol :: Style
flexCol = Layout.flexCol

flexRow :: Style
flexRow = Layout.flexRow

grow :: Style
grow = Layout.grow

itemsCenter :: Style
itemsCenter = atom "items-center" "align-items" "center"

itemsEnd :: Style
itemsEnd = atom "items-end" "align-items" "end"

itemsStretch :: Style
itemsStretch = atom "items-stretch" "align-items" "stretch"

justifyStart :: Style
justifyStart = atom "justify-start" "justify-content" "flex-start"

justifyCenter :: Style
justifyCenter = atom "justify-center" "justify-content" "center"

justifyBetween :: Style
justifyBetween = atom "justify-between" "justify-content" "space-between"

justifyAround :: Style
justifyAround = atom "justify-around" "justify-content" "space-around"

grow0 :: Style
grow0 = atom "grow-0" "flex-grow" "0"

shrink0 :: Style
shrink0 = atom "shrink-0" "flex-shrink" "0"

absolute :: Style
absolute = Layout.position Layout.Absolute

relative :: Style
relative = Layout.position Layout.Relative

fixed :: Style
fixed = Layout.position Layout.Fixed

hidden :: Style
hidden = Layout.display None

overflowHidden :: Style
overflowHidden = Layout.overflow Layout.Hidden

overflowYAuto :: Style
overflowYAuto = atom "overflow-y-auto" "overflow-y" "auto"

z10 :: Style
z10 = Layout.zIndex 10

z20 :: Style
z20 = Layout.zIndex 20

z30 :: Style
z30 = Layout.zIndex 30

z40 :: Style
z40 = Layout.zIndex 40

cursorPointer :: Style
cursorPointer = atom "cursor-pointer" "cursor" "pointer"

cursorNotAllowed :: Style
cursorNotAllowed = atom "cursor-not-allowed" "cursor" "not-allowed"

pointerEventsNone :: Style
pointerEventsNone = atom "pointer-events-none" "pointer-events" "none"

pointerEventsAuto :: Style
pointerEventsAuto = atom "pointer-events-auto" "pointer-events" "auto"

group :: Style
group = atom "group" "content" "\"\""

inlineBlock :: Style
inlineBlock = atom "inline-block" "display" "inline-block"

alignTextBottom :: Style
alignTextBottom = atom "align-text-bottom" "vertical-align" "text-bottom"

flexWrap :: Style
flexWrap = atom "flex-wrap" "flex-wrap" "wrap"

contentStart :: Style
contentStart = atom "content-start" "align-content" "flex-start"

--------------------------------------------------------------------------------
-- Sizing
--------------------------------------------------------------------------------

wFull :: Style
wFull = Layout.width (Pct 1.0)

hFull :: Style
hFull = Layout.height (Pct 1.0)

wFit :: Style
wFit = atom "w-fit" "width" "fit-content"

w4 :: Style
w4 = Layout.width 16

h4 :: Style
h4 = Layout.height 16

w6 :: Style
w6 = Layout.width 24

h6 :: Style
h6 = Layout.height 24

w8 :: Style
w8 = Layout.width 32

h8 :: Style
h8 = Layout.height 32

w10 :: Style
w10 = Layout.width 40

h10 :: Style
h10 = Layout.height 40

w40 :: Style
w40 = Layout.width 160

w72 :: Style
w72 = Layout.width 288

w80 :: Style
w80 = Layout.width 320

wCard :: Style
wCard = atom "w-[63mm]" "width" "63mm"

hCard :: Style
hCard = atom "h-[88mm]" "height" "88mm"

w8mm :: Style
w8mm = atom "w-[8mm]" "width" "8mm"

h8mm :: Style
h8mm = atom "h-[8mm]" "height" "8mm"

hScreen :: Style
hScreen = atom "h-screen" "height" "100vh"

h2_5 :: Style
h2_5 = atom "h-2/5" "height" "40%"

--------------------------------------------------------------------------------
-- Spacing
--------------------------------------------------------------------------------

p1 :: Style
p1 = Box.pad (All 4)

p2mm :: Style
p2mm = atom "p-[2mm]" "padding" "2mm"

p2_5mm :: Style
p2_5mm = atom "p-[2.5mm]" "padding" "2.5mm"

p4 :: Style
p4 = Box.pad (All 16)

p2 :: Style
p2 = Box.pad (All 8)

p1_5 :: Style
p1_5 = Box.pad (All 6)

pb1 :: Style
pb1 = Box.pad (B 4)

px1 :: Style
px1 = Box.pad (X 4)

top1 :: Style
top1 = atom "top-1" "top" "0.25rem"

right1 :: Style
right1 = atom "right-1" "right" "0.25rem"

pr1 :: Style
pr1 = Box.pad (R 4)

px2 :: Style
px2 = Box.pad (X 8)

py1 :: Style
py1 = Box.pad (Y 4)

px4 :: Style
px4 = Box.pad (X 16)

py2 :: Style
py2 = Box.pad (Y 8)

px6 :: Style
px6 = Box.pad (X 24)

px8 :: Style
px8 = Box.pad (X 32)

py3 :: Style
py3 = Box.pad (Y 12)

p3 :: Style
p3 = Box.pad (All 12)

mb2mm :: Style
mb2mm = atom "mb-[2mm]" "margin-bottom" "2mm"

mt2 :: Style
mt2 = Box.margin (T 8)

mt1 :: Style
mt1 = Box.margin (T 4)

mb1 :: Style
mb1 = Box.margin (B 4)

mb2 :: Style
mb2 = Box.margin (B 8)

top2mm :: Style
top2mm = atom "top-[2mm]" "top" "2mm"

right2mm :: Style
right2mm = atom "right-[2mm]" "right" "2mm"

gap0 :: Style
gap0 = Box.gap 0

gap1 :: Style
gap1 = Box.gap 4

gap2 :: Style
gap2 = Box.gap 8

gap4 :: Style
gap4 = Box.gap 16

gap4mm :: Style
gap4mm = atom "gap-[4mm]" "gap" "4mm"

bottom0 :: Style
bottom0 = atom "bottom-0" "bottom" "0"

left0 :: Style
left0 = atom "left-0" "left" "0"

right0 :: Style
right0 = atom "right-0" "right" "0"

inset0 :: Style
inset0 = atom "inset-0" "inset" "0"

--------------------------------------------------------------------------------
-- Colors
--------------------------------------------------------------------------------

bgSlate900 :: Style
bgSlate900 = atom "bg-slate-900" "background-color" "#0f172a"

bgSlate800 :: Style
bgSlate800 = atom "bg-slate-800" "background-color" "#1e293b"

bgSlate700 :: Style
bgSlate700 = atom "bg-slate-700" "background-color" "#334155"

bgSlate600 :: Style
bgSlate600 = atom "bg-slate-600" "background-color" "#475569"

bgSlate950 :: Style
bgSlate950 = atom "bg-slate-950" "background-color" "#020617"

bgSlate800_50 :: Style
bgSlate800_50 = atom "bg-slate-800/50" "background-color" "rgb(30 41 59 / 0.5)"

bgGray300 :: Style
bgGray300 = atom "bg-gray-300" "background-color" "#d1d5db"

bgWhite :: Style
bgWhite = atom "bg-white" "background-color" "white"

bgTransparent :: Style
bgTransparent = atom "bg-transparent" "background-color" "transparent"

bgIndigo600 :: Style
bgIndigo600 = atom "bg-indigo-600" "background-color" "#4f46e5"

bgIndigo500 :: Style
bgIndigo500 = atom "bg-indigo-500" "background-color" "#6366f1"

bgIndigo700 :: Style
bgIndigo700 = atom "bg-indigo-700" "background-color" "#4338ca"

bgRed900_50 :: Style
bgRed900_50 = atom "bg-red-900/50" "background-color" "rgb(127 29 29 / 0.5)"

bgRed800_50 :: Style
bgRed800_50 = atom "bg-red-800/50" "background-color" "rgb(153 27 27 / 0.5)"

textSlate100 :: Style
textSlate100 = atom "text-slate-100" "color" "#f1f5f9"

textSlate200 :: Style
textSlate200 = atom "text-slate-200" "color" "#e2e8f0"

textSlate300 :: Style
textSlate300 = atom "text-slate-300" "color" "#cbd5e1"

textBlue300 :: Style
textBlue300 = atom "text-blue-300" "color" "#93c5fd"

textBlue400 :: Style
textBlue400 = atom "text-blue-400" "color" "#60a5fa"

textSlate400 :: Style
textSlate400 = atom "text-slate-400" "color" "#94a3b8"

textSlate500 :: Style
textSlate500 = atom "text-slate-500" "color" "#64748b"

textSlate600 :: Style
textSlate600 = atom "text-slate-600" "color" "#475569"

textSlate700 :: Style
textSlate700 = atom "text-slate-700" "color" "#334155"

textBlack :: Style
textBlack = atom "text-black" "color" "black"

textWhite :: Style
textWhite = atom "text-white" "color" "white"

textRed500 :: Style
textRed500 = atom "text-red-500" "color" "#ef4444"

textRed200 :: Style
textRed200 = atom "text-red-200" "color" "#fecaca"

textRed100 :: Style
textRed100 = atom "text-red-100" "color" "#fee2e2"

textRed300 :: Style
textRed300 = atom "text-red-300" "color" "#fca5a5"

textRed400 :: Style
textRed400 = atom "text-red-400" "color" "#f87171"

textIndigo400 :: Style
textIndigo400 = atom "text-indigo-400" "color" "#818cf8"

textYellow400 :: Style
textYellow400 = atom "text-yellow-400" "color" "#facc15"

textBlue500 :: Style
textBlue500 = atom "text-blue-500" "color" "#3b82f6"

textBlue5 :: Style
textBlue5 = atom "text-blue-5" "color" "var(--blue-5)"

borderSlate500 :: Style
borderSlate500 = atom "border-slate-500" "border-color" "#64748b"

borderSlate600 :: Style
borderSlate600 = atom "border-slate-600" "border-color" "#475569"

borderSlate700 :: Style
borderSlate700 = atom "border-slate-700" "border-color" "#334155"

borderSlate800 :: Style
borderSlate800 = atom "border-slate-800" "border-color" "#1e293b"

borderBlack :: Style
borderBlack = atom "border-black" "border-color" "black"

borderTransparent :: Style
borderTransparent = atom "border-transparent" "border-color" "transparent"

borderRed800 :: Style
borderRed800 = atom "border-red-800" "border-color" "#991b1b"

--------------------------------------------------------------------------------
-- Borders
--------------------------------------------------------------------------------

border :: Style
border = Box.border 1

border0 :: Style
border0 = Box.border 0

border2 :: Style
border2 = Box.border 2

borderB :: Style
borderB = atom "border-b" "border-bottom-width" "1px"

borderT :: Style
borderT = atom "border-t" "border-top-width" "1px"

borderL :: Style
borderL = atom "border-l" "border-left-width" "1px"

borderR :: Style
borderR = atom "border-r" "border-right-width" "1px"

border02mm :: Style
border02mm = atom "border-[0.2mm]" "border-width" "0.2mm"

rounded :: Style
rounded = atom "rounded" "border-radius" "0.25rem"

roundedNone :: Style
roundedNone = atom "rounded-none" "border-radius" "0"

roundedXl :: Style
roundedXl = atom "rounded-xl" "border-radius" "0.75rem"

rounded3Xl :: Style
rounded3Xl = atom "rounded-3xl" "border-radius" "1.5rem"

roundedFull :: Style
roundedFull = atom "rounded-full" "border-radius" "9999px"

rounded3mm :: Style
rounded3mm = atom "rounded-[3mm]" "border-radius" "3mm"

rounded2mm :: Style
rounded2mm = atom "rounded-[2mm]" "border-radius" "2mm"

rounded1mm :: Style
rounded1mm = atom "rounded-[1mm]" "border-radius" "1mm"

--------------------------------------------------------------------------------
-- Typography
--------------------------------------------------------------------------------

fontBold :: Style
fontBold = Text.bold

textSm :: Style
textSm = Text.fontSize 14

textXs :: Style
textXs = Text.fontSize 12

textXl :: Style
textXl = Text.fontSize 20

text2Xl :: Style
text2Xl = Text.fontSize 24

textLg :: Style
textLg = Text.fontSize 18

textBase :: Style
textBase = Text.fontSize 16

leadingTight :: Style
leadingTight = atom "leading-tight" "line-height" "1.25"

textCenter :: Style
textCenter = Text.textAlign Text.AlignCenter

uppercase :: Style
uppercase = atom "uppercase" "text-transform" "uppercase"

trackingWider :: Style
trackingWider = atom "tracking-wider" "letter-spacing" "0.05em"

whitespaceNowrap :: Style
whitespaceNowrap = atom "whitespace-nowrap" "white-space" "nowrap"

textTruncate :: Style
textTruncate = atom "truncate" "text-overflow" "ellipsis"

textLeft :: Style
textLeft = Text.textAlign Text.AlignLeft

--------------------------------------------------------------------------------
-- Effects
--------------------------------------------------------------------------------

shadow2Xl :: Style
shadow2Xl = atom "shadow-2xl" "box-shadow" "0 25px 50px -12px rgb(0 0 0 / 0.25)"

shadowXl :: Style
shadowXl =
  atom "shadow-xl" "box-shadow" "0 20px 25px -5px rgb(0 0 0 / 0.1), 0 8px 10px -6px rgb(0 0 0 / 0.1)"

shadowLg :: Style
shadowLg =
  atom "shadow-lg" "box-shadow" "0 10px 15px -3px rgb(0 0 0 / 0.1), 0 4px 6px -4px rgb(0 0 0 / 0.1)"

shadowSm :: Style
shadowSm = atom "shadow-sm" "box-shadow" "0 1px 2px 0 rgb(0 0 0 / 0.05)"

grayscale :: Style
grayscale = atom "grayscale" "filter" "grayscale(100%)"

grayscale50 :: Style
grayscale50 = atom "grayscale-[50%]" "filter" "grayscale(50%)"

opacity75 :: Style
opacity75 = Box.opacity 0.75

backdropBlurMd :: Style
backdropBlurMd = atom "backdrop-blur-md" "backdrop-filter" "blur(12px)"

opacity50 :: Style
opacity50 = Box.opacity 0.5

--------------------------------------------------------------------------------
-- Aspect Ratios
--------------------------------------------------------------------------------

aspect43 :: Style
aspect43 = atom "aspect-[4/3]" "aspect-ratio" "4/3"

aspectCard :: Style
aspectCard = atom "aspect-[63/88]" "aspect-ratio" "63/88"

aspectSquare :: Style
aspectSquare = atom "aspect-square" "aspect-ratio" "1/1"

--------------------------------------------------------------------------------
-- Card Layout
--------------------------------------------------------------------------------

wCardHand :: Style
wCardHand = atom "w-[16vh]" "width" "16vh"

mlCardOverlap :: Style
mlCardOverlap = atom "-ml-[12vh]" "margin-left" "-12vh"

originBottom :: Style
originBottom = atom "origin-bottom" "transform-origin" "bottom"

translateYNeg4 :: Style
translateYNeg4 = atom "-translate-y-4" "transform" "translateY(-1rem)"

translateYNeg8 :: Style
translateYNeg8 = atom "-translate-y-8" "transform" "translateY(-2rem)"

scale105 :: Style
scale105 = atom "scale-105" "transform" "scale(1.05)"

--------------------------------------------------------------------------------
-- Transitions
--------------------------------------------------------------------------------

transitionAll :: Style
transitionAll = atom "transition-all" "transition-property" "all"

transitionTransform :: Style
transitionTransform = atom "transition-transform" "transition-property" "transform"

transitionColors :: Style
transitionColors =
  atom
    "transition-colors"
    "transition-property"
    "color, background-color, border-color, text-decoration-color, fill, stroke"

duration200 :: Style
duration200 = atom "duration-200" "transition-duration" "200ms"

easeOut :: Style
easeOut = atom "ease-out" "transition-timing-function" "ease-out"

--------------------------------------------------------------------------------
-- Interactions
--------------------------------------------------------------------------------

selectNone :: Style
selectNone = atom "select-none" "user-select" "none"

--------------------------------------------------------------------------------
-- Ring/Outline
--------------------------------------------------------------------------------

ring2 :: Style
ring2 = atom "ring-2" "box-shadow" "0 0 0 2px var(--tw-ring-color)"

ringBlue400 :: Style
ringBlue400 = atom "ring-blue-400" "--tw-ring-color" "#60a5fa"

ringAmber400 :: Style
ringAmber400 = atom "ring-amber-400" "--tw-ring-color" "#fbbf24"

ringIndigo400 :: Style
ringIndigo400 = atom "ring-indigo-400" "--tw-ring-color" "#818cf8"

ringOffset2 :: Style
ringOffset2 = atom "ring-offset-2" "--tw-ring-offset-width" "2px"

--------------------------------------------------------------------------------
-- Compound Styles
--------------------------------------------------------------------------------

flex1 :: Style
flex1 = atom "flex-1" "flex" "1 1 0%"

full :: Style
full = wFull . hFull
