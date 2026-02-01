{-# LANGUAGE OverloadedStrings #-}

-- | Centralized styling utilities for the client-reflex frontend.
--
-- This module acts as an aggregate for domain-specific styles.
-- Generic styling and layout have been moved to:
--
-- * 'Frontend.Style.Common' (basic types and atoms)
-- * 'Frontend.Style.Layout' (layout combinators)
--
-- This module retains component-specific style groups.
module Frontend.Style
  ( -- * Card Style Groups
    cardBase
  , cardScreen
  , cardPrint
  , cardRow
  , cardHandWidth
  , standardCardSize
  , standardCardAspectRatio
  , plannedCardOverlap

    -- * Art Style Groups
  , artBase
  , artScreen
  , artPrint

    -- * Name Style Groups
  , nameBase
  , nameScreen
  , namePrint

    -- * Cost Style Groups
  , costBase
  , costScreen
  , costPrint
  , costRow

    -- * Textbox Style Groups
  , textboxBase
  , textboxScreen
  , textboxPrint

    -- * Interactables
  , cardPlayable
  , cardNotPlayable

    -- * Staging Styles
  , stagedActionCard
  , stagedResourceCard
  ) where

import Frontend.Style.Common

--------------------------------------------------------------------------------

-- * Card Style Groups

--------------------------------------------------------------------------------

-- | Base classes for the card container.
cardBase :: [CssClass]
cardBase =
  [ flex
  , flexCol
  , relative
  , "p-[2.5mm]" -- Padding around the card content within the border
  , "overflow-hidden"
  ]

-- ** Screen Styles

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
cardScreen = cardScreenVisuals

-- ** Print Styles

cardPrint :: [CssClass]
cardPrint =
  [ "w-[63mm]"
  , "h-[88mm]"
  , "bg-white"
  , "text-black"
  , "border"
  , "border-black"
  , "rounded-[3mm]"
  ]

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

standardCardSize :: [CssClass]
standardCardSize = ["w-[63mm]", "h-[88mm]"]

standardCardAspectRatio :: [CssClass]
standardCardAspectRatio = ["aspect-[63/88]"]

cardHandWidth :: [CssClass]
cardHandWidth = ["w-[16vh]"]

plannedCardOverlap :: [CssClass]
plannedCardOverlap = ["-ml-[12vh]"]

--------------------------------------------------------------------------------

-- * Element Style Groups

--------------------------------------------------------------------------------

-- ** Art

artBase :: [CssClass]
artBase =
  [ "w-full"
  , "aspect-[4/3]"
  , "mb-[2mm]"
  , "bg-gray-300"
  , "rounded-[1mm]"
  , "overflow-hidden"
  ]

artScreen :: [CssClass]
artScreen = ["border", "border-slate-700"]

artPrint :: [CssClass]
artPrint = ["border", "border-black", "grayscale"]

-- ** Name

nameBase :: [CssClass]
nameBase =
  [ fontBold
  , "text-sm"
  , "leading-tight"
  , "mb-[2mm]"
  ]

nameScreen :: [CssClass]
nameScreen = ["text-slate-100"]

namePrint :: [CssClass]
namePrint = ["text-black"]

-- ** Cost

costBase :: [CssClass]
costBase =
  [ absolute
  , "top-[2mm]"
  , "right-[2mm]"
  , "w-[8mm]"
  , "h-[8mm]"
  , "z-10"
  , flex
  , itemsCenter
  , justifyCenter
  , fontBold
  ]

costScreen :: [CssClass]
costScreen = ["text-slate-200"]

costPrint :: [CssClass]
costPrint = ["text-black"]

-- ** Textbox

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

textboxScreen :: [CssClass]
textboxScreen = ["bg-slate-800", "border-slate-600", "rounded-[2mm]", "text-slate-300"]

textboxPrint :: [CssClass]
textboxPrint = ["rounded-none", "bg-transparent", "border-black"]

--------------------------------------------------------------------------------

-- * Icon Style Groups

--------------------------------------------------------------------------------

--------------------------------------------------------------------------------

-- * Interactables

--------------------------------------------------------------------------------

cardPlayable :: [CssClass]
cardPlayable =
  [ "hover:-translate-y-4"
  , "hover:scale-105"
  , "transition-all"
  , "duration-200"
  , "cursor-pointer"
  , "shadow-lg"
  , "ring-2"
  , "ring-blue-400"
  , "z-20"
  ]

cardNotPlayable :: [CssClass]
cardNotPlayable = ["opacity-75", "grayscale-[50%]", "cursor-not-allowed"]

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
