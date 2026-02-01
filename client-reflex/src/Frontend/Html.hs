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

import Frontend.Render.Common (IconMode (..), renderNonEmptyText, renderResourceType)
import Frontend.Render.Rules (renderRichText)
import Frontend.Style qualified as Style

-- | Render a ResourceType as an SVG shape icon
resourceSymbol :: (DomBuilder t m) => IconMode -> ResourceType -> Maybe Text -> m ()
resourceSymbol = renderResourceType

-- | Render a Block element
renderBlock :: (DomBuilder t m) => Block -> m ()
renderBlock (Paragraph rt) = el "p" $ renderRichText rt
renderBlock Rule = el "hr" $ pure ()
renderBlock (Header rt) = el "h3" $ renderRichText rt
renderBlock (BulletList items) = el "ul" $ mapM_ (el "li" . renderRichText) items
