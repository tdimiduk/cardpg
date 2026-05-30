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
  ( -- * Re-exports
    module Frontend.Style.DSL
  , module Frontend.Style.Common
  , module Frontend.Style.Layout

    -- * Card Style Groups
  , cardBase
  , cardScreen
  , cardPrint
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

    -- * Textbox Style Groups
  , textboxBase
  , textboxScreen
  , textboxPrint

    -- * Card Component Styles
  , cardRuleStyle
  , stagedActionCard
  , stagedResourceCard
  ) where

import Frontend.Style.Common
import Frontend.Style.DSL
import Frontend.Style.DSL qualified as S
import Frontend.Style.Layout

--------------------------------------------------------------------------------

-- * Card Style Groups

--------------------------------------------------------------------------------

-- | Base classes for the card container.
cardBase :: Style
cardBase =
  S.wFull
    . flexCol
    . relative
    . overflowHidden
    . standardCardAspectRatio

-- ** Screen Styles

-- Shared visuals used by both full cards and spines/strips
cardScreenVisuals :: Style
cardScreenVisuals =
  S.cls "double-frame-gold"
    . S.bg S.Gray 12
    . S.text S.Gray 2
    . S.roundedS (S.Mm 3)

cardScreen :: Style
cardScreen = cardHandWidth . cardScreenVisuals . S.p S.S2

-- ** Print Styles

cardPrint :: Style
cardPrint =
  wCard
    . hCard
    . bgWhite
    . textBlack
    . S.border1
    . borderBlack
    . S.roundedS (S.Mm 3)
    . S.p (S.Mm 2.5)

-- ** Compact Variants

standardCardSize :: Style
standardCardSize = wCard . hCard

standardCardAspectRatio :: Style
standardCardAspectRatio = aspectCard

cardHandWidth :: Style
cardHandWidth = wCardHand

plannedCardOverlap :: Style
plannedCardOverlap = spaceXActionStackOverlap

--------------------------------------------------------------------------------

-- * Element Style Groups

--------------------------------------------------------------------------------

-- ** Art

artBase :: Style
artBase = id

artScreen :: Style
artScreen =
  grow
    . hFull
    . S.roundedS (S.Mm 2)
    . S.css "bg-mystic-art" "background" "radial-gradient(circle, #252220 0%, #12100f 100%)"
    . S.border1
    . S.border S.Gray 9

artPrint :: Style
artPrint = S.h (S.Mm 33) . S.border1 . borderBlack . grayscale . roundedNone . bgTransparent

-- ** Name

nameBase :: Style
nameBase =
  S.fontBold
    . S.cls "fantasy-font"
    . S.textSm
    . S.leadingTight
    . S.uppercase
    . S.mb S.S1

nameScreen :: Style
nameScreen = S.css "text-gold-bright" "color" "var(--color-gold-bright)"

namePrint :: Style
namePrint = textBlack

-- ** Cost

costBase :: Style
costBase =
  w (Em 1.4)
    . h (Em 1.4)
    . mt (Em (-0.1))
    . mb (Em (-0.1))
    . z 10
    . flex
    . itemsCenter
    . justifyCenter
    . fontBold
    . S.cls "fantasy-font"

costScreen :: Style
costScreen = S.text S.Gray 2

costPrint :: Style
costPrint = textBlack

-- ** Textbox

textboxBase :: Style
textboxBase =
  S.flex1
    . S.textXs
    . S.border1
    . S.p S.S1
    . S.grow

-- Note: The child selectors like "[&_p]:mt-0" cannot be expressed as simple atoms.
-- They require custom CSS rules which we'll handle separately or inline.

textboxScreen :: Style
textboxScreen =
  S.css "bg-obsidian-textbox" "background-color" "rgba(18, 16, 15, 0.85)"
    . S.border1
    . S.border S.Gray 9
    . S.roundedS (S.Mm 2)
    . S.text S.Gray 2

textboxPrint :: Style
textboxPrint = roundedNone . bgTransparent . borderBlack

--------------------------------------------------------------------------------

-- * Icon Style Groups

--------------------------------------------------------------------------------

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
    . cardHandWidth
    . shrink0
    . z 10
    . transitionTransform

-- Note: hover:z-30, hover:scale-105 are variant states

-- | Style for Resource cards in the staging area
stagedResourceCard :: Style
stagedResourceCard =
  relative
    . group
    . cursorPointer
    . originBottom
    . cardHandWidth
    . shrink0
    . transitionAll
    . duration200

-- Note: hover:-translate-y-4, hover:z-20 are variant states

-- | Style for individual rules/actions within a card's textbox
cardRuleStyle :: Style
cardRuleStyle = S.mb S.S1 . S.lastChild S.mb0

-- | Helper for last-child variant (need to add to DSL if not present)
-- For now, we'll just use a simple mb-1 which is the common case
-- and handle the last child margin via the container's padding.
