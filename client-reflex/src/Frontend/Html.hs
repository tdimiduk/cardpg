-- | HTML rendering utilities for primitive types.
-- | This module provides explicit render functions rather than typeclass instances.
module Frontend.Html
  ( renderBlock
  , renderNonEmptyText
  , resourceSymbol
  ) where

import Data.Text (Text)
import Reflex.Dom.Core

import Core.NonEmptyText (NonEmptyText, getRawText)
import Core.RichText (Block (..))
import Core.Stats (ResourceType (..))
import Core.Util (tshow)

import Frontend.Render.Common (IconMode (..))
import Frontend.Render.Rules (renderRichText)
import Frontend.Style qualified as Style
import Frontend.Svg (renderCircle, renderDiamond, renderSquare)

-- | Render a ResourceType as an SVG shape icon
resourceSymbol :: (DomBuilder t m) => IconMode -> ResourceType -> Maybe Text -> m ()
resourceSymbol mode r t = case r of
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

-- | Render NonEmptyText as plain text
renderNonEmptyText :: (DomBuilder t m) => NonEmptyText -> m ()
renderNonEmptyText = text . getRawText

-- | Render a Block element
renderBlock :: (DomBuilder t m) => Block -> m ()
renderBlock (Paragraph rt) = el "p" $ renderRichText rt
renderBlock Rule = el "hr" $ pure ()
renderBlock (Header rt) = el "h3" $ renderRichText rt
renderBlock (BulletList items) = el "ul" $ mapM_ (el "li" . renderRichText) items
