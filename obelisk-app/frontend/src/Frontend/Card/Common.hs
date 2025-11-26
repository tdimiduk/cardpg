-- Defining rendering orphans which are frontend only
{-# options_ghc -fno-warn-orphans #-}

module Frontend.Card.Common
  ( art
  ) where

import Data.Text (Text)
import qualified Data.Text as T

import Reflex.Dom.Core

import Common.Util
import Common.Card.Common

import Frontend.Html

resourceSymbol :: DomBuilder t m => ResourceType -> Maybe Text -> m ()
resourceSymbol r t = divClass cls $
  divClass "resource-number" $ mapM_ text t
  where
    cls = "resource-symbol " <> (T.toLower (tshow r))

art :: DomBuilder t m => m ()
art = divClass "art" blank

instance DomBuilder t m => Render CardBlock m where
  render (Paragraph b) = el "p" $ render b
  render ThematicBreak = el "hr" $ pure ()

instance DomBuilder t m => Render CardInline m where
  render (Txt t) = text t
  render (ResourceIcon c) = resourceSymbol c Nothing
  render (ResourceValue c v) = resourceSymbol c v
