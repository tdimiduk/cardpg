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
card = cardHtml

maybeText :: DomBuilder t m => Maybe Text -> m ()
maybeText Nothing = blank
maybeText (Just t) = text t

cardHtml :: DomBuilder t m => Card -> m ()
cardHtml (Card name red yellow blue cost action effect details) = divClass "card" $ do
  divClass "name" $ text name
  divClass "art" blank
  divClass "cost" $ maybeText $ fmap ("Cost:" <>) cost
  divClass "textbox" $ do
    divClass "action" $ maybeText action
    divClass "effect" $ maybeText effect
    case details of
      Nothing -> blank
      Just d -> mapM_ (divClass "details" . text) (splitOn ";" d)
  divClass "numbers" $ do
    divClass "red" $ text red
    divClass "yellow" $ text yellow
    divClass "blue" $ text blue

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
