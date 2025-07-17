module Frontend.Card
  ( card
  , adhocCard
  , textboxArea
  , costSymbol
  ) where

import Data.List.NonEmpty (NonEmpty(..), (<|))
import Data.Text (Text)
import qualified Data.Vector as V

import Reflex.Dom.Core

import Common.Util
import Common.Card (CoreCard(..), Resources(..), Cost(..), Textbox(..), ActionStrength(..), Action(..), Attack(..), StandardDefend(..), AdhocCard(..))
import Common.Card.Common

import Frontend.Card.Common

card :: DomBuilder t m => CoreCard -> m ()
card = cardHtml

cardHtml :: DomBuilder t m => CoreCard -> m ()
cardHtml (CoreCard _ name resources cost textbox) = divClass "card" $ do
  divClass "flex" $ do
    divClass "name" $ text name
    divClass "expand" blank
    costSymbol cost
  divClass "flex" $ do
    resourcesArea resources
    art
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
  mapM_ (divClass "effect" . renderCardBlocks) effect
  mapM_ (divClass "details" . renderCardBlocks) details

modifierText :: Int -> Maybe Text
modifierText x
  | x == 0 = Nothing
  | x > 0 = Just $ "+" <> (tshow x)
  | otherwise = Just $ tshow x

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

actionStrength :: ActionStrength -> CardText
actionStrength (ActionStrength r m) = ResourceIcon r :| maybe mempty (pure . Txt) (modifierText m)

action :: DomBuilder t m => Maybe Action -> m ()
action Nothing = blank
action (Just a) = divClass "action" $ case a of
  GeneralAction t -> renderCardBlocks t
  AttackAction x -> renderCardBlocks $ attack x
  DefendAction d -> standardDefend d
  SpecialDefend t -> do
    text "Defend: "
    renderCardBlocks t

attack :: Attack -> CardBlocks
attack (Attack resistBy strength otherText) = case otherText of
  Nothing -> pure $ Paragraph main
  Just (Paragraph start :| rest) -> Paragraph (main <> start) :| rest
  Just t -> Paragraph main <| t
  where
    main = (Txt "Attack " :| [ResourceIcon resistBy, Txt ": "]) <> actionStrength strength

standardDefend :: DomBuilder t m => StandardDefend -> m ()
standardDefend (StandardDefend resists strength otherText) = do
  text "Defend "
  renderDefendsList resists
  text ": "
  renderCardText $ actionStrength strength
  maybe blank renderCardBlocks otherText

adhocCard :: DomBuilder t m => AdhocCard -> m ()
adhocCard c = divClass "card" $ do
  divClass "name" $ text $ _ahcName c
  divClass "art" blank
  divClass "textbox" $ V.mapM_ (divClass "block" . text) $ _blocks c
