{-# LANGUAGE OverloadedStrings #-}

-- | Core types and functions for the purpose-built CSS system.
--
-- This module provides the foundational types for composable, type-safe
-- CSS utilities. Styles compose with (.) and produce atomic CSS classes.
--
-- @
-- cardStyle :: Style
-- cardStyle = flexCol . bgSlate800 . roundedXl . shadowXl
--
-- widget = divS cardStyle $ text "Hello"
-- @
module Frontend.Style.Core
  ( -- * Core Types
    Prop (..)
  , Style

    -- * Atomic Constructors
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

    -- * Rendering
  , classNames
  , renderAll
  , renderProp

    -- * Utilities
  , escapeCss
  , tshow
  ) where

import Data.List (nubBy)
import Data.Text (Text)
import Data.Text qualified as T

--------------------------------------------------------------------------------
-- Core Types
--------------------------------------------------------------------------------

-- | A single CSS rule: class name + property declarations.
data Prop = Prop
  { propClassName :: !Text
  -- ^ The class name (e.g. "flex-col", "hover\\:bg-slate-700")
  , propSelector :: !Text
  -- ^ The full CSS selector (e.g. ".flex-col", ".hover\\:bg-slate-700:hover")
  , propDecls :: ![(Text, Text)]
  -- ^ CSS property declarations (e.g. [("display","flex")])
  }
  deriving (Show, Eq)

-- | A composable style transformer. Compose with (.) and apply to []:
--
-- @
-- myStyle = flexCol . gap4 . bgSlate800
-- classes = classNames myStyle   -- "flex-col gap-4 bg-slate-800"
-- @
type Style = [Prop] -> [Prop]

--------------------------------------------------------------------------------
-- Atomic Constructors
--------------------------------------------------------------------------------

-- | Define a single-property atomic style.
--
-- @
-- flexCol = css' "flex-col" [("display","flex"), ("flex-direction","column")]
-- bgSlate800 = css "bg-slate-800" "background-color" "#1e293b"
-- @
css :: Text -> Text -> Text -> Style
css name property value = (Prop name ("." <> escapeCss name) [(property, value)] :)

-- | Define a multi-property atomic style.
css' :: Text -> [(Text, Text)] -> Style
css' name decls = (Prop name ("." <> escapeCss name) decls :)

-- | An external class name with no generated CSS.
-- Use for classes defined elsewhere (e.g. "action", "scaler-target").
cls :: Text -> Style
cls name = (Prop name ("." <> name) [] :)

--------------------------------------------------------------------------------
-- Modifiers
--------------------------------------------------------------------------------

-- | Apply a style only on :hover.
--
-- @
-- cardHover = hover bgSlate700
-- @
hover :: Style -> Style
hover inner = \rest -> map hoverProp (inner []) ++ rest

-- | Add hover styling to a single Prop. Useful for GenCss generation.
hoverProp :: Prop -> Prop
hoverProp p =
  p
    { propClassName = "hover\\:" <> p.propClassName
    , propSelector = "." <> escapeCss ("hover:" <> p.propClassName) <> ":hover"
    }

-- | Apply a style only on :active.
active :: Style -> Style
active inner = \rest -> map activeProp (inner []) ++ rest

-- | Add active styling to a single Prop. Useful for GenCss generation.
activeProp :: Prop -> Prop
activeProp p =
  p
    { propClassName = "active\\:" <> p.propClassName
    , propSelector = "." <> escapeCss ("active:" <> p.propClassName) <> ":active"
    }

-- | Apply a style with a custom pseudo-class.
--
-- @
-- focusVisible = pseudo "focus-visible" (ringBlue400 . ring2)
-- @
pseudo :: Text -> Style -> Style
pseudo pseudoClass inner = \rest -> map (pseudoProp pseudoClass) (inner []) ++ rest

-- | Add pseudo-class styling to a single Prop.
pseudoProp :: Text -> Prop -> Prop
pseudoProp pseudoClass p =
  p
    { propClassName = pseudoClass <> "\\:" <> p.propClassName
    , propSelector =
        "." <> escapeCss (pseudoClass <> ":" <> p.propClassName) <> ":" <> pseudoClass
    }

-- | Wrap a style in a @media query.
--
-- @
-- printOnly = media "print" textBlack
-- responsive = media "(min-width: 768px)" (fontSize 18)
-- @
media :: Text -> Style -> Style
media query inner = \rest -> map (mediaProp query) (inner []) ++ rest

-- | Add media query styling to a single Prop.
mediaProp :: Text -> Prop -> Prop
mediaProp q p =
  p
    { propClassName = mediaPrefix <> "\\:" <> p.propClassName
    , propSelector = "." <> escapeCss (mediaPrefix <> ":" <> p.propClassName)
    }
  where
    -- Use a short prefix for the class name
    mediaPrefix = T.filter (\c -> c /= ' ' && c /= '(' && c /= ')' && c /= ':') q

--------------------------------------------------------------------------------
-- Rendering
--------------------------------------------------------------------------------

-- | Extract the space-separated class names from a Style.
classNames :: Style -> Text
classNames style = T.unwords $ map (.propClassName) (style [])

-- | Render a list of Props to CSS text (for file generation).
-- Deduplicates by class name.
renderAll :: [Prop] -> Text
renderAll = T.unlines . map renderProp . nubBy (\a b -> a.propClassName == b.propClassName)

-- | Render a single Prop to a CSS rule string.
renderProp :: Prop -> Text
renderProp (Prop _ _ []) = "" -- cls-only props produce no CSS
renderProp (Prop _ sel decls) =
  sel <> " { " <> T.intercalate "; " (map renderDecl decls) <> " }"
  where
    renderDecl (prop, val) = prop <> ": " <> val

--------------------------------------------------------------------------------
-- Utilities
--------------------------------------------------------------------------------

-- | Escape special characters for CSS class selectors.
escapeCss :: Text -> Text
escapeCss = T.concatMap escapeChar
  where
    escapeChar c
      | c `elem` ("!\"#$%&'()*+,./:;<=>?@[\\]^`{|}~ " :: String) = "\\" <> T.singleton c
      | otherwise = T.singleton c

-- | Show a value as Text.
tshow :: (Show a) => a -> Text
tshow = T.pack . show
