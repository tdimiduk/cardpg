-- | Common rendering utilities and types for the frontend.
module Frontend.Render.Common
  ( IconMode (..)
  , renderNonEmptyText
  , renderResourceType
  ) where

import Data.Default (Default (..))
import Data.Text (Text)
import Reflex.Dom.Core

import Core.NonEmptyText (NonEmptyText, getRawText)
import Core.Stats (ResourceType (..))
import Core.Util (tshow)

import Frontend.Style qualified as Style
import Frontend.Svg (renderCircle, renderDiamond, renderSquare)

-- | Icon display mode for resource symbols and stat values
data IconMode = IconInline | IconBlock | IconResponsive
  deriving (Eq, Show, Enum, Bounded)

instance Default IconMode where
  def = IconInline

-- | Render a ResourceType as an SVG icon
renderResourceType :: (DomBuilder t m) => IconMode -> ResourceType -> Maybe Text -> m ()
renderResourceType mode r t = case r of
  Red -> renderSquare (color <> style) t
  Yellow -> renderCircle (color <> style) t
  Blue -> renderDiamond (color <> style) t
  where
    color = case r of
      Red -> [Style.textRed500]
      Yellow -> [Style.textYellow400]
      Blue -> [Style.textBlue500]
    style = case mode of
      IconInline -> Style.iconInline
      IconBlock -> Style.iconBlock
      IconResponsive -> Style.iconResponsive

-- | Render a NonEmptyText as plain text
renderNonEmptyText :: (DomBuilder t m) => NonEmptyText -> m ()
renderNonEmptyText = text . getRawText
