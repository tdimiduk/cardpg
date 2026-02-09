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

import Frontend.Style.Common (Style)
import Frontend.Style.DSL

--------------------------------------------------------------------------------

-- * Card Style Groups

--------------------------------------------------------------------------------

-- | Base classes for the card container.
cardBase :: Style
cardBase =
  flexCol
    . relative
    . p2_5mm -- Padding around the card content within the border
    . overflowHidden

-- ** Screen Styles

-- Shared visuals used by both full cards and spines/strips
cardScreenVisuals :: Style
cardScreenVisuals =
  bgSlate900
    . textSlate200
    . border2
    . borderSlate600
    . rounded3mm
    . shadowXl

cardScreen :: Style
cardScreen = cardScreenVisuals

-- ** Print Styles

cardPrint :: Style
cardPrint =
  wCard
    . hCard
    . bgWhite
    . textBlack
    . border
    . borderBlack
    . rounded3mm

-- ** Compact Variants

-- | Cost hexagon styling for CardRow (explicit small size)
costRow :: Style
costRow = w4 . h4 . textSlate200

cardRow :: Style
cardRow =
  flexRow
    . itemsCenter
    . gap1
    . p1
    . bgSlate900
    . border
    . borderSlate700
    . rounded

standardCardSize :: Style
standardCardSize = wCard . hCard

standardCardAspectRatio :: Style
standardCardAspectRatio = aspectCard

cardHandWidth :: Style
cardHandWidth = wCardHand

plannedCardOverlap :: Style
plannedCardOverlap = mlCardOverlap

--------------------------------------------------------------------------------

-- * Element Style Groups

--------------------------------------------------------------------------------

-- ** Art

artBase :: Style
artBase =
  wFull
    . aspect43
    . mb2mm
    . bgGray300
    . rounded1mm
    . overflowHidden

artScreen :: Style
artScreen = border . borderSlate700

artPrint :: Style
artPrint = border . borderBlack . grayscale

-- ** Name

nameBase :: Style
nameBase =
  fontBold
    . textSm
    . leadingTight
    . mb2mm

nameScreen :: Style
nameScreen = textSlate100

namePrint :: Style
namePrint = textBlack

-- ** Cost

costBase :: Style
costBase =
  absolute
    . top2mm
    . right2mm
    . w8mm
    . h8mm
    . z10
    . flex
    . itemsCenter
    . justifyCenter
    . fontBold

costScreen :: Style
costScreen = textSlate200

costPrint :: Style
costPrint = textBlack

-- ** Textbox

textboxBase :: Style
textboxBase =
  flex1
    . textXs
    . border02mm
    . p2mm
    . grow

-- Note: The child selectors like "[&_p]:mt-0" cannot be expressed as simple atoms.
-- They require custom CSS rules which we'll handle separately or inline.

textboxScreen :: Style
textboxScreen = bgSlate800 . borderSlate600 . rounded2mm . textSlate300

textboxPrint :: Style
textboxPrint = roundedNone . bgTransparent . borderBlack

--------------------------------------------------------------------------------

-- * Icon Style Groups

--------------------------------------------------------------------------------

--------------------------------------------------------------------------------

-- * Interactables

--------------------------------------------------------------------------------

cardPlayable :: Style
cardPlayable =
  translateYNeg4
    . scale105
    . transitionAll
    . duration200
    . cursorPointer
    . shadowLg
    . ring2
    . ringBlue400
    . z20

-- Note: hover: variants need special handling - these are the applied states

cardNotPlayable :: Style
cardNotPlayable = opacity75 . grayscale50 . cursorNotAllowed

--------------------------------------------------------------------------------

-- * Staging Styles

--------------------------------------------------------------------------------

-- | Style for the Action card in the staging area
stagedActionCard :: Style
stagedActionCard =
  relative
    . group
    . cursorPointer
    . originBottom
    . w40
    . shrink0
    . z10
    . transitionTransform

-- Note: hover:z-30, hover:scale-105 are variant states

-- | Style for Resource cards in the staging area
stagedResourceCard :: Style
stagedResourceCard =
  relative
    . group
    . cursorPointer
    . originBottom
    . w40
    . shrink0
    . transitionAll
    . duration200

-- Note: hover:-translate-y-4, hover:z-20 are variant states
