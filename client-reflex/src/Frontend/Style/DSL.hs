{-# LANGUAGE OverloadedStrings #-}

-- | CSS utility DSL for CardPG.
--
-- This module provides CSS utilities as composable style functions.
-- Compose with (.) and apply to [] or use with divS/elS helpers.
--
-- @
-- cardHover :: Style
-- cardHover = transitionTransform . duration200 . hover translateYNeg8
-- @
module Frontend.Style.DSL
  ( -- * Re-exports from Core
    Style
  , css
  , css'

    -- * Modifiers
  , hover
  , hoverProp
  , active
  , activeProp
  , pseudo
  , pseudoProp
  , media
  , mediaProp

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

    -- * Parameterized Styles
  , gap
  , pad
  , fontSize
  , zIndex
  , opacity
  , borderRadius

    -- * Compound Styles
  , flex1
  , full
  ) where

import Data.Text (Text)
import Data.Text qualified as T
import Frontend.Style.Core

--------------------------------------------------------------------------------
-- Layout
--------------------------------------------------------------------------------

flex :: Style
flex = css "flex" "display" "flex"

flexCol :: Style
flexCol = css' "flex-col" [("display", "flex"), ("flex-direction", "column")]

flexRow :: Style
flexRow = css' "flex-row" [("display", "flex"), ("flex-direction", "row")]

grow :: Style
grow = css "grow" "flex-grow" "1"

itemsCenter :: Style
itemsCenter = css "items-center" "align-items" "center"

itemsEnd :: Style
itemsEnd = css "items-end" "align-items" "end"

itemsStretch :: Style
itemsStretch = css "items-stretch" "align-items" "stretch"

justifyStart :: Style
justifyStart = css "justify-start" "justify-content" "flex-start"

justifyCenter :: Style
justifyCenter = css "justify-center" "justify-content" "center"

justifyBetween :: Style
justifyBetween = css "justify-between" "justify-content" "space-between"

justifyAround :: Style
justifyAround = css "justify-around" "justify-content" "space-around"

grow0 :: Style
grow0 = css "grow-0" "flex-grow" "0"

shrink0 :: Style
shrink0 = css "shrink-0" "flex-shrink" "0"

absolute :: Style
absolute = css "absolute" "position" "absolute"

relative :: Style
relative = css "relative" "position" "relative"

fixed :: Style
fixed = css "fixed" "position" "fixed"

hidden :: Style
hidden = css "hidden" "display" "none"

overflowHidden :: Style
overflowHidden = css "overflow-hidden" "overflow" "hidden"

overflowYAuto :: Style
overflowYAuto = css "overflow-y-auto" "overflow-y" "auto"

z10 :: Style
z10 = css "z-10" "z-index" "10"

z20 :: Style
z20 = css "z-20" "z-index" "20"

z30 :: Style
z30 = css "z-30" "z-index" "30"

z40 :: Style
z40 = css "z-40" "z-index" "40"

cursorPointer :: Style
cursorPointer = css "cursor-pointer" "cursor" "pointer"

cursorNotAllowed :: Style
cursorNotAllowed = css "cursor-not-allowed" "cursor" "not-allowed"

pointerEventsNone :: Style
pointerEventsNone = css "pointer-events-none" "pointer-events" "none"

pointerEventsAuto :: Style
pointerEventsAuto = css "pointer-events-auto" "pointer-events" "auto"

group :: Style
group = css "group" "content" "\"\""

inlineBlock :: Style
inlineBlock = css "inline-block" "display" "inline-block"

alignTextBottom :: Style
alignTextBottom = css "align-text-bottom" "vertical-align" "text-bottom"

flexWrap :: Style
flexWrap = css "flex-wrap" "flex-wrap" "wrap"

contentStart :: Style
contentStart = css "content-start" "align-content" "flex-start"

--------------------------------------------------------------------------------
-- Sizing
--------------------------------------------------------------------------------

wFull :: Style
wFull = css "w-full" "width" "100%"

hFull :: Style
hFull = css "h-full" "height" "100%"

wFit :: Style
wFit = css "w-fit" "width" "fit-content"

w4 :: Style
w4 = css "w-4" "width" "1rem"

h4 :: Style
h4 = css "h-4" "height" "1rem"

w6 :: Style
w6 = css "w-6" "width" "1.5rem"

h6 :: Style
h6 = css "h-6" "height" "1.5rem"

w8 :: Style
w8 = css "w-8" "width" "2rem"

h8 :: Style
h8 = css "h-8" "height" "2rem"

w10 :: Style
w10 = css "w-10" "width" "2.5rem"

h10 :: Style
h10 = css "h-10" "height" "2.5rem"

w40 :: Style
w40 = css "w-40" "width" "10rem"

w72 :: Style
w72 = css "w-72" "width" "18rem"

w80 :: Style
w80 = css "w-80" "width" "20rem"

wCard :: Style
wCard = css "w-card" "width" "63mm"

hCard :: Style
hCard = css "h-card" "height" "88mm"

w8mm :: Style
w8mm = css "w-8mm" "width" "8mm"

h8mm :: Style
h8mm = css "h-8mm" "height" "8mm"

hScreen :: Style
hScreen = css "h-screen" "height" "100vh"

h2_5 :: Style
h2_5 = css "h-2/5" "height" "40%"

--------------------------------------------------------------------------------
-- Spacing
--------------------------------------------------------------------------------

p1 :: Style
p1 = css "p-1" "padding" "0.25rem"

p2mm :: Style
p2mm = css "p-2mm" "padding" "2mm"

p2_5mm :: Style
p2_5mm = css "p-2.5mm" "padding" "2.5mm"

p4 :: Style
p4 = css "p-4" "padding" "1rem"

p2 :: Style
p2 = css "p-2" "padding" "0.5rem"

p1_5 :: Style
p1_5 = css "p-1.5" "padding" "0.375rem"

pb1 :: Style
pb1 = css "pb-1" "padding-bottom" "0.25rem"

px1 :: Style
px1 = css' "px-1" [("padding-left", "0.25rem"), ("padding-right", "0.25rem")]

top1 :: Style
top1 = css "top-1" "top" "0.25rem"

right1 :: Style
right1 = css "right-1" "right" "0.25rem"

pr1 :: Style
pr1 = css "pr-1" "padding-right" "0.25rem"

px2 :: Style
px2 = css' "px-2" [("padding-left", "0.5rem"), ("padding-right", "0.5rem")]

py1 :: Style
py1 = css' "py-1" [("padding-top", "0.25rem"), ("padding-bottom", "0.25rem")]

px4 :: Style
px4 = css' "px-4" [("padding-left", "1rem"), ("padding-right", "1rem")]

py2 :: Style
py2 = css' "py-2" [("padding-top", "0.5rem"), ("padding-bottom", "0.5rem")]

px6 :: Style
px6 = css' "px-6" [("padding-left", "1.5rem"), ("padding-right", "1.5rem")]

px8 :: Style
px8 = css' "px-8" [("padding-left", "2rem"), ("padding-right", "2rem")]

py3 :: Style
py3 = css' "py-3" [("padding-top", "0.75rem"), ("padding-bottom", "0.75rem")]

p3 :: Style
p3 = css "p-3" "padding" "0.75rem"

mb2mm :: Style
mb2mm = css "mb-2mm" "margin-bottom" "2mm"

mt2 :: Style
mt2 = css "mt-2" "margin-top" "0.5rem"

mt1 :: Style
mt1 = css "mt-1" "margin-top" "0.25rem"

mb1 :: Style
mb1 = css "mb-1" "margin-bottom" "0.25rem"

mb2 :: Style
mb2 = css "mb-2" "margin-bottom" "0.5rem"

top2mm :: Style
top2mm = css "top-2mm" "top" "2mm"

right2mm :: Style
right2mm = css "right-2mm" "right" "2mm"

gap0 :: Style
gap0 = css "gap-0" "gap" "0"

gap1 :: Style
gap1 = css "gap-1" "gap" "0.25rem"

gap2 :: Style
gap2 = css "gap-2" "gap" "0.5rem"

gap4 :: Style
gap4 = css "gap-4" "gap" "1rem"

gap4mm :: Style
gap4mm = css "gap-4mm" "gap" "4mm"

bottom0 :: Style
bottom0 = css "bottom-0" "bottom" "0"

left0 :: Style
left0 = css "left-0" "left" "0"

right0 :: Style
right0 = css "right-0" "right" "0"

inset0 :: Style
inset0 = css "inset-0" "inset" "0"

--------------------------------------------------------------------------------
-- Colors
--------------------------------------------------------------------------------

bgSlate900 :: Style
bgSlate900 = css "bg-slate-900" "background-color" "#0f172a"

bgSlate800 :: Style
bgSlate800 = css "bg-slate-800" "background-color" "#1e293b"

bgSlate700 :: Style
bgSlate700 = css "bg-slate-700" "background-color" "#334155"

bgSlate600 :: Style
bgSlate600 = css "bg-slate-600" "background-color" "#475569"

bgSlate950 :: Style
bgSlate950 = css "bg-slate-950" "background-color" "#020617"

bgSlate800_50 :: Style
bgSlate800_50 = css "bg-slate-800/50" "background-color" "rgb(30 41 59 / 0.5)"

bgGray300 :: Style
bgGray300 = css "bg-gray-300" "background-color" "#d1d5db"

bgWhite :: Style
bgWhite = css "bg-white" "background-color" "white"

bgTransparent :: Style
bgTransparent = css "bg-transparent" "background-color" "transparent"

bgIndigo600 :: Style
bgIndigo600 = css "bg-indigo-600" "background-color" "#4f46e5"

bgIndigo500 :: Style
bgIndigo500 = css "bg-indigo-500" "background-color" "#6366f1"

bgIndigo700 :: Style
bgIndigo700 = css "bg-indigo-700" "background-color" "#4338ca"

bgRed900_50 :: Style
bgRed900_50 = css "bg-red-900/50" "background-color" "rgb(127 29 29 / 0.5)"

bgRed800_50 :: Style
bgRed800_50 = css "bg-red-800/50" "background-color" "rgb(153 27 27 / 0.5)"

textSlate100 :: Style
textSlate100 = css "text-slate-100" "color" "#f1f5f9"

textSlate200 :: Style
textSlate200 = css "text-slate-200" "color" "#e2e8f0"

textSlate300 :: Style
textSlate300 = css "text-slate-300" "color" "#cbd5e1"

textBlue300 :: Style
textBlue300 = css "text-blue-300" "color" "#93c5fd"

textBlue400 :: Style
textBlue400 = css "text-blue-400" "color" "#60a5fa"

textSlate400 :: Style
textSlate400 = css "text-slate-400" "color" "#94a3b8"

textSlate500 :: Style
textSlate500 = css "text-slate-500" "color" "#64748b"

textSlate600 :: Style
textSlate600 = css "text-slate-600" "color" "#475569"

textSlate700 :: Style
textSlate700 = css "text-slate-700" "color" "#334155"

textBlack :: Style
textBlack = css "text-black" "color" "black"

textWhite :: Style
textWhite = css "text-white" "color" "white"

textRed500 :: Style
textRed500 = css "text-red-500" "color" "#ef4444"

textRed200 :: Style
textRed200 = css "text-red-200" "color" "#fecaca"

textRed100 :: Style
textRed100 = css "text-red-100" "color" "#fee2e2"

textRed300 :: Style
textRed300 = css "text-red-300" "color" "#fca5a5"

textRed400 :: Style
textRed400 = css "text-red-400" "color" "#f87171"

textIndigo400 :: Style
textIndigo400 = css "text-indigo-400" "color" "#818cf8"

textYellow400 :: Style
textYellow400 = css "text-yellow-400" "color" "#facc15"

textBlue500 :: Style
textBlue500 = css "text-blue-500" "color" "#3b82f6"

textBlue5 :: Style
textBlue5 = css "text-blue-5" "color" "var(--blue-5)"

borderSlate500 :: Style
borderSlate500 = css "border-slate-500" "border-color" "#64748b"

borderSlate600 :: Style
borderSlate600 = css "border-slate-600" "border-color" "#475569"

borderSlate700 :: Style
borderSlate700 = css "border-slate-700" "border-color" "#334155"

borderSlate800 :: Style
borderSlate800 = css "border-slate-800" "border-color" "#1e293b"

borderBlack :: Style
borderBlack = css "border-black" "border-color" "black"

borderTransparent :: Style
borderTransparent = css "border-transparent" "border-color" "transparent"

borderRed800 :: Style
borderRed800 = css "border-red-800" "border-color" "#991b1b"

--------------------------------------------------------------------------------
-- Borders
--------------------------------------------------------------------------------

border :: Style
border = css "border" "border-width" "1px"

border0 :: Style
border0 = css "border-0" "border-width" "0"

border2 :: Style
border2 = css "border-2" "border-width" "2px"

borderB :: Style
borderB = css "border-b" "border-bottom-width" "1px"

borderT :: Style
borderT = css "border-t" "border-top-width" "1px"

borderL :: Style
borderL = css "border-l" "border-left-width" "1px"

borderR :: Style
borderR = css "border-r" "border-right-width" "1px"

border02mm :: Style
border02mm = css "border-0.2mm" "border-width" "0.2mm"

rounded :: Style
rounded = css "rounded" "border-radius" "0.25rem"

roundedNone :: Style
roundedNone = css "rounded-none" "border-radius" "0"

roundedXl :: Style
roundedXl = css "rounded-xl" "border-radius" "0.75rem"

rounded3Xl :: Style
rounded3Xl = css "rounded-3xl" "border-radius" "1.5rem"

roundedFull :: Style
roundedFull = css "rounded-full" "border-radius" "9999px"

rounded3mm :: Style
rounded3mm = css "rounded-3mm" "border-radius" "3mm"

rounded2mm :: Style
rounded2mm = css "rounded-2mm" "border-radius" "2mm"

rounded1mm :: Style
rounded1mm = css "rounded-1mm" "border-radius" "1mm"

--------------------------------------------------------------------------------
-- Typography
--------------------------------------------------------------------------------

fontBold :: Style
fontBold = css "font-bold" "font-weight" "bold"

textSm :: Style
textSm = css "text-sm" "font-size" "0.875rem"

textXs :: Style
textXs = css "text-xs" "font-size" "0.75rem"

textXl :: Style
textXl = css "text-xl" "font-size" "1.25rem"

text2Xl :: Style
text2Xl = css "text-2xl" "font-size" "1.5rem"

textLg :: Style
textLg = css "text-lg" "font-size" "1.125rem"

textBase :: Style
textBase = css "text-base" "font-size" "1rem"

leadingTight :: Style
leadingTight = css "leading-tight" "line-height" "1.25"

textCenter :: Style
textCenter = css "text-center" "text-align" "center"

uppercase :: Style
uppercase = css "uppercase" "text-transform" "uppercase"

trackingWider :: Style
trackingWider = css "tracking-wider" "letter-spacing" "0.05em"

whitespaceNowrap :: Style
whitespaceNowrap = css "whitespace-nowrap" "white-space" "nowrap"

textTruncate :: Style
textTruncate = css "truncate" "text-overflow" "ellipsis"

textLeft :: Style
textLeft = css "text-left" "text-align" "left"

--------------------------------------------------------------------------------
-- Effects
--------------------------------------------------------------------------------

shadow2Xl :: Style
shadow2Xl = css "shadow-2xl" "box-shadow" "0 25px 50px -12px rgb(0 0 0 / 0.25)"

shadowXl :: Style
shadowXl =
  css "shadow-xl" "box-shadow" "0 20px 25px -5px rgb(0 0 0 / 0.1), 0 8px 10px -6px rgb(0 0 0 / 0.1)"

shadowLg :: Style
shadowLg =
  css "shadow-lg" "box-shadow" "0 10px 15px -3px rgb(0 0 0 / 0.1), 0 4px 6px -4px rgb(0 0 0 / 0.1)"

shadowSm :: Style
shadowSm = css "shadow-sm" "box-shadow" "0 1px 2px 0 rgb(0 0 0 / 0.05)"

grayscale :: Style
grayscale = css "grayscale" "filter" "grayscale(100%)"

grayscale50 :: Style
grayscale50 = css "grayscale-50" "filter" "grayscale(50%)"

opacity75 :: Style
opacity75 = css "opacity-75" "opacity" "0.75"

backdropBlurMd :: Style
backdropBlurMd = css "backdrop-blur-md" "backdrop-filter" "blur(12px)"

opacity50 :: Style
opacity50 = css "opacity-50" "opacity" "0.5"

--------------------------------------------------------------------------------
-- Aspect Ratios
--------------------------------------------------------------------------------

aspect43 :: Style
aspect43 = css "aspect-4/3" "aspect-ratio" "4/3"

aspectCard :: Style
aspectCard = css "aspect-card" "aspect-ratio" "63/88"

aspectSquare :: Style
aspectSquare = css "aspect-square" "aspect-ratio" "1/1"

--------------------------------------------------------------------------------
-- Card Layout
--------------------------------------------------------------------------------

wCardHand :: Style
wCardHand = css "w-card-hand" "width" "16vh"

mlCardOverlap :: Style
mlCardOverlap = css "-ml-card-overlap" "margin-left" "-12vh"

originBottom :: Style
originBottom = css "origin-bottom" "transform-origin" "bottom"

translateYNeg4 :: Style
translateYNeg4 = css "-translate-y-4" "transform" "translateY(-1rem)"

translateYNeg8 :: Style
translateYNeg8 = css "-translate-y-8" "transform" "translateY(-2rem)"

scale105 :: Style
scale105 = css "scale-105" "transform" "scale(1.05)"

--------------------------------------------------------------------------------
-- Transitions
--------------------------------------------------------------------------------

transitionAll :: Style
transitionAll = css "transition-all" "transition-property" "all"

transitionTransform :: Style
transitionTransform = css "transition-transform" "transition-property" "transform"

transitionColors :: Style
transitionColors =
  css
    "transition-colors"
    "transition-property"
    "color, background-color, border-color, text-decoration-color, fill, stroke"

duration200 :: Style
duration200 = css "duration-200" "transition-duration" "200ms"

easeOut :: Style
easeOut = css "ease-out" "transition-timing-function" "ease-out"

--------------------------------------------------------------------------------
-- Interactions
--------------------------------------------------------------------------------

selectNone :: Style
selectNone = css "select-none" "user-select" "none"

--------------------------------------------------------------------------------
-- Ring/Outline
--------------------------------------------------------------------------------

ring2 :: Style
ring2 = css "ring-2" "box-shadow" "0 0 0 2px var(--tw-ring-color)"

ringBlue400 :: Style
ringBlue400 = css "ring-blue-400" "--tw-ring-color" "#60a5fa"

ringAmber400 :: Style
ringAmber400 = css "ring-amber-400" "--tw-ring-color" "#fbbf24"

ringIndigo400 :: Style
ringIndigo400 = css "ring-indigo-400" "--tw-ring-color" "#818cf8"

ringOffset2 :: Style
ringOffset2 = css "ring-offset-2" "--tw-ring-offset-width" "2px"

--------------------------------------------------------------------------------
-- Compound Styles
--------------------------------------------------------------------------------

flex1 :: Style
flex1 = css "flex-1" "flex" "1 1 0%"

full :: Style
full = wFull . hFull

--------------------------------------------------------------------------------
-- Parameterized Styles
--------------------------------------------------------------------------------

gap :: Int -> Style
gap 0 = css "gap-0" "gap" "0"
gap n = css ("gap-" <> tshow n) "gap" (tshow n <> "px")

pad :: Int -> Style
pad n = css ("p-" <> tshow n) "padding" (tshow (n * 4) <> "px")

fontSize :: Int -> Style
fontSize n = css ("text-" <> tshow n) "font-size" (tshow n <> "px")

zIndex :: Int -> Style
zIndex n = css ("z-" <> tshow n) "z-index" (tshow n)

opacity :: Double -> Style
opacity v = css ("opacity-" <> tshow (round (v * 100) :: Int)) "opacity" (tshow v)

borderRadius :: Int -> Style
borderRadius n = css ("rounded-" <> tshow n) "border-radius" (tshow n <> "px")
