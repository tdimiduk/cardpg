{-# LANGUAGE ImportQualifiedPost #-}
{-# LANGUAGE OverloadedStrings #-}

module Frontend.Svg
  ( svgEl
  , renderSquare
  , renderCircle
  , renderDiamond
  , renderHexagon
  , svgPath
  ) where

import Data.Map qualified as Map
import Data.Text (Text)
import Reflex.Dom.Core
import Web.Atomic.Types (CSS, Rule)

import Frontend.Style.Class (MonadStyle)
import Frontend.Style.Common (Style, classes)
import Frontend.Style.Common qualified as CommonStyle

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

-- | Renders text centered in the SVG.
renderLabel :: (DomBuilder t m, MonadStyle m) => Maybe Text -> m ()
renderLabel Nothing = blank
renderLabel (Just t) = do
  cls <- classes $ (CommonStyle.resourceTextBase . CommonStyle.resourceTextPrint) mempty
  svgEl
    "text"
    ( "x" =: "50"
        <> "y" =: "50"
        <> "dominant-baseline" =: "central"
        <> "text-anchor" =: "middle"
        <> "font-size" =: "40"
        <> "font-family" =: "sans-serif"
        <> "font-weight" =: "bold"
        <> "fill" =: "currentColor"
        <> "class" =: cls
        <> "stroke" =: "none"
    )
    $ text t

-- | Renders a square icon.
renderSquare :: (DomBuilder t m, MonadStyle m) => Style -> Maybe Text -> m ()
renderSquare extraStyle mLabel = do
  cls <- classes $ (CommonStyle.resourceIcon . extraStyle) mempty
  svgEl
    "svg"
    ( "viewBox" =: "0 0 100 100"
        <> "class" =: cls
    )
    $ do
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
renderCircle :: (DomBuilder t m, MonadStyle m) => Style -> Maybe Text -> m ()
renderCircle extraStyle mLabel = do
  cls <- classes $ (CommonStyle.resourceIcon . extraStyle) mempty
  svgEl
    "svg"
    ( "viewBox" =: "0 0 100 100"
        <> "class" =: cls
    )
    $ do
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
renderDiamond :: (DomBuilder t m, MonadStyle m) => Style -> Maybe Text -> m ()
renderDiamond extraStyle mLabel = do
  cls <- classes $ (CommonStyle.resourceIcon . extraStyle) mempty
  svgEl
    "svg"
    ( "viewBox" =: "0 0 100 100"
        <> "class" =: cls
    )
    $ do
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

-- | Renders a hexagon icon.
renderHexagon :: (DomBuilder t m, MonadStyle m) => CSS [Rule] -> Maybe Text -> m ()
renderHexagon extraClasses mLabel = do
  cls <- classes $ CommonStyle.resourceIcon mempty <> extraClasses
  svgEl
    "svg"
    ( "viewBox" =: "0 0 100 100"
        <> "class" =: cls
    )
    $ do
      svgEl
        "polygon"
        ( "points" =: "50,5 95,27.5 95,72.5 50,95 5,72.5 5,27.5"
            <> "class" =: "resource-shape"
            <> "fill" =: "none"
            <> "stroke" =: "currentColor"
            <> "stroke-width" =: "8"
        )
        blank
      renderLabel mLabel
