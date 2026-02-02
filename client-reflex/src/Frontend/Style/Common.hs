{-# LANGUAGE OverloadedStrings #-}

-- | Common styling atoms and types.
module Frontend.Style.Common
  ( -- * Core Types
    CssClass (..)
  , classes

    -- * Element Helpers
  , divStyle
  , elStyle
  , elStyle'
  , component
  , testId

    -- * Shared Atoms
  , flex
  , flexRow
  , flexCol
  , itemsCenter
  , justifyCenter
  , justifyBetween
  , grow
  , full
  , absolute
  , relative
  , cursorPointer
  , shadowXl
  , pointerEventsNone
  , pointerEventsAuto
  , group

    -- * Appearance
  , hidden
  , truncateText
  , clipText
  , fontBold
  , textSm
  , textXs
  , rounded
  , uppercase
  , trackingWider

    -- * Icon Atoms
  , iconBlock
  , iconResponsive
  , iconInline
  , resourceIcon
  , resourceTextBase
  , resourceTextPrint

    -- * Resource Colors
  , textRed500
  , textYellow400
  , textBlue500
  , flex1
  , shadow
  , backdropBlur
  , bottom0
  , left0
  , right0
  , z40
  , itemsEnd
  ) where

import Data.Coerce (coerce)
import Data.Map (Map)

import Data.String (IsString (..))
import Data.Text (Text, unwords)
import Reflex.Dom.Core

--------------------------------------------------------------------------------

-- * Core Types

--------------------------------------------------------------------------------

newtype CssClass = CssClass {unCssClass :: Text}
  deriving (Eq, Show, IsString)
  deriving newtype (Semigroup, Monoid)

classes :: [CssClass] -> Text
classes = unwords . coerce

--------------------------------------------------------------------------------

-- * Element Helpers

--------------------------------------------------------------------------------

-- | Helper to create a div with a list of typed classes.
divStyle :: (DomBuilder t m) => [CssClass] -> m a -> m a
divStyle cls = divClass (classes cls)

-- | Helper to create an element with a list of typed classes.
elStyle :: (DomBuilder t m) => Text -> [CssClass] -> m a -> m a
elStyle tagName cls = elClass tagName (classes cls)

-- | Helper to create an element with typed classes and attributes.
elStyle'
  :: (DomBuilder t m)
  => Text -> [CssClass] -> Map Text Text -> m a -> m (Element EventResult (DomBuilderSpace m) t, a)
elStyle' tagName cls attrs = elAttr' tagName (("class" =: classes cls) <> attrs)

-- | A named component div (useful for debugging/structure).
component :: (DomBuilder t m) => Text -> [CssClass] -> m a -> m a
component name cls = divClass (classes cls <> " " <> name)

-- | Add a data-testid attribute for testing.
testId :: Text -> Map Text Text
testId = ("data-testid" =:)

--------------------------------------------------------------------------------

-- * Shared Atoms

--------------------------------------------------------------------------------

-- ** Layout

flex :: CssClass
flex = "flex"

flexRow :: CssClass
flexRow = "flex-row"

flexCol :: CssClass
flexCol = "flex-col"

itemsCenter :: CssClass
itemsCenter = "items-center"

justifyCenter :: CssClass
justifyCenter = "justify-center"

justifyBetween :: CssClass
justifyBetween = "justify-between"

grow :: CssClass
grow = "grow"

full :: CssClass
full = "w-full h-full"

absolute :: CssClass
absolute = "absolute"

relative :: CssClass
relative = "relative"

cursorPointer :: CssClass
cursorPointer = "cursor-pointer"

shadowXl :: CssClass
shadowXl = "shadow-xl"

pointerEventsNone :: CssClass
pointerEventsNone = "pointer-events-none"

pointerEventsAuto :: CssClass
pointerEventsAuto = "pointer-events-auto"

group :: CssClass
group = "group"

-- ** Appearance

hidden :: CssClass
hidden = "hidden"

truncateText :: CssClass
truncateText = "truncate"

clipText :: [CssClass]
clipText = ["overflow-hidden", "whitespace-nowrap"]

fontBold :: CssClass
fontBold = "font-bold"

textSm :: CssClass
textSm = "text-sm"

textXs :: CssClass
textXs = "text-xs"

rounded :: CssClass
rounded = "rounded"

-- ** Icon Atoms

iconBlock :: [CssClass]
iconBlock = ["w-10", "h-10", fontBold, "text-xl"]

iconResponsive :: [CssClass]
iconResponsive = ["h-[30%]", "w-auto", "aspect-square", fontBold]

iconInline :: [CssClass]
iconInline = ["inline-block", "h-[0.8em]", "w-auto", "align-text-bottom"]

-- Resource colors (used in Html.hs for icon coloring)
textRed500 :: CssClass
textRed500 = "text-red-500"

textYellow400 :: CssClass
textYellow400 = "text-yellow-400"

textBlue500 :: CssClass
textBlue500 = "text-blue-500"

uppercase :: CssClass
uppercase = "uppercase"

trackingWider :: CssClass
trackingWider = "tracking-wider"

-- ** Icon Atoms

resourceIcon :: [CssClass]
resourceIcon = ["w-4", "h-4"]

resourceTextBase :: [CssClass]
resourceTextBase = [fontBold]

resourceTextPrint :: [CssClass]
resourceTextPrint = ["text-black"]

flex1 :: CssClass
flex1 = "flex-1"

shadow :: Text -> CssClass
shadow size = CssClass $ "shadow-" <> size

backdropBlur :: Text -> CssClass
backdropBlur size = CssClass $ "backdrop-blur-" <> size

bottom0 :: CssClass
bottom0 = "bottom-0"

left0 :: CssClass
left0 = "left-0"

right0 :: CssClass
right0 = "right-0"

z40 :: CssClass
z40 = "z-40"

itemsEnd :: CssClass
itemsEnd = "items-end"
