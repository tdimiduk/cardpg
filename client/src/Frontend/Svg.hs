{-# LANGUAGE ImportQualifiedPost #-}
{-# LANGUAGE OverloadedStrings #-}

module Frontend.Svg
  ( svgEl
  , renderSvgShape
  , renderSquare
  , renderCircle
  , renderDiamond
  , renderHexagon
  , svgPath
  ) where

import Data.Map qualified as Map
import Data.Text (Text)
import Reflex.Dom.Core

import Frontend.Style.Common (Style, classNames)

type ElAttrs = Map.Map Text Text

svgXMLNamespace :: Namespace
svgXMLNamespace = "http://www.w3.org/2000/svg"

elAttrNS'
  :: (DomBuilder t m)
  => Maybe Namespace
  -> Text
  -> Map.Map Text Text
  -> m a
  -> m (Element EventResult (DomBuilderSpace m) t, a)
elAttrNS' mns elementTag attrs =
  element elementTag $
    def
      & elementConfig_namespace
      .~ mns
      & initialAttributes
      .~ Map.mapKeys (AttributeName Nothing) attrs

svgEl :: (DomBuilder t m) => Text -> ElAttrs -> m a -> m a
svgEl elementTag attrs child = snd <$> elAttrNS' (Just svgXMLNamespace) elementTag attrs child

svgPath :: (DomBuilder t m) => Text -> m ()
svgPath d = svgEl "path" ("d" =: d) blank

-- | Renders text centered in the SVG with custom Almendra typography, white fill, and thick black outline for maximum legibility.
renderLabel :: (DomBuilder t m) => Maybe Text -> m ()
renderLabel Nothing = blank
renderLabel (Just t) = do
  svgEl
    "text"
    ( "x" =: "50"
        <> "y" =: "49" -- adjusted for baseline centering of Almendra font
        <> "dominant-baseline" =: "central"
        <> "text-anchor" =: "middle"
        <> "font-size" =: "54" -- larger for readability
        <> "font-family" =: "'Almendra', Georgia, serif"
        <> "font-weight" =: "700" -- bold weight for Almendra numbers
        <> "fill" =: "#ffffff" -- high-contrast white fill for all shapes
        <> "stroke" =: "#090706" -- deep dark outline
        <> "stroke-width" =: "10" -- thick readable border
        <> "stroke-linejoin" =: "round"
        <> "paint-order" =: "stroke fill"
    )
    $ text t

-- | Higher-order parameterized SVG shape builder that handles viewBox scaffolding, defs, and labeling.
renderSvgShape
  :: (DomBuilder t m)
  => Style
  -- ^ Extra classes
  -> Maybe Text
  -- ^ Label text
  -> m ()
  -- ^ Gradient and filter definitions
  -> m ()
  -- ^ SVG shape rendering block (e.g. rect, circle, polygon)
  -> m ()
renderSvgShape extraStyle mLabel defsBuilder shapeBuilder = do
  let cls = classNames extraStyle
  svgEl
    "svg"
    ( "viewBox" =: "0 0 100 100"
        <> "class" =: cls
    )
    $ do
      svgEl "defs" Map.empty defsBuilder
      shapeBuilder
      renderLabel mLabel

-- | Renders a square icon (Ruby/Red).
renderSquare :: (DomBuilder t m) => Style -> Maybe Text -> m ()
renderSquare extraStyle mLabel =
  renderSvgShape
    extraStyle
    mLabel
    ( do
        svgEl "radialGradient" ("id" =: "rubyGrad" <> "cx" =: "35%" <> "cy" =: "35%" <> "r" =: "60%") $ do
          svgEl "stop" ("offset" =: "0%" <> "stop-color" =: "#ffa8a8") blank
          svgEl "stop" ("offset" =: "60%" <> "stop-color" =: "#ff4b4b") blank
          svgEl "stop" ("offset" =: "100%" <> "stop-color" =: "#c92a2a") blank
        svgEl "filter" ("id" =: "rubyGlow") $
          svgEl
            "feDropShadow"
            ( "dx" =: "0"
                <> "dy" =: "2"
                <> "stdDeviation" =: "3"
                <> "flood-color" =: "#ff4b4b"
                <> "flood-opacity" =: "0.5"
            )
            blank
    )
    ( svgEl
        "rect"
        ( "x" =: "12.5"
            <> "y" =: "12.5"
            <> "width" =: "75"
            <> "height" =: "75"
            <> "rx" =: "12"
            <> "ry" =: "12"
            <> "fill" =: "url(#rubyGrad)"
            <> "stroke" =: "var(--color-gold-muted)"
            <> "stroke-width" =: "3"
            <> "filter" =: "url(#rubyGlow)"
        )
        blank
    )

-- | Renders a circle icon (Topaz/Yellow).
renderCircle :: (DomBuilder t m) => Style -> Maybe Text -> m ()
renderCircle extraStyle mLabel =
  renderSvgShape
    extraStyle
    mLabel
    ( do
        svgEl "radialGradient" ("id" =: "topazGrad" <> "cx" =: "35%" <> "cy" =: "35%" <> "r" =: "60%") $ do
          svgEl "stop" ("offset" =: "0%" <> "stop-color" =: "#ffec99") blank
          svgEl "stop" ("offset" =: "75%" <> "stop-color" =: "#f59e0b") blank
          svgEl "stop" ("offset" =: "100%" <> "stop-color" =: "#b45309") blank
        svgEl "filter" ("id" =: "topazGlow") $
          svgEl
            "feDropShadow"
            ( "dx" =: "0"
                <> "dy" =: "2"
                <> "stdDeviation" =: "3"
                <> "flood-color" =: "#f59e0b"
                <> "flood-opacity" =: "0.5"
            )
            blank
    )
    ( svgEl
        "circle"
        ( "cx" =: "50"
            <> "cy" =: "50"
            <> "r" =: "40"
            <> "fill" =: "url(#topazGrad)"
            <> "stroke" =: "var(--color-gold-bright)"
            <> "stroke-width" =: "3"
            <> "filter" =: "url(#topazGlow)"
        )
        blank
    )

-- | Renders a diamond icon (Sapphire/Blue).
renderDiamond :: (DomBuilder t m) => Style -> Maybe Text -> m ()
renderDiamond extraStyle mLabel =
  renderSvgShape
    extraStyle
    mLabel
    ( do
        svgEl "radialGradient" ("id" =: "sapphireGrad" <> "cx" =: "35%" <> "cy" =: "35%" <> "r" =: "60%") $ do
          svgEl "stop" ("offset" =: "0%" <> "stop-color" =: "#a5d8ff") blank
          svgEl "stop" ("offset" =: "70%" <> "stop-color" =: "#228be6") blank
          svgEl "stop" ("offset" =: "100%" <> "stop-color" =: "#1c7ed6") blank
        svgEl "filter" ("id" =: "sapphireGlow") $
          svgEl
            "feDropShadow"
            ( "dx" =: "0"
                <> "dy" =: "2"
                <> "stdDeviation" =: "3"
                <> "flood-color" =: "#228be6"
                <> "flood-opacity" =: "0.5"
            )
            blank
    )
    ( svgEl
        "rect"
        ( "x" =: "19"
            <> "y" =: "19"
            <> "width" =: "62"
            <> "height" =: "62"
            <> "rx" =: "8"
            <> "ry" =: "8"
            <> "transform" =: "rotate(45 50 50)"
            <> "fill" =: "url(#sapphireGrad)"
            <> "stroke" =: "var(--color-silver-bright)"
            <> "stroke-width" =: "3"
            <> "filter" =: "url(#sapphireGlow)"
        )
        blank
    )

-- | Renders a hexagon icon (Cost Hexagon).
renderHexagon :: (DomBuilder t m) => Style -> Maybe Text -> m ()
renderHexagon extraStyle mLabel =
  renderSvgShape
    extraStyle
    mLabel
    ( do
        svgEl
          "linearGradient"
          ("id" =: "hexGrad" <> "x1" =: "0%" <> "y1" =: "0%" <> "x2" =: "100%" <> "y2" =: "100%")
          $ do
            svgEl "stop" ("offset" =: "0%" <> "stop-color" =: "#1c1917") blank
            svgEl "stop" ("offset" =: "100%" <> "stop-color" =: "#0c0a09") blank
        svgEl "filter" ("id" =: "hexGlow") $
          svgEl
            "feDropShadow"
            ( "dx" =: "0"
                <> "dy" =: "3"
                <> "stdDeviation" =: "4"
                <> "flood-color" =: "#000000"
                <> "flood-opacity" =: "0.6"
            )
            blank
    )
    ( svgEl
        "polygon"
        ( "points" =: "50,5 95,27.5 95,72.5 50,95 5,72.5 5,27.5"
            <> "fill" =: "url(#hexGrad)"
            <> "stroke" =: "var(--color-gold-bright)"
            <> "stroke-width" =: "4.5"
            <> "filter" =: "url(#hexGlow)"
        )
        blank
    )
