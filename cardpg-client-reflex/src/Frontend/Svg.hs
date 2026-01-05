{-# LANGUAGE ImportQualifiedPost #-}
{-# LANGUAGE OverloadedStrings #-}

module Frontend.Svg
  ( svgEl
  , renderSquare
  , renderCircle
  , renderDiamond
  ) where

import Data.Map qualified as Map
import Data.Text (Text)
import Reflex.Dom.Core

type ElAttrs = Map.Map Text Text

svgXMLNamespace :: Namespace
svgXMLNamespace = "http://www.w3.org/2000/svg"

elAttrNS' ::
  (DomBuilder t m) =>
  Maybe Namespace ->
  Text ->
  Map.Map Text Text ->
  m a ->
  m (Element EventResult (DomBuilderSpace m) t, a)
elAttrNS' mns elementTag attrs =
  element elementTag $
    def
      & elementConfig_namespace
      .~ mns
      & initialAttributes
      .~ Map.mapKeys (AttributeName Nothing) attrs

svgEl :: (DomBuilder t m) => Text -> ElAttrs -> m a -> m a
svgEl elementTag attrs child = snd <$> elAttrNS' (Just svgXMLNamespace) elementTag attrs child

-- | Renders text centered in the SVG.
renderLabel :: (DomBuilder t m) => Maybe Text -> m ()
renderLabel Nothing = blank
renderLabel (Just t) =
  svgEl
    "text"
    ( "x" =: "50"
        <> "y" =: "50"
        <> "dominant-baseline" =: "central"
        <> "text-anchor" =: "middle"
        <> "font-size" =: "40"
        <> "font-family" =: "sans-serif"
        <> "font-weight" =: "bold"
        <> "fill" =: "currentColor" -- Will be overridden by class if needed
        <> "class" =: "resource-text" -- Allow external styling
        <> "stroke" =: "none"
    )
    $ text t

-- | Renders a square icon.
renderSquare :: (DomBuilder t m) => Text -> Maybe Text -> m ()
renderSquare colorClass mLabel =
  svgEl "svg" ("viewBox" =: "0 0 100 100" <> "class" =: ("resource-icon " <> colorClass)) $ do
    svgEl
      "rect"
      ( "x" =: "12.5"
          <> "y" =: "12.5"
          <> "width" =: "75"
          <> "height" =: "75"
          <> "rx" =: "10"
          <> "ry" =: "10"
          <> "class" =: "resource-shape"
          <> "fill" =: "none"
          <> "stroke" =: "currentColor"
          <> "stroke-width" =: "8"
      )
      blank
    renderLabel mLabel

-- | Renders a circle icon.
renderCircle :: (DomBuilder t m) => Text -> Maybe Text -> m ()
renderCircle colorClass mLabel =
  svgEl "svg" ("viewBox" =: "0 0 100 100" <> "class" =: ("resource-icon " <> colorClass)) $ do
    svgEl
      "circle"
      ( "cx" =: "50"
          <> "cy" =: "50"
          <> "r" =: "40"
          <> "class" =: "resource-shape"
          <> "fill" =: "none"
          <> "stroke" =: "currentColor"
          <> "stroke-width" =: "8"
      )
      blank
    renderLabel mLabel

-- | Renders a diamond icon.
renderDiamond :: (DomBuilder t m) => Text -> Maybe Text -> m ()
renderDiamond colorClass mLabel =
  svgEl "svg" ("viewBox" =: "0 0 100 100" <> "class" =: ("resource-icon " <> colorClass)) $ do
    svgEl
      "rect"
      ( "x" =: "19"
          <> "y" =: "19"
          <> "width" =: "62"
          <> "height" =: "62"
          <> "rx" =: "5"
          <> "ry" =: "5"
          <> "transform" =: "rotate(45 50 50)"
          <> "class" =: "resource-shape"
          <> "fill" =: "none"
          <> "stroke" =: "currentColor"
          <> "stroke-width" =: "8"
      )
      blank
    renderLabel mLabel
