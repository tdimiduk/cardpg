module Frontend.Card.Common
  ( renderCardBlocks
  , renderCardText
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

renderCardBlocks :: DomBuilder t m => CardBlocks -> m ()
renderCardBlocks = mapM_ renderBlock

renderBlock :: DomBuilder t m => CardBlock -> m ()
renderBlock (Paragraph b) = el "p" $ renderCardText b
renderBlock ThematicBreak = el "hr" $ pure ()

renderCardText :: DomBuilder t m => CardText -> m ()
renderCardText = mapM_ renderInline . toList

renderInline :: DomBuilder t m => CardInline -> m ()
renderInline (Txt t) = text t
renderInline (ResourceIcon t) = resourceSymbol t
