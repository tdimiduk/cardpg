module Frontend.Demo where

import Data.Text (Text)

import Reflex.Dom.Core

import Common.Card (CoreCard(..), Textbox(..), Resources(..), Cost(..), Action(..), Attack(..), ActionStrength(..))
import Common.Card.Common

import Frontend.Card
import Frontend.Card.Common

layoutOptions :: DomBuilder t m => m ()
layoutOptions = divClass "cards" $ do
  costLeftVertical $ demoCard "Left Vertical" "Original proposed location"
  costRightVertical $ demoCard "Right Vertical" "Collect numbers together. Does the cost get confused with the resources?"
  costAbove $ demoCard "Very Top" "Is this weird? Numbers are an early thing you want to see, but above name?"
  costBelowName $ demoCard "Below Name" ""
  costLeftHoriz $ demoCard "Left Horizontal" ""

demoCard :: Text -> Text -> CoreCard
demoCard name bodyText = CoreCard
  { _actor = "Demo"
  , _name = name
  , _resources = Resources (Just "3") (Just "2") (Just "4") Nothing
  , _cost = Cost (Just "2") Nothing
  , _textbox = demoTextbox $ Just bodyText
  }

demoTextbox :: Maybe Text -> Textbox
demoTextbox d = Textbox
  { _action = Just $ AttackAction $ Attack Red (ActionStrength Red 1) Nothing
  , _effect = Nothing
  , _details = asCardText <$> d
  }

numbers :: DomBuilder t m => Resources -> m ()
numbers (Resources red yellow blue _) = elClass "div" "numbers flex-row" $ do
  resourceSymbol' Red red
  resourceSymbol' Yellow yellow
  resourceSymbol' Blue blue

numbers' :: DomBuilder t m => Text -> Resources -> m ()
numbers' extraClass (Resources red yellow blue _) = elClass "div" ("numbers flex-row " <> extraClass) $ do
  resourceSymbol' Red red
  resourceSymbol' Yellow yellow
  resourceSymbol' Blue blue

titleLine :: DomBuilder t m => Text -> Cost -> m ()
titleLine name cost = divClass "flex" $ do
  divClass "name" $ text name
  divClass "expand" blank
  costSymbol cost

costAbove :: DomBuilder t m => CoreCard -> m ()
costAbove (CoreCard _ name resources cost textbox) = divClass "card" $ do
  numbers resources
  titleLine name cost
  elClass "div" "flex" $ divClass "art-short" blank
  textboxArea textbox

costRightVertical :: DomBuilder t m => CoreCard -> m ()
costRightVertical (CoreCard _ name resources cost textbox) = divClass "card" $ do
  titleLine name cost
  elClass "div" "flex" $ do
    art
    elClass "div" "flex flex-col" $ do
      divClass "expand" blank
      numbers' "flex-col h-18" resources
  textboxArea textbox

costLeftVertical :: DomBuilder t m => CoreCard -> m ()
costLeftVertical (CoreCard _ name resources cost textbox) = divClass "card" $ do
  titleLine name cost
  elClass "div" "flex" $ do
    numbers' "flex-col h-18" resources
    art
  textboxArea textbox

costBelowName :: DomBuilder t m => CoreCard -> m ()
costBelowName (CoreCard _ name resources cost textbox) = divClass "card" $ do
  titleLine name cost
  numbers resources
  elClass "div" "flex" $ divClass "art-short" blank
  textboxArea textbox


costLeftHoriz :: DomBuilder t m => CoreCard -> m ()
costLeftHoriz (CoreCard _ name resources cost textbox) = divClass "card" $ do
  titleLine name cost
  numbers' "w-18" resources
  elClass "div" "flex" $ divClass "art-short" blank
  textboxArea textbox
