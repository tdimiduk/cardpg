module Frontend.Card.Common
  ( fancyText
  , fancyText'
  , resourceSymbol
  , resourceSymbol'
  ) where

import Data.List.NonEmpty (NonEmpty(..))
import Data.Text (Text)
import qualified Data.Text as T

import Reflex.Dom.Core

import Common.Util
import Common.Card

fancyText :: DomBuilder t m => FancyText -> m ()
fancyText (FancyText ls) = mapM_ fancyLine ls

fancyText' :: DomBuilder t m => FancyText -> m ()
fancyText' (FancyText (l:|ls)) = fancyLine' l >> mapM_ fancyLine ls

fancyLine :: DomBuilder t m => FancyLine -> m ()
fancyLine = elClass "div" "text-line" . fancyLine'

fancyLine' :: DomBuilder t m => FancyLine -> m ()
fancyLine' (FancyLine tokens) = mapM_ render tokens
  where
    render (FancyTextToken t) = text t
    render (ResourceToken t) = resourceSymbol t

resourceSymbol :: DomBuilder t m => ResourceType -> m ()
resourceSymbol a = resourceSymbol' a Nothing

resourceSymbol' :: DomBuilder t m => ResourceType -> Maybe Text -> m ()
resourceSymbol' r t = divClass cls $
  divClass "resource-number" $ mapM_ text t
  where
    cls = "resource-symbol " <> (T.toLower (tshow r))
