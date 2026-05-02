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
  , z
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
  , w
  , h
  , wFull
  , hFull
  , wFit
  , wCard
  , hCard
  , w8mm
  , h8mm
  , hScreen
  , h2_5

    -- * Spacing
  , p
  , px
  , py
  , mt
  , mb
  , p2mm
  , p2_5mm
  , p1_5
  , pb1
  , pr1
  , top1
  , right1
  , mb2mm
  , top2mm
  , right2mm
  , gap
  , gap4mm
  , bottom0
  , left0
  , right0
  , inset0

    -- * Colors
  , Color (..)
  , bg
  , bgAlpha
  , borderAlpha
  , text
  , border
  , ring
  , bgWhite
  , bgTransparent
  , textBlack
  , textWhite
  , borderBlack
  , borderTransparent

    -- * Borders
  , border1
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
  , italic

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
  , spaceXActionStackOverlap
  , spaceY2
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
  , ringOffset2

    -- * Parameterized Styles
  , gap
  , fontSize
  , opacity
  , borderRadius

    -- * Compound Styles
  , flex1
  , full
  ) where

import Data.Text (Text)
import Data.Text qualified as T
import Frontend.Style.Core

----------------------------------------------------------------------------------

spaceXActionStackOverlap :: Style
spaceXActionStackOverlap = \rest ->
  Prop
    "space-x-action-stack-overlap"
    ".space-x-action-stack-overlap > * + *"
    [("margin-left", "-12vh")]
    : rest

spaceY2 :: Style
spaceY2 = \rest ->
  Prop "space-y-2" ".space-y-2 > * + *" [("margin-top", "0.5rem")]
    : rest

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

z :: Int -> Style
z n = css ("z-" <> tshow n) "z-index" (tshow n)

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

-- | Width in Tailwind spacing units (n * 0.25rem).
-- e.g. @w 4@ = 1rem, @w 8@ = 2rem, @w 80@ = 20rem
w :: Int -> Style
w n = css ("w-" <> tshow n) "width" (remValue n)

-- | Height in Tailwind spacing units (n * 0.25rem).
-- e.g. @h 4@ = 1rem, @h 8@ = 2rem, @h 10@ = 2.5rem
h :: Int -> Style
h n = css ("h-" <> tshow n) "height" (remValue n)

-- | Convert a Tailwind spacing unit to a rem value string.
-- Produces clean output: 1rem, 1.25rem, 2.5rem (no trailing .0)
remValue :: Int -> Text
remValue n
  | n `mod` 4 == 0 = tshow (n `div` 4) <> "rem"
  | otherwise = tshow (fromIntegral n * 0.25 :: Double) <> "rem"

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

p :: Int -> Style
p n = css ("p-" <> tshow n) "padding" (remValue n)

px :: Int -> Style
px n = css' ("px-" <> tshow n) [("padding-left", v), ("padding-right", v)]
  where
    v = remValue n

py :: Int -> Style
py n = css' ("py-" <> tshow n) [("padding-top", v), ("padding-bottom", v)]
  where
    v = remValue n

mt :: Int -> Style
mt n = css ("mt-" <> tshow n) "margin-top" (remValue n)

mb :: Int -> Style
mb n = css ("mb-" <> tshow n) "margin-bottom" (remValue n)

p2mm :: Style
p2mm = css "p-2mm" "padding" "2mm"

p2_5mm :: Style
p2_5mm = css "p-2.5mm" "padding" "2.5mm"

p1_5 :: Style
p1_5 = css "p-1.5" "padding" "0.375rem"

pb1 :: Style
pb1 = css "pb-1" "padding-bottom" "0.25rem"

top1 :: Style
top1 = css "top-1" "top" "0.25rem"

right1 :: Style
right1 = css "right-1" "right" "0.25rem"

pr1 :: Style
pr1 = css "pr-1" "padding-right" "0.25rem"

mb2mm :: Style
mb2mm = css "mb-2mm" "margin-bottom" "2mm"

top2mm :: Style
top2mm = css "top-2mm" "top" "2mm"

right2mm :: Style
right2mm = css "right-2mm" "right" "2mm"

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

data Color = Gray | Red | Blue | Indigo | Yellow | Amber | White | Black | Transparent
  deriving (Show, Eq, Enum, Bounded)

colorName :: Color -> Text
colorName c = T.toLower (tshow c)

bg :: Color -> Int -> Style
bg c n =
  css
    ("bg-" <> colorName c <> "-" <> tshow n)
    "background-color"
    ("var(--" <> colorName c <> "-" <> tshow n <> ")")

bgAlpha :: Color -> Int -> Int -> Style
bgAlpha c n a =
  let var = case c of
        Black -> "black"
        White -> "white"
        _ -> "var(--" <> colorName c <> "-" <> tshow n <> ")"
   in css
        ("bg-" <> colorName c <> "-" <> tshow n <> "/" <> tshow a)
        "background-color"
        ("color-mix(in srgb, " <> var <> " " <> tshow a <> "%, transparent)")

borderAlpha :: Color -> Int -> Int -> Style
borderAlpha c n a =
  let var = case c of
        Black -> "black"
        White -> "white"
        _ -> "var(--" <> colorName c <> "-" <> tshow n <> ")"
   in css
        ("border-" <> colorName c <> "-" <> tshow n <> "/" <> tshow a)
        "border-color"
        ("color-mix(in srgb, " <> var <> " " <> tshow a <> "%, transparent)")

text :: Color -> Int -> Style
text c n =
  css
    ("text-" <> colorName c <> "-" <> tshow n)
    "color"
    ("var(--" <> colorName c <> "-" <> tshow n <> ")")

border :: Color -> Int -> Style
border c n =
  css
    ("border-" <> colorName c <> "-" <> tshow n)
    "border-color"
    ("var(--" <> colorName c <> "-" <> tshow n <> ")")

ring :: Color -> Int -> Style
ring c n =
  css
    ("ring-" <> colorName c <> "-" <> tshow n)
    "--ring-color"
    ("var(--" <> colorName c <> "-" <> tshow n <> ")")

bgWhite :: Style
bgWhite = bg Gray 0

bgTransparent :: Style
bgTransparent = css "bg-transparent" "background-color" "transparent"

textBlack :: Style
textBlack = text Gray 12

textWhite :: Style
textWhite = text Gray 0

borderBlack :: Style
borderBlack = border Gray 12

borderTransparent :: Style
borderTransparent = css "border-transparent" "border-color" "transparent"

--------------------------------------------------------------------------------
-- Borders
--------------------------------------------------------------------------------

border1 :: Style
border1 = css "border" "border-width" "1px"

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
rounded = css "rounded" "border-radius" "var(--radius-2)"

roundedNone :: Style
roundedNone = css "rounded-none" "border-radius" "0"

roundedXl :: Style
roundedXl = css "rounded-xl" "border-radius" "var(--radius-3)"

rounded3Xl :: Style
rounded3Xl = css "rounded-3xl" "border-radius" "var(--radius-5)"

roundedFull :: Style
roundedFull = css "rounded-full" "border-radius" "var(--radius-round)"

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
textSm = css "text-sm" "font-size" "var(--font-size-0)"

textXs :: Style
textXs = css "text-xs" "font-size" "var(--font-size-00)"

textXl :: Style
textXl = css "text-xl" "font-size" "var(--font-size-3)"

text2Xl :: Style
text2Xl = css "text-2xl" "font-size" "var(--font-size-4)"

textLg :: Style
textLg = css "text-lg" "font-size" "var(--font-size-2)"

textBase :: Style
textBase = css "text-base" "font-size" "var(--font-size-1)"

leadingTight :: Style
leadingTight = css "leading-tight" "line-height" "var(--font-lineheight-1)"

textCenter :: Style
textCenter = css "text-center" "text-align" "center"

uppercase :: Style
uppercase = css "uppercase" "text-transform" "uppercase"

trackingWider :: Style
trackingWider = css "tracking-wider" "letter-spacing" "var(--font-letterspacing-3)"

whitespaceNowrap :: Style
whitespaceNowrap = css "whitespace-nowrap" "white-space" "nowrap"

textTruncate :: Style
textTruncate = css "truncate" "text-overflow" "ellipsis"

textLeft :: Style
textLeft = css "text-left" "text-align" "left"

italic :: Style
italic = css "italic" "font-style" "italic"

--------------------------------------------------------------------------------
-- Effects
--------------------------------------------------------------------------------

shadow2Xl :: Style
shadow2Xl = css "shadow-2xl" "box-shadow" "var(--shadow-6)"

shadowXl :: Style
shadowXl = css "shadow-xl" "box-shadow" "var(--shadow-5)"

shadowLg :: Style
shadowLg = css "shadow-lg" "box-shadow" "var(--shadow-4)"

shadowSm :: Style
shadowSm = css "shadow-sm" "box-shadow" "var(--shadow-2)"

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
aspect43 = css "aspect-4/3" "aspect-ratio" "var(--ratio-4-3)"

aspectCard :: Style
aspectCard = css "aspect-card" "aspect-ratio" "63/88"

aspectSquare :: Style
aspectSquare = css "aspect-square" "aspect-ratio" "var(--ratio-square)"

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
duration200 = css "duration-200" "transition-duration" "var(--duration-1)"

easeOut :: Style
easeOut = css "ease-out" "transition-timing-function" "var(--ease-out-3)"

--------------------------------------------------------------------------------
-- Interactions
--------------------------------------------------------------------------------

selectNone :: Style
selectNone = css "select-none" "user-select" "none"

--------------------------------------------------------------------------------
-- Ring/Outline
--------------------------------------------------------------------------------

ring2 :: Style
ring2 = css "ring-2" "box-shadow" "0 0 0 2px var(--ring-color, var(--blue-4))"

ringOffset2 :: Style
ringOffset2 = css "ring-offset-2" "--ring-offset-width" "2px"

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
gap n = css ("gap-" <> tshow n) "gap" (remValue n)

fontSize :: Int -> Style
fontSize n = css ("text-" <> tshow n) "font-size" (tshow n <> "px")

opacity :: Double -> Style
opacity v = css ("opacity-" <> tshow (round (v * 100) :: Int)) "opacity" (tshow v)

borderRadius :: Int -> Style
borderRadius n = css ("rounded-" <> tshow n) "border-radius" (tshow n <> "px")
