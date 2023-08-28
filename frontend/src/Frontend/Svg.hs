module Frontend.Svg where

import qualified Text.Builder as B
import Data.Map qualified as Map
import Data.Text (Text)
import Data.Text qualified as T

import Reflex.Dom.Core

import Common.Util

type ElAttrs = Map.Map Text Text

svgXMLNamespace :: Text
svgXMLNamespace = "http://www.w3.org/2000/svg"

widthHeight :: Double -> Double -> ElAttrs
widthHeight = widthHeight' id

widthHeightMM :: Double -> Double -> ElAttrs
widthHeightMM = widthHeight' (<> "mm")

widthHeight' :: (Text -> Text) -> Double -> Double -> ElAttrs
widthHeight' toUnit w h = "width" =: (toUnit (tshow w)) <> "height" =: (toUnit (tshow h))

elAttrNS' ::
  DomBuilder t m =>
  Maybe Namespace ->
  Text ->
  Map.Map Text Text ->
  m a ->
  m (Element EventResult (DomBuilderSpace m) t, a)
elAttrNS' mns elementTag attrs =
  element elementTag $
    def
      & elementConfig_namespace .~ mns
      & initialAttributes .~ Map.mapKeys (AttributeName Nothing) attrs

elAttrNS ::
  DomBuilder t f =>
  Maybe Namespace ->
  Text ->
  Map.Map Text Text ->
  f b ->
  f b
elAttrNS mns elementTag attrs child = snd <$> elAttrNS' mns elementTag attrs child

svgEl :: (DomBuilder t m) => Text -> ElAttrs -> m a -> m a
svgEl = elAttrNS (Just svgXMLNamespace)

svg :: DomBuilder t m => Double -> Double -> m a -> m a
svg width height = svgEl "svg" (widthHeight width height)

svg' :: DomBuilder t m => Double -> Double -> m a -> m a
svg' vw vh = elClass "div" "svg-container" . svgEl "svg" ("viewBox" =: ("0 0 " <> tshow vw <> " " <> tshow vh) <> "width" =: "100%" <> "height" =: "100%")

path :: DomBuilder t m => [(Double, Double)] -> [Text] -> m ()
path points style =
  svgEl
    "path"
    ( "d"
        =: ("M" <> T.intercalate " " (pathPoint <$> points))
        <> "style"
        =: T.intercalate ";" style
    )
    blank

fill :: Text -> ElAttrs
fill c = "fill" =: c

circle :: DomBuilder t m => (Double, Double) -> Double -> Double -> m ()
circle center r w = circle' center r ("stroke-width" =: tshow w <> "stroke" =: "black" <> "fill" =: "none" <> "preserveAspectRatio" =: "none")

circle' :: DomBuilder t m => (Double, Double) -> Double -> ElAttrs -> m ()
circle' center r a =
  svgEl
    "circle"
    (  xyPair (T.cons 'c') center
    <> "r" =: tshow r
    <> a
    )
    blank

line :: DomBuilder t m => (Double, Double) -> (Double, Double) -> Double -> m ()
line (x1, y1) (x2, y2) w =
  svgEl
    "line"
    ( "x1"
        =: tshow x1
        <> "y1"
        =: tshow y1
        <> "x2"
        =: tshow x2
        <> "y2"
        =: tshow y2
        <> "stroke"
        =: "black"
        <> "stroke-width"
        =: tshow w
    )
    blank

xyPair :: (Text -> Text) -> (Double, Double) -> ElAttrs
xyPair mkKey (x, y) = (mkKey "x") =: tshow x <> (mkKey "y") =: tshow y

xymm = xyPair (<> "mm")

rxy :: (Double, Double) -> ElAttrs
rxy = xyPair ("r" <>)

rect' :: DomBuilder t m => ElAttrs -> m ()
rect' attrs = svgEl "rect" attrs blank

rect :: DomBuilder t m => (Double, Double) -> (Double, Double) -> ElAttrs -> m ()
rect xy wh attrs = rect' (xyPair id xy <> uncurry widthHeight wh <> attrs)

rectC :: DomBuilder t m => (Double, Double) -> (Double, Double) -> ElAttrs -> m ()
rectC (x, y) (width, height) = rect (x - width/2, y - height/2) (width, height)

mkPoint :: Int -> Int -> B.Builder
mkPoint x y = B.decimal x <> B.text "," <> B.decimal y

mkPoints :: [(Int, Int)] -> (Int, Int) -> B.Builder
mkPoints points (x, y) =  B.intercalate " " $ fmap (\(a, b) -> mkPoint (a+x) (b+y)) points

mkPolygon :: (DomBuilder t m) => [(Int, Int)] -> (Int, Int) -> ElAttrs -> m ()
mkPolygon points center attrs = svgEl "polygon" (attrs <> "points" =: (B.run (mkPoints points center))) blank

pathPoint :: (Double, Double) -> Text
pathPoint (x, y) = tshow x <> "," <> tshow y

strokeGray :: Text
strokeGray = "stroke:#3e3e3e"

fillNone :: Text
fillNone = "fill:none"

rotate :: Show a => (a, a) -> Double -> ElAttrs
rotate (cx, cy) r = "transform" =: ("rotate(" <> tshow r <> "," <> tshow cx <> "," <> tshow cy <> ")")

strokeWidth :: Double -> Text
strokeWidth w = "stroke-width:" <> tshow w

arrowStyle :: Double -> [Text]
arrowStyle w = [strokeGray, strokeWidth w, fillNone]

data Direction = Up | Down deriving stock (Eq)

upArrow :: DomBuilder t m => m ()
upArrow = arrow Up

downArrow :: DomBuilder t m => m ()
downArrow = arrow Down

arrow :: DomBuilder t m => Direction -> m ()
arrow dir = do
  svg' width height $
    path
      [ (0, endPoint),
        (halfWidth, middlePoint),
        (width, endPoint)
      ]
      (arrowStyle w)
  where
    width = 100
    height = 70
    halfWidth = width / 2
    w = 10
    middlePoint = if dir == Down then height - w else w
    endPoint = if dir == Down then w else height - w

-- | See https://remixicon.com for icon name values to use
icon :: DomBuilder t m => Text -> m ()
icon name = elClass "i" ("ri-" <> name) blank

searchGlass :: DomBuilder t m => m ()
searchGlass = icon "search-2-line"

threeDots' :: DomBuilder t m => m ()
threeDots' = svg' size height $ do
  circle' (2 * r, cx) r mempty
  circle' (half, cx) r mempty
  circle' (size - 2 * r, cx) r mempty
  where
    size = 100
    r = 8
    height = size / 2.5
    half = size / 2
    cx = height / 2
