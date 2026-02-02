{-# LANGUAGE OverloadedStrings #-}

module Core.Layout
  ( LayoutItem (..)
  , renderLayoutText
  , renderLayoutItem
  , layoutWrapper
  , intercalateLayout
  ) where

import Core.DSL (toText)
import Core.RichText (RichText)
import Core.Stats (ResourceType, toTextResourceType)
import Data.Text (Text)
import Data.Text qualified as T

-- | Abstract representation of a rule's display components.
data LayoutItem
  = -- | Keywords like "Action:", "When", "Check", etc.
    Keyword Text
  | -- | A resource icon, potentially with text inside
    Symbol ResourceType (Maybe Text)
  | -- | Plain text literals (names, separators like "->")
    Literal Text
  | -- | Rich text content
    RichContent RichText
  | -- | Logical grouping (often rendered with parens)
    Group [LayoutItem]
  | -- | Explicit spacing
    Space
  deriving (Eq, Show)

--------------------------------------------------------------------------------
-- Helpers
--------------------------------------------------------------------------------

renderLayoutText :: [LayoutItem] -> Text
renderLayoutText items = T.concat $ map renderLayoutItem items

renderLayoutItem :: LayoutItem -> Text
renderLayoutItem (Keyword t) = t
renderLayoutItem (Literal t) = t
renderLayoutItem (Symbol r Nothing) = toTextResourceType r
renderLayoutItem (Symbol r (Just t)) = toTextResourceType r <> " " <> t
renderLayoutItem (RichContent rt) = toText rt
renderLayoutItem (Group items) = "(" <> renderLayoutText items <> ")"
renderLayoutItem Space = " "

-- | Wraps items in parentheses (abstractly, though Group often implies this)
layoutWrapper :: [LayoutItem] -> [LayoutItem]
layoutWrapper items = items

intercalateLayout :: [LayoutItem] -> [[LayoutItem]] -> [LayoutItem]
intercalateLayout _ [] = []
intercalateLayout _ [x] = x
intercalateLayout sep (x : xs) = x <> sep <> intercalateLayout sep xs
