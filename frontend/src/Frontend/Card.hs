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
  mapM_ (divClass "effect" . fancyText) effect
  mapM_ (divClass "details" . fancyText) details

renderModifier :: DomBuilder t m => Int -> m ()
renderModifier x
  | x == 0 = blank
  | x > 0 = text "+" >> text (tshow x)
  | otherwise = text (tshow x)

fancyText :: DomBuilder t m => FancyText -> m ()
fancyText (FancyText tokens) = mapM_ render tokens
  where
    render (FancyTextToken t) = text t
    render (ResourceToken t) = resourceSymbol t

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
  GeneralAction t -> fancyText t
  Attack resistBy strengthBy strengthPlus otherText -> do
    text "Attack "
    resourceSymbol resistBy
    text ": "
    resourceSymbol strengthBy
    renderModifier strengthPlus
    maybeText (fmap (" " <>) otherText)
  StandardDefend resists resistsWith strMod otherText -> do
    text "Defend "
    renderDefendsList resists
    text ": strength = "
    resourceSymbol resistsWith
    renderModifier strMod
    maybeText (fmap (" " <>) otherText)
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

textBlock :: DomBuilder t m => Double -> Double -> Text -> m ()
textBlock x y t = svgEl "text" (xyPair id (x, y) <> "font-size" =: "0.8em") (mapM_ renderLine blocks)
  where
    blocks = splitOn ";" t
    renderLine l = svgEl "tspan" ("dy" =: "18" <> "x" =: tshow x) (text $ strip l)
