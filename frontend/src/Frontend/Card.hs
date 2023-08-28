module Frontend.Card where

import Data.Text (Text, splitOn, strip)
import Data.Maybe (fromMaybe)

import Reflex.Dom.Core

import Common.Util
import Common.Card

import Frontend.Svg

rnx :: Double
rnx = 15

lnx :: Double
lnx = 185

tny :: Double
tny = 15

bny :: Double
bny = 285

mtshow Nothing = ""
mtshow (Just t) = tshow t

rectSize = (20, 20)


card :: DomBuilder t m => Card -> m ()
card (Card name red yellow blue green cost bodyText) = do
  svgEl "svg" (widthHeight 200 300) $ do
    rect' ("stroke" =: "black" <> fill "transparent" <> widthHeight' (<> "%") 100 100 <> roundCorners 10)
    cardText 40 15 name
    resourceSymbol (rnx, tny) red (\c -> rectC c rectSize (fill "red" <> roundCorners 3))
    resourceSymbol (lnx, tny) yellow (\c -> star c rectSize (fill "yellow"))
    resourceSymbol (lnx, bny) (fromMaybe 0 green) (\c -> circle' c 10 (fill "green"))
    resourceSymbol (rnx, bny) (fromMaybe 0 blue) (\c -> rectC c rectSize (fill "rgb(80, 80, 255)" <> roundCorners 3 <> rotate c 45))
    case cost of
      Nothing -> blank
      (Just c) -> cardText 5 140 $ "Cost: " <> c
    textBlock 5 145 bodyText

star center size attrs = do
  rectC center size (attrs <> roundCorners 2)
  rectC center size (attrs <> roundCorners 2 <> rotate center 45)

resourceSymbol (x, y) number symbol = el "g" $ do
  symbol (x, y)
  cardNum x (y+2) (tshow number)

textBlock :: DomBuilder t m => Double -> Double -> Text -> m ()
textBlock x y t = svgEl "text" (xyPair id (x, y) <> "font-size" =: "0.8em") (mapM_ renderLine (zip [1..] lines))
  where
    lines = splitOn ";" t
    renderLine (i, l) = svgEl "tspan" ("dy" =: "18" <> "x" =: tshow x) (text $ strip l)


cardText :: DomBuilder t m => Double -> Double -> Text -> m ()
cardText x y t = svgEl "text" (xyPair id (x, y) <> "dominant-baseline" =: "middle") (text t)

cardNum :: DomBuilder t m => Double -> Double -> Text -> m ()
cardNum x y t = svgEl "text" (xyPair id (x, y) <> "text-anchor" =: "middle" <> "dominant-baseline" =: "middle" ) (text t)

mkStar :: (DomBuilder t m) => Text -> (Int, Int) -> m ()
mkStar color center = do
  mkPolygon trianglePoints center c
  mkPolygon trianglePoints center (c <> rotate center 180)
  where
    c = "color" =: color


trianglePoints :: [(Int, Int)]
trianglePoints = [(0,-40), (20, 0), (40,40), (-40,40)]

roundCorners :: Double -> ElAttrs
roundCorners x = rxy (x, x)

starPath :: Text
starPath = "M7.5 0.25 L9.375 6 h5.625 L10.375 9.25 L12.25 14.875 L7.5 11.375 L2.75 14.875 L4.625 9.25 L0 6 h5.625 Z"
