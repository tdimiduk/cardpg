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
  , cls

    -- * Modifiers
  , hover
  , hoverProp
  , active
  , activeProp
  , pseudo
  , pseudoProp
  , media
  , mediaProp
  , lastChild
  , lastChildProp

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
  , bottom
  , left
  , right
  , top
  , p
  , px
  , py
  , pt
  , pb
  , pl
  , pr
  , mt
  , mb
  , mb0
  , ml
  , mr
  , Size (..)
  , standardSizes
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
  , canvas
  , surface
  , text1
  , text2

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
  , roundedS
  , roundedNone
  , roundedXl
  , rounded3Xl
  , roundedFull

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

    -- * Sizing/Spacing types
  , sizeValue

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

    -- * Compound Styles
  , flex1
  , full
  ) where

import Data.Text (Text)
import Data.Text qualified as T
import Frontend.Style.Core

----------------------------------------------------------------------------------

spaceXActionStackOverlap :: Style
spaceXActionStackOverlap rest =
  Prop
    "space-x-action-stack-overlap"
    ".space-x-action-stack-overlap > * + *"
    [("margin-left", "calc(var(--size-9) * -0.6)")]
    Nothing
    : rest

spaceY2 :: Style
spaceY2 rest =
  Prop "space-y-2" ".space-y-2 > * + *" [("margin-top", "var(--size-2)")] Nothing
    : rest

lastChild :: Style -> Style
lastChild style rest =
  let props = style []
   in map lastChildProp props ++ rest

lastChildProp :: Prop -> Prop
lastChildProp prop =
  prop
    { propClassName = "last\\:" <> prop.propClassName
    , propSelector = "." <> escapeCss ("last:" <> prop.propClassName) <> ":last-child"
    }

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

data Size
  = S0
  | S0_5
  | S1
  | S2
  | S3
  | S4
  | S5
  | S6
  | S7
  | S8
  | S9
  | S10
  | S11
  | S12
  | S13
  | S14
  | S15
  | Rem Double
  | Vh Double
  | Vw Double
  | Px Double
  | Percent Double
  | Mm Double
  deriving (Show, Eq)

standardSizes :: [Size]
standardSizes = [S0, S0_5, S1, S2, S3, S4, S5, S6, S7, S8, S9, S10, S11, S12, S13, S14, S15]

sizeName :: Size -> Text
sizeName = \case
  S0 -> "0"
  S0_5 -> "0_5"
  S1 -> "1"
  S2 -> "2"
  S3 -> "3"
  S4 -> "4"
  S5 -> "5"
  S6 -> "6"
  S7 -> "7"
  S8 -> "8"
  S9 -> "9"
  S10 -> "10"
  S11 -> "11"
  S12 -> "12"
  S13 -> "13"
  S14 -> "14"
  S15 -> "15"
  Rem d -> "rem-" <> cleanShow d
  Vh d -> "vh-" <> cleanShow d
  Vw d -> "vw-" <> cleanShow d
  Px d -> "px-" <> tshow (round d :: Int)
  Percent d -> "pct-" <> tshow (round d :: Int)
  Mm d -> cleanShow d <> "mm"
  where
    cleanShow d =
      let s = tshow d
       in T.replace "." "_" $ if ".0" `T.isSuffixOf` s then T.dropEnd 2 s else s

sizeValue :: Size -> Text
sizeValue = \case
  S0 -> "0"
  S0_5 -> "var(--size-000)"
  S1 -> "var(--size-1)"
  S2 -> "var(--size-2)"
  S3 -> "var(--size-3)"
  S4 -> "var(--size-4)"
  S5 -> "var(--size-5)"
  S6 -> "var(--size-6)"
  S7 -> "var(--size-7)"
  S8 -> "var(--size-8)"
  S9 -> "var(--size-9)"
  S10 -> "var(--size-10)"
  S11 -> "var(--size-11)"
  S12 -> "var(--size-12)"
  S13 -> "var(--size-13)"
  S14 -> "var(--size-14)"
  S15 -> "var(--size-15)"
  Rem d -> tshow d <> "rem"
  Vh d -> tshow d <> "vh"
  Vw d -> tshow d <> "vw"
  Px d -> tshow d <> "px"
  Percent d -> tshow d <> "%"
  Mm d -> tshow d <> "mm"

w :: Size -> Style
w s = css ("w-" <> sizeName s) "width" (sizeValue s)

h :: Size -> Style
h s = css ("h-" <> sizeName s) "height" (sizeValue s)

wFull :: Style
wFull = w (Percent 100)

hFull :: Style
hFull = h (Percent 100)

wFit :: Style
wFit = css "w-fit" "width" "fit-content"

wCard :: Style
wCard = w (Mm 63)

hCard :: Style
hCard = h (Mm 88)

w8mm :: Style
w8mm = w (Mm 8)

h8mm :: Style
h8mm = h (Mm 8)

hScreen :: Style
hScreen = h (Vh 100)

h2_5 :: Style
h2_5 = h (Percent 40)

bottom :: Size -> Style
bottom s = css ("bottom-" <> sizeName s) "bottom" (sizeValue s)

left :: Size -> Style
left s = css ("left-" <> sizeName s) "left" (sizeValue s)

right :: Size -> Style
right s = css ("right-" <> sizeName s) "right" (sizeValue s)

top :: Size -> Style
top s = css ("top-" <> sizeName s) "top" (sizeValue s)

--------------------------------------------------------------------------------
-- Spacing
--------------------------------------------------------------------------------

p :: Size -> Style
p s = css ("p-" <> sizeName s) "padding" (sizeValue s)

px :: Size -> Style
px s = css' ("px-" <> sizeName s) [("padding-left", v), ("padding-right", v)]
  where
    v = sizeValue s

py :: Size -> Style
py s = css' ("py-" <> sizeName s) [("padding-top", v), ("padding-bottom", v)]
  where
    v = sizeValue s

pt :: Size -> Style
pt s = css ("pt-" <> sizeName s) "padding-top" (sizeValue s)

pb :: Size -> Style
pb s = css ("pb-" <> sizeName s) "padding-bottom" (sizeValue s)

pl :: Size -> Style
pl s = css ("pl-" <> sizeName s) "padding-left" (sizeValue s)

pr :: Size -> Style
pr s = css ("pr-" <> sizeName s) "padding-right" (sizeValue s)

mt :: Size -> Style
mt s = css ("mt-" <> sizeName s) "margin-top" (sizeValue s)

mb :: Size -> Style
mb s = css ("mb-" <> sizeName s) "margin-bottom" (sizeValue s)

mb0 :: Style
mb0 = mb S0

ml :: Size -> Style
ml s = css ("ml-" <> sizeName s) "margin-left" (sizeValue s)

mr :: Size -> Style
mr s = css ("mr-" <> sizeName s) "margin-right" (sizeValue s)

gap :: Size -> Style
gap s = css ("gap-" <> sizeName s) "gap" (sizeValue s)

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

data Color = Gray | Red | Blue | Indigo | Yellow | Amber | White | Black | Transparent | Surface | Text
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

-- | Semantic adaptive background (canvas/base)
canvas :: Style
canvas = css "canvas" "background-color" "var(--surface-1)"

-- | Semantic adaptive background (surface/card)
surface :: Int -> Style
surface n = css ("surface-" <> tshow n) "background-color" ("var(--surface-" <> tshow n <> ")")

-- | Semantic adaptive text (primary)
text1 :: Style
text1 = css "text-1" "color" "var(--text-1)"

-- | Semantic adaptive text (secondary)
text2 :: Style
text2 = css "text-2" "color" "var(--text-2)"

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

roundedS :: Size -> Style
roundedS s = css ("rounded-" <> sizeName s) "border-radius" (sizeValue s)

roundedNone :: Style
roundedNone = css "rounded-none" "border-radius" "0"

roundedXl :: Style
roundedXl = css "rounded-xl" "border-radius" "var(--radius-4)"

rounded3Xl :: Style
rounded3Xl = css "rounded-3xl" "border-radius" "var(--radius-6)"

roundedFull :: Style
roundedFull = css "rounded-full" "border-radius" "9999px"

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
wCardHand = w (Vh 16)

mlCardOverlap :: Style
mlCardOverlap = css "-ml-card-overlap" "margin-left" "-12vh"

originBottom :: Style
originBottom = css "origin-bottom" "transform-origin" "bottom"

translateYNeg4 :: Style
translateYNeg4 = css "-translate-y-4" "transform" "translateY(calc(var(--size-4) * -1))"

translateYNeg8 :: Style
translateYNeg8 = css "-translate-y-8" "transform" "translateY(calc(var(--size-8) * -1))"

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
-- Parameterized Styles (Deprecated - use Size ADT)
--------------------------------------------------------------------------------

fontSize :: Int -> Style
fontSize n = css ("text-" <> tshow n) "font-size" (tshow n <> "px")

opacity :: Double -> Style
opacity v = css ("opacity-" <> tshow (round (v * 100) :: Int)) "opacity" (tshow v)
