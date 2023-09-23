module Frontend.Card where

import Data.Maybe (isNothing)
import Data.List.NonEmpty (NonEmpty(..))
import Data.Text (Text, splitOn, strip, intercalate)
import qualified Data.Text as T
import qualified Data.Vector as V
import Witherable

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

mtshow :: Show a => Maybe a -> Text
mtshow Nothing = ""
mtshow (Just t) = tshow t

card :: DomBuilder t m => Card -> m ()
card = cardHtml

maybeText :: DomBuilder t m => Maybe Text -> m ()
maybeText Nothing = blank
maybeText (Just t) = text t

cardHtml :: DomBuilder t m => Card -> m ()
cardHtml (Card _ name resources cost textbox) = divClass "card" $ do
  divClass "name" $ text name
  divClass "art" blank
  costLine cost
  textboxArea textbox
  resourcesArea resources

costLine :: DomBuilder t m => Cost -> m ()
costLine (Cost Nothing Nothing) = blank
costLine (Cost c k) = divClass "cost" (text $ "Cost: " <> intercalate ", " (catMaybes [c, k]))

resourcesArea :: DomBuilder t m => Resources -> m ()
resourcesArea (Resources red yellow blue keywordProvide) = do
  maybe blank (divClass "keywords" . elClass "span" "keywords" . text) keywordProvide
  divClass "numbers" $ do
    resourceSymbol' Red red
    resourceSymbol' Yellow yellow
    resourceSymbol' Blue blue

textboxArea :: DomBuilder t m => Textbox -> m ()
textboxArea (Textbox a effect details) = divClass "textbox" $ do
  action a
  divClass "effect" $ maybeText effect
  case details of
    Nothing -> blank
    Just d -> mapM_ (divClass "details" . text) (splitOn ";" d)

renderModifier :: DomBuilder t m => Int -> m ()
renderModifier x
  | x == 0 = blank
  | x > 0 = text "+" >> text (tshow x)
  | otherwise = text (tshow x)

renderDefendsList :: DomBuilder t m => NonEmpty ResourceType -> m ()
renderDefendsList (a :| [b, c]) = do
  resourceSymbol a
  text ", "
  resourceSymbol b
  text " or "
  resourceSymbol c
renderDefendsList (a :| [b]) = do
  resourceSymbol a
  text " or "
  resourceSymbol b
renderDefendsList (a :| []) = do
  resourceSymbol a
renderDefendsList _ = text "error: too many resources"


action :: DomBuilder t m => Maybe Action -> m ()
action Nothing = blank
action (Just a) = divClass "action" $ case a of
  GeneralAction t -> text t
  Attack resistBy strengthBy strengthPlus otherText -> do
    text "Attack "
    resourceSymbol resistBy
    text ": strength = "
    resourceSymbol strengthBy
    renderModifier strengthPlus
    maybeText otherText
  StandardDefend resists resistsWith strMod otherText -> do
    text "Defend "
    renderDefendsList resists
    text ": strength = "
    resourceSymbol resistsWith
    renderModifier strMod
    maybeText otherText
  SpecialDefend t -> do
    text "Defend: "
    text t


resourceSymbol :: DomBuilder t m => ResourceType -> m ()
resourceSymbol a = resourceSymbol' a Nothing

resourceSymbol' :: DomBuilder t m => ResourceType -> Maybe Text -> m ()
resourceSymbol' r t = elClass container ("resource-container " <> (T.toLower (tshow r))) $ do
  mapM_ (elClass container "resource-text"  . text) t
  svg' size size $ case r of
    Red -> rectC (c, c) (rectSize, rectSize) (strokeWidth w)
    Yellow -> circle (c, c) (size - c - w) w
    Blue -> rectC (c, c) (diamondSize, diamondSize) (rotate (c, c) 45 <> strokeWidth w)
  where
    container = if isNothing t then "span" else "div"
    size = 100
    diamondSize = 65
    rectSize = 80
    w = 10
    c = 50

adhocCard :: DomBuilder t m => AdhocCard -> m ()
adhocCard (AdhocCard name blocks) = divClass "card" $ do
  divClass "name" $ text name
  divClass "art" blank
  divClass "textbox" $ V.mapM_ (divClass "block" . text) blocks

star ::
  DomBuilder t m
  => (Double, Double)
  -> (Double, Double)
  -> ElAttrs
  -> m ()
star center size attrs = do
  rectC center size (attrs <> roundCorners 2)
  rectC center size (attrs <> roundCorners 2 <> rotate center 45)

textBlock :: DomBuilder t m => Double -> Double -> Text -> m ()
textBlock x y t = svgEl "text" (xyPair id (x, y) <> "font-size" =: "0.8em") (mapM_ renderLine blocks)
  where
    blocks = splitOn ";" t
    renderLine l = svgEl "tspan" ("dy" =: "18" <> "x" =: tshow x) (text $ strip l)


cardText :: DomBuilder t m => Double -> Double -> Text -> m ()
cardText x y t = svgEl "text" (xyPair id (x, y) <> "dominant-baseline" =: "middle") (text t)

cardNum :: DomBuilder t m => Double -> Double -> Text -> m ()
cardNum x y t = svgEl "text" (xyPair id (x, y) <> "text-anchor" =: "middle" <> "dominant-baseline" =: "middle" ) (text t)

trianglePoints :: [(Int, Int)]
trianglePoints = [(0,-40), (20, 0), (40,40), (-40,40)]

roundCorners :: Double -> ElAttrs
roundCorners x = rxy (x, x)

starPath :: Text
starPath = "M7.5 0.25 L9.375 6 h5.625 L10.375 9.25 L12.25 14.875 L7.5 11.375 L2.75 14.875 L4.625 9.25 L0 6 h5.625 Z"
