module Frontend.Card
  ( card
  , adhocCard
  ) where

import Data.List.NonEmpty (NonEmpty(..))
import qualified Data.Vector as V

import Reflex.Dom.Core

import Common.Util
import Common.Card

import Frontend.Card.Common

card :: DomBuilder t m => Card -> m ()
card = cardHtml

cardHtml :: DomBuilder t m => Card -> m ()
cardHtml (Card _ name resources cost textbox) = divClass "card" $ do
  divClass "flex" $ do
    divClass "name" $ text name
    divClass "expand" blank
    costSymbol cost
  divClass "flex" $ do
    resourcesArea resources
    divClass "art" blank
  textboxArea textbox

costSymbol :: DomBuilder t m => Cost -> m ()
costSymbol (Cost (Just c) _) = divClass "cost" (text c)
costSymbol (Cost Nothing _) = blank

resourcesArea :: DomBuilder t m => Resources -> m ()
resourcesArea (Resources red yellow blue _) = do
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

actionStrength :: DomBuilder t m => ActionStrength -> m ()
actionStrength (ActionStrength r m) = do
  resourceSymbol r
  renderModifier m

action :: DomBuilder t m => Maybe Action -> m ()
action Nothing = blank
action (Just a) = divClass "action" $ case a of
  GeneralAction t -> fancyText t
  Attack resistBy strength otherText -> do
    text "Attack "
    resourceSymbol resistBy
    text ": "
    actionStrength strength
    maybe blank fancyText' otherText
  StandardDefend resists strength otherText -> do
    text "Defend "
    renderDefendsList resists
    text ": "
    actionStrength strength
    maybe blank fancyText' otherText
  SpecialDefend t -> do
    text "Defend: "
    fancyText t

adhocCard :: DomBuilder t m => AdhocCard -> m ()
adhocCard (AdhocCard name blocks) = divClass "card" $ do
  divClass "name" $ text name
  divClass "art" blank
  divClass "textbox" $ V.mapM_ (divClass "block" . text) blocks
