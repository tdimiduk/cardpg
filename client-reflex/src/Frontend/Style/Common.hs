{-# LANGUAGE OverloadedStrings #-}

-- | Common styling atoms and element helpers.
--
-- This module provides the core infrastructure for building styled elements
-- using the transformer-style CSS pattern.
module Frontend.Style.Common
  ( -- * Core Types
    Style
  , classes
  , toClassName

    -- * Element Helpers
  , divS
  , elS
  , elS'
  , component
  , testId

    -- * Transformer-style Element Helpers
  , divT
  , elT
  , elT'
  , componentT
  , toStyle

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
import Data.Text qualified as T
import Reflex.Dom.Core
import Web.Atomic.Types (CSS (..), Rule)
import Web.Atomic.Types qualified as Atomic (ClassName (..), Rule (..))

import Frontend.Style.Class (MonadStyle (..), StyledDomBuilder)
import Frontend.Style.DSL

--------------------------------------------------------------------------------
-- Core Types
--------------------------------------------------------------------------------

-- | A style transformer that composes CSS rules.
-- Use (.) to compose styles: @flex . justifyCenter . gap4@
type Style = CSS [Rule] -> CSS [Rule]

-- | Registers the CSS rules and returns the class string for the DOM.
classes :: (MonadStyle m) => CSS [Rule] -> m Text
classes css@(CSS rules) = do
  registerStyles css
  pure $ T.unwords $ map toClassName rules

-- | Extract the class name from a Rule.
toClassName :: Rule -> Text
toClassName (Atomic.Rule c _ _ _) = case c of
  Atomic.ClassName t -> t

--------------------------------------------------------------------------------
-- Element Helpers
--------------------------------------------------------------------------------

-- | Helper to create a div with CSS styles.
divS :: (StyledDomBuilder t m) => CSS [Rule] -> m a -> m a
divS css child = do
  clsText <- classes css
  divClass clsText child

-- | A named component div (useful for debugging/structure).
component :: (StyledDomBuilder t m) => Text -> CSS [Rule] -> m a -> m a
component name css child = do
  clsText <- classes css
  elAttr "div" ("class" =: clsText <> testId name) child

-- | Helper to create an element with CSS styles.
elS :: (StyledDomBuilder t m) => Text -> CSS [Rule] -> m a -> m a
elS tagName css child = do
  clsText <- classes css
  elClass tagName clsText child

-- | Helper to create an element with CSS styles and attributes.
elS'
  :: (StyledDomBuilder t m)
  => Text -> CSS [Rule] -> Map Text Text -> m a -> m (Element EventResult (DomBuilderSpace m) t, a)
elS' tagName css attrs child = do
  clsText <- classes css
  elAttr' tagName (("class" =: clsText) <> attrs) child

-- | Add a data-testid attribute for testing.
testId :: Text -> Map Text Text
testId = ("data-testid" =:)

--------------------------------------------------------------------------------
-- Transformer-style Element Helpers
--------------------------------------------------------------------------------

-- | Create a div using transformer-style CSS.
-- @
-- divT (flex . justifyCenter . hover bgSlate700) child
-- @
divT :: (StyledDomBuilder t m) => Style -> m a -> m a
divT style = divS (style mempty)

-- | Create an element using transformer-style CSS.
elT :: (StyledDomBuilder t m) => Text -> Style -> m a -> m a
elT tagName style = elS tagName (style mempty)

-- | Create an element using transformer-style CSS with attributes.
elT'
  :: (StyledDomBuilder t m)
  => Text -> Style -> Map Text Text -> m a -> m (Element EventResult (DomBuilderSpace m) t, a)
elT' tagName style = elS' tagName (style mempty)

-- | A named component div using transformer-style CSS.
componentT :: (StyledDomBuilder t m) => Text -> Style -> m a -> m a
componentT name style child = do
  clsText <- classes (style mempty)
  elAttr "div" ("class" =: clsText <> testId name) child

-- | Convert a raw CSS value to a Style transformer.
toStyle :: CSS [Rule] -> Style
toStyle css = (css <>)

--------------------------------------------------------------------------------
-- Composite Styles (multi-atom combinations)
--------------------------------------------------------------------------------

-- | Block icon style (fixed size)
iconBlock :: Style
iconBlock = w10 . h10 . fontBold . textXl

-- | Responsive icon (percentage height)
iconResponsive :: Style
iconResponsive = atom "h-[30%]" "height" "30%" . wFit . aspectSquare . fontBold

-- | Inline icon (fits text line height)
iconInline :: Style
iconInline = inlineBlock . atom "h-[0.8em]" "height" "0.8em" . atom "w-auto" "width" "auto" . alignTextBottom

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
shadow size = atom ("shadow-" <> size) "box-shadow" ""

-- | Helper for dynamic backdrop blur
backdropBlur :: Text -> Style
backdropBlur size = atom ("backdrop-blur-" <> size) "backdrop-filter" (T.unpack $ "blur(" <> size <> ")")
