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

import Frontend.Style.Common (Style)
import Frontend.Style.Common qualified as CommonStyle
import Frontend.Style.DSL qualified as S
import Frontend.Svg (renderCircle, renderDiamond, renderSquare)

-- | Icon display mode for resource symbols and stat values
data IconMode = IconInline | IconBlock | IconResponsive
  deriving (Eq, Show, Enum, Bounded)

instance Default IconMode where
  def = IconInline

-- | Render a ResourceType as an SVG icon
renderResourceType
  :: (DomBuilder t m) => IconMode -> ResourceType -> Maybe Text -> m ()
renderResourceType mode r t = case r of
  Red -> renderSquare (color . style) t
  Yellow -> renderCircle (color . style) t
  Blue -> renderDiamond (color . style) t
  where
    color :: Style
    color = case r of
      Red -> (S.text S.Red 6)
      Yellow -> (S.text S.Yellow 5)
      Blue -> (S.text S.Blue 5)
    style :: Style
    style = case mode of
      IconInline -> CommonStyle.iconInline
      IconBlock -> CommonStyle.iconBlock
      IconResponsive -> CommonStyle.iconResponsive

-- | Render a NonEmptyText as plain text
renderNonEmptyText :: (DomBuilder t m) => NonEmptyText -> m ()
renderNonEmptyText = text . getRawText
