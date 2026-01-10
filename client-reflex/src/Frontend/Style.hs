{-# LANGUAGE OverloadedStrings #-}

-- | Centralized styling utilities for the client-reflex frontend.
--
-- This module provides:
--
-- * 'CssClass' newtype for type-safe Tailwind class composition
-- * Layout combinators ('row', 'col', 'between', etc.) for common patterns
-- * Semantic style groups for cards and UI components
--
-- == Usage
--
-- Prefer combinators for common layouts:
--
-- @
-- row $ do
--   component "name" nameClasses $ text cardName
--   spacer
--   renderCost cost
-- @
--
-- Use 'divStyle' with class lists for custom layouts. Mix atoms and strings:
--
-- @
-- divStyle [flex, "gap-4", "p-2"] $ ...
-- @
module Frontend.Style
  ( -- * Core Types
    CssClass (..)
  , classes

    -- * Element Helpers
  , divStyle
  , elStyle
  , elStyle'
  , component

    -- * Layout Combinators
  , row
  , rowGap
  , rowWith
  , col
  , colGap
  , colWith
  , centered
  , between
  , spacer
  , stack
  , overlay
  , overlayBottom
  , overlayBottomWith

    -- * Shared Atoms

  --
  -- These are commonly used across multiple files. For one-off classes,
  -- use string literals directly: @"gap-4"@, @"text-slate-500"@, etc.

    -- ** Layout
  , flex
  , flexCol
  , flexRow
  , flex1
  , itemsCenter
  , itemsEnd
  , justifyCenter
  , justifyBetween
  , justifyEnd
  , relative
  , absolute
  , bottom0
  , left0
  , right0
  , z40
  , grow

    -- ** Interaction
  , cursorPointer
  , pointerEventsNone
  , pointerEventsAuto
  , group

    -- ** Appearance
  , hidden
  , truncateText
  , clipText
  , fontBold
  , textSm
  , textXs
  , rounded
  , shadowXl
  , shadow
  , backdropBlur

    -- * Card Style Groups (Screen)
  , cardBase
  , cardScreen
  , artBase
  , artScreen
  , nameBase
  , nameScreen
  , costBase
  , costScreen
  , textboxBase
  , textboxScreen

    -- * Card Sizes
  , plannedCardOverlap
  , cardHandWidth
  , standardCardSize
  , standardCardAspectRatio

    -- * Card Style Groups (Print)
  , cardPrint
  , artPrint
  , namePrint
  , costPrint
  , textboxPrint

    -- * Card Compact Variants
  , cardRow
  , costRow

    -- * Icon Style Groups
  , resourceIcon
  , resourceTextBase
  , resourceTextPrint
  , iconInline
  , iconBlock
  , iconResponsive

    -- * Resource Colors
  , textRed500
  , textYellow400
  , textBlue500

    -- * Interactables
  , buttonSecondary
  , buttonPrimary
  , buttonDisabled
  , cursorNotAllowed
  , cardPlayable
  , cardNotPlayable

    -- * Staging Styles
  , stagedActionCard
  , stagedResourceCard

    -- * Layout Grids
  , cardGrid
  , deckGrid
  ) where

import Data.Coerce (coerce)
import Data.List.NonEmpty (toList)
import Data.Semigroup (Semigroup (..))
import Data.String (IsString (..))
import Data.Text (Text)
import Data.Text qualified as T
import Reflex.Dom.Core
  ( DomBuilder
  , DomBuilderSpace
  , Element
  , EventResult
  , blank
  , divClass
  , elAttr
  , elClass
  , elClass'
  , (=:)
  )

--------------------------------------------------------------------------------

-- * Core Types

--------------------------------------------------------------------------------

-- | A newtype wrapper for a single Tailwind class (or a small group of classes
-- that always go together). Use 'IsString' for convenient string literals.
newtype CssClass = CssClass {unCssClass :: Text}
  deriving (Eq, Show, Ord)

instance IsString CssClass where
  fromString = CssClass . T.pack

instance Semigroup CssClass where
  (CssClass a) <> (CssClass b) = CssClass (a <> " " <> b)
  sconcat = CssClass . T.intercalate " " . coerce . toList

instance Monoid CssClass where
  mempty = CssClass ""
  mconcat = CssClass . T.intercalate " " . coerce

-- | Convert a list of classes to a space-separated Text for use in DOM attributes.
classes :: [CssClass] -> Text
classes = coerce . mconcat

--------------------------------------------------------------------------------

-- * Element Helpers

--------------------------------------------------------------------------------

-- | Helper to create a div with a list of typed classes.
divStyle :: (DomBuilder t m) => [CssClass] -> m a -> m a
divStyle cls = divClass (classes cls)

-- | Helper to create an element with a list of typed classes.
elStyle :: (DomBuilder t m) => Text -> [CssClass] -> m a -> m a
elStyle tag cls = elClass tag (classes cls)

-- | Helper to create an element with a list of typed classes, returning the element and result.
elStyle'
  :: (DomBuilder t m) => Text -> [CssClass] -> m a -> m (Element EventResult (DomBuilderSpace m) t, a)
elStyle' tag cls = elClass' tag (classes cls)

-- | Create a semantic div with data-component attribute for testing/inspection.
component :: (DomBuilder t m) => Text -> [CssClass] -> m a -> m a
component name cls = elAttr "div" ("class" =: classes cls <> "data-component" =: name)

--------------------------------------------------------------------------------

-- * Layout Combinators

--------------------------------------------------------------------------------

-- | A horizontal flex container.
row :: (DomBuilder t m) => m a -> m a
row = divStyle [flex, flexRow]

-- | A horizontal flex container with a gap.
rowGap :: (DomBuilder t m) => CssClass -> m a -> m a
rowGap gap = divStyle [flex, flexRow, gap]

-- | A horizontal flex container with arbitrary classes.
rowWith :: (DomBuilder t m) => [CssClass] -> m a -> m a
rowWith cls = divStyle ([flex, flexRow] <> cls)

-- | A vertical flex container.
col :: (DomBuilder t m) => m a -> m a
col = divStyle [flex, flexCol]

-- | A vertical flex container with a gap.
colGap :: (DomBuilder t m) => CssClass -> m a -> m a
colGap gap = divStyle [flex, flexCol, gap]

-- | A vertical flex container with arbitrary classes.
colWith :: (DomBuilder t m) => [CssClass] -> m a -> m a
colWith cls = divStyle ([flex, flexCol] <> cls)

-- | Flex container centered both axes.
centered :: (DomBuilder t m) => m a -> m a
centered = divStyle [flex, itemsCenter, justifyCenter]

-- | Row with items pushed to opposite ends.
between :: (DomBuilder t m) => m a -> m a
between = divStyle [flex, flexRow, justifyBetween, itemsCenter]

-- | Spacer that pushes siblings apart (grows to fill available space).
spacer :: (DomBuilder t m) => m ()
spacer = divStyle [grow] blank

-- | Creates a relative positioning context (for absolutely positioned children).
stack :: (DomBuilder t m) => m a -> m a
stack = divStyle [relative]

-- | An absolute overlay that fills its parent.
overlay :: (DomBuilder t m) => m a -> m a
overlay = divStyle [absolute, "inset-0"]

-- | Bottom-anchored overlay (for hand/action areas).
overlayBottom :: (DomBuilder t m) => m a -> m a
overlayBottom = divStyle [absolute, "bottom-0", "left-0", "right-0"]

-- | Bottom-anchored overlay with additional classes.
overlayBottomWith :: (DomBuilder t m) => [CssClass] -> m a -> m a
overlayBottomWith cls = divStyle ([absolute, "bottom-0", "left-0", "right-0"] <> cls)

--------------------------------------------------------------------------------

-- * Shared Atoms

--
-- These are exported because they're used across multiple files. For one-off
-- values like "gap-4", "p-2", "w-72", use string literals directly.
--------------------------------------------------------------------------------

-- ** Layout

flex :: CssClass
flex = "flex"

flexCol :: CssClass
flexCol = "flex-col"

flexRow :: CssClass
flexRow = "flex-row"

flex1 :: CssClass
flex1 = "flex-1"

itemsCenter :: CssClass
itemsCenter = "items-center"

itemsEnd :: CssClass
itemsEnd = "items-end"

justifyCenter :: CssClass
justifyCenter = "justify-center"

justifyBetween :: CssClass
justifyBetween = "justify-between"

justifyEnd :: CssClass
justifyEnd = "justify-end"

relative :: CssClass
relative = "relative"

absolute :: CssClass
absolute = "absolute"

bottom0 :: CssClass
bottom0 = "bottom-0"

left0 :: CssClass
left0 = "left-0"

right0 :: CssClass
right0 = "right-0"

z40 :: CssClass
z40 = "z-40"

grow :: CssClass
grow = "grow"

-- ** Interaction

cursorPointer :: CssClass
cursorPointer = "cursor-pointer"

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

shadowXl :: CssClass
shadowXl = "shadow-xl"

shadow :: Text -> CssClass
shadow s = CssClass $ "shadow-" <> s

backdropBlur :: Text -> CssClass
backdropBlur s = CssClass $ "backdrop-blur-" <> s

--------------------------------------------------------------------------------

-- * Icon Style Groups

--------------------------------------------------------------------------------

resourceIcon :: [CssClass]
resourceIcon = ["inline-block"]

resourceTextBase :: [CssClass]
resourceTextBase = ["fill-slate-200", "font-sans", fontBold]

resourceTextPrint :: [CssClass]
resourceTextPrint = ["print:fill-black"]

iconInline :: [CssClass]
iconInline =
  [ "w-[1em]"
  , "h-[1em]"
  , "ml-[-0.15em]"
  , "mr-[-0.05em]"
  , "align-middle"
  , "inline-block"
  , "transform"
  , "translate-y-[-0.1em]"
  ]

iconBlock :: [CssClass]
iconBlock = ["w-10", "h-10", fontBold, "text-xl"]

iconResponsive :: [CssClass]
iconResponsive = ["h-[30%]", "w-auto", "aspect-square", fontBold]

-- Resource colors (used in Html.hs for icon coloring)
textRed500 :: CssClass
textRed500 = "text-red-500"

textYellow400 :: CssClass
textYellow400 = "text-yellow-400"

textBlue500 :: CssClass
textBlue500 = "text-blue-500"

--------------------------------------------------------------------------------

-- * Card Style Groups

--------------------------------------------------------------------------------

-- ** Base (shared between screen and print)

cardCanonicalWidth :: CssClass
cardCanonicalWidth = "w-[63mm]"

cardCanonicalHeight :: CssClass
cardCanonicalHeight = "h-[88mm]"

-- | Width for cards in the hand/planned action area (approx 160px)
cardHandWidth :: CssClass
cardHandWidth = "w-40"

-- | Overlap for stacked cards in planned actions (-128px)
plannedCardOverlap :: CssClass
plannedCardOverlap = "[&>*:not(:first-child)]:-ml-32"

standardCardSize :: CssClass
standardCardSize = cardCanonicalWidth <> cardCanonicalHeight

standardCardAspectRatio :: CssClass
standardCardAspectRatio = "aspect-[63/88]"

cardBase :: [CssClass]
cardBase =
  [ flex
  , flexCol
  , standardCardSize
  , "break-inside-avoid"
  , relative
  , "overflow-hidden"
  ]

artBase :: [CssClass]
artBase = []

nameBase :: [CssClass]
nameBase = [fontBold]

costBase :: [CssClass]
costBase = ["w-[1.4em]", "h-[1.4em]", "-my-[0.1em]"]

textboxBase :: [CssClass]
textboxBase =
  [ "flex-1"
  , textXs
  , "border-[0.2mm]"
  , "p-[2mm]"
  , grow
  , "[&_p]:mt-0"
  , "[&_p]:mb-[0.1em]"
  , "[&_p]:leading-tight"
  ]

-- ** Screen Styles

--
-- Shared visuals used by both full cards and spines/strips
cardScreenVisuals :: [CssClass]
cardScreenVisuals =
  [ "bg-slate-900"
  , "text-slate-200"
  , "border-2"
  , "border-slate-600"
  , "rounded-[3mm]"
  , shadowXl
  ]

cardScreen :: [CssClass]
cardScreen = cardScreenVisuals <> ["p-1.5"]

artScreen :: [CssClass]
artScreen = [grow, "h-full", "rounded-sm", "bg-slate-800"]

nameScreen :: [CssClass]
nameScreen = [textSm, "text-slate-200"]

costScreen :: [CssClass]
costScreen = ["text-slate-200"]

textboxScreen :: [CssClass]
textboxScreen = [rounded, "bg-slate-800/50", "border-slate-600"]

-- ** Print Styles

cardPrint :: [CssClass]
cardPrint =
  [ "aspect-auto" -- Override for fixed dimensions
  , "p-[2mm]"
  , "m-0"
  , "w-[56mm]"
  , "h-[80mm]" -- Slightly smaller for cutting margin
  , "border-[0.2mm]"
  , "rounded-none"
  , "bg-white"
  , "text-black"
  , "shadow-none"
  , "border-black"
  ]

artPrint :: [CssClass]
artPrint = ["h-[33mm]", "rounded-none", "bg-transparent"]

namePrint :: [CssClass]
namePrint = [textSm, "text-black"]

costPrint :: [CssClass]
costPrint = ["text-black"]

textboxPrint :: [CssClass]
textboxPrint = ["rounded-none", "bg-transparent", "border-black"]

-- ** Compact Variants

-- | Cost hexagon styling for CardRow (explicit small size)
costRow :: [CssClass]
costRow = ["w-4", "h-4", "text-slate-200"]

cardRow :: [CssClass]
cardRow =
  [ flex
  , flexRow
  , itemsCenter
  , "gap-1"
  , "p-1"
  , "bg-slate-900"
  , "border"
  , "border-slate-700"
  , rounded
  ]

--------------------------------------------------------------------------------

-- * Layout Grids

--------------------------------------------------------------------------------

cardGrid :: [CssClass]
cardGrid =
  [ "grid"
  , "grid-cols-[repeat(auto-fill,minmax(240px,1fr))]"
  , "p-4"
  , "print:gap-0"
  , "print:p-0"
  , "print:block"
  ]

deckGrid :: [CssClass]
deckGrid =
  [ "grid"
  , "gap-[3mm]"
  , "justify-start"
  , "grid-cols-[repeat(3,56mm)]"
  ]

--------------------------------------------------------------------------------

-- * Interactables

--------------------------------------------------------------------------------

-- | Secondary/cancel button styling
buttonSecondary :: [CssClass]
buttonSecondary =
  [ flex1
  , "py-2"
  , rounded
  , "border"
  , "border-slate-600"
  , "text-slate-400"
  , fontBold
  , "hover:bg-slate-800"
  , "transition-colors"
  ]

-- | Primary button styling (active state)
buttonPrimary :: [CssClass]
buttonPrimary =
  [ flex1
  , "py-2"
  , rounded
  , fontBold
  , "transition-colors"
  , "bg-indigo-600"
  , "text-white"
  , "hover:bg-indigo-500"
  ]

-- | Disabled button styling
buttonDisabled :: [CssClass]
buttonDisabled =
  [ flex1
  , "py-2"
  , rounded
  , fontBold
  , "transition-colors"
  , "bg-slate-800"
  , "text-slate-600"
  , cursorNotAllowed
  ]

cursorNotAllowed :: CssClass
cursorNotAllowed = "cursor-not-allowed"

-- | Style for cards that can be played (valid cost)
cardPlayable :: [CssClass]
cardPlayable = ["ring-2", "ring-indigo-400", "ring-offset-1"]

-- | Style for cards that cannot be played (invalid cost)
cardNotPlayable :: [CssClass]
cardNotPlayable = ["opacity-75"]

--------------------------------------------------------------------------------

-- * Staging Styles

--------------------------------------------------------------------------------

-- | Style for the Action card in the staging area
stagedActionCard :: [CssClass]
stagedActionCard =
  [ relative
  , group
  , cursorPointer
  , "origin-bottom"
  , "w-40"
  , "shrink-0"
  , "z-10"
  , "hover:z-30"
  , "hover:scale-105"
  , "transition-transform"
  ]

-- | Style for Resource cards in the staging area
stagedResourceCard :: [CssClass]
stagedResourceCard =
  [ relative
  , group
  , cursorPointer
  , "origin-bottom"
  , "w-40"
  , "shrink-0"
  , "transition-all"
  , "duration-200"
  , "hover:-translate-y-4"
  , "hover:z-20"
  ]
