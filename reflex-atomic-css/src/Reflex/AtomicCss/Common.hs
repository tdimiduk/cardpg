{-# LANGUAGE OverloadedStrings #-}

-- | Common styling infrastructure and element helpers.
--
-- This module provides the core element helpers for building styled
-- Reflex DOM elements using the composable Style system.
module Reflex.AtomicCss.Common
  ( -- * Core re-exports
    Style
  , Prop
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
  ) where

import Data.Map (Map)
import Data.Text (Text)
import Reflex.Dom.Core

import Reflex.AtomicCss.Core (Prop, Style, classNames, cls, css, css')

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
componentS name style = elAttr "div" ("class" =: classNames style <> testId name)

-- | Add a data-testid attribute for testing.
testId :: Text -> Map Text Text
testId = ("data-testid" =:)
