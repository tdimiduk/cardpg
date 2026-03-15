{-# LANGUAGE OverloadedStrings #-}

-- | Common styling infrastructure and element helpers.
--
-- This module provides the core element helpers for building styled
-- Reflex DOM elements using the composable Style system.
module Frontend.Style.Common
  ( -- * Core re-exports
    Style
  , Prop (..)
  , css
  , css'
  , cls
  , classNames

    -- * Element Helpers
  , divS
  , elS
  , elS'
  , componentS
  , testId

    -- * Composite Styles (multi-atom combinations)
  , iconBlock
  , iconResponsive
  , iconInline
  , resourceIcon
  , resourceTextBase
  , resourceTextPrint
  , shadow
  , backdropBlur
  ) where

import Data.Map (Map)
import Data.Text (Text)
import Reflex.Dom.Core

import Frontend.Style.Core (Prop (..), Style, classNames, cls, css, css')
import Frontend.Style.DSL

--------------------------------------------------------------------------------
-- Element Helpers
--------------------------------------------------------------------------------

-- | Create a styled div.
divS :: (DomBuilder t m) => Style -> m a -> m a
divS style = divClass (classNames style)

-- | Create a styled element.
elS :: (DomBuilder t m) => Text -> Style -> m a -> m a
elS tagName style = elClass tagName (classNames style)

-- | Create a styled element with additional attributes.
elS'
  :: (DomBuilder t m)
  => Text -> Style -> Map Text Text -> m a -> m (Element EventResult (DomBuilderSpace m) t, a)
elS' tagName style attrs = elAttr' tagName (("class" =: classNames style) <> attrs)

-- | A named component div (adds data-testid for testing/debugging).
componentS :: (DomBuilder t m) => Text -> Style -> m a -> m a
componentS name style child =
  elAttr "div" ("class" =: classNames style <> testId name) child

-- | Add a data-testid attribute for testing.
testId :: Text -> Map Text Text
testId = ("data-testid" =:)

--------------------------------------------------------------------------------
-- Composite Styles (multi-atom combinations)
--------------------------------------------------------------------------------

-- | Block icon style (fixed size)
iconBlock :: Style
iconBlock = w10 . h10 . fontBold . textXl

-- | Responsive icon (percentage height)
iconResponsive :: Style
iconResponsive =
  css "h-30pct" "height" "30%"
    . css "w-auto" "width" "auto"
    . aspectSquare
    . fontBold

-- | Inline icon (fits text line height)
iconInline :: Style
iconInline =
  inlineBlock
    . css "h-0.8em" "height" "0.8em"
    . css "w-auto" "width" "auto"
    . alignTextBottom

-- | Resource icon size
resourceIcon :: Style
resourceIcon = w4 . h4

-- | Resource text base (bold)
resourceTextBase :: Style
resourceTextBase = fontBold

-- | Resource text for print (black)
resourceTextPrint :: Style
resourceTextPrint = textBlack

-- | Helper for dynamic shadows (takes size suffix like "md", "lg", "xl")
shadow :: Text -> Style
shadow size = css ("shadow-" <> size) "box-shadow" ""

-- | Helper for dynamic backdrop blur
backdropBlur :: Text -> Style
backdropBlur size = css ("backdrop-blur-" <> size) "backdrop-filter" ("blur(" <> size <> ")")
