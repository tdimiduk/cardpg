module Frontend.Card.Common
  ( renderCardText
  , resourceSymbol
  , resourceSymbol'
  , art
  ) where

import Data.List.NonEmpty (toList)
import Data.Text (Text)
import qualified Data.Text as T

import Reflex.Dom.Core

import Common.Util
import Common.Card.Common

resourceSymbol :: DomBuilder t m => ResourceType -> m ()
resourceSymbol a = resourceSymbol' a Nothing

resourceSymbol' :: DomBuilder t m => ResourceType -> Maybe Text -> m ()
resourceSymbol' r t = divClass cls $
  divClass "resource-number" $ mapM_ text t
  where
    cls = "resource-symbol " <> (T.toLower (tshow r))

art :: DomBuilder t m => m ()
art = divClass "art" blank

renderCardText :: DomBuilder t m => CardText -> m ()
renderCardText (CardText blocks) = mapM_ renderBlock blocks

renderBlock :: DomBuilder t m => CardBlock -> m ()
renderBlock (Paragraph inlines) = el "p" $ mapM_ renderInline $ toList inlines
renderBlock ThematicBreak = el "hr" $ pure ()

renderInline :: DomBuilder t m => CardInline -> m ()
renderInline (Txt t) = text t
renderInline (ResourceIcon t) = resourceSymbol t
