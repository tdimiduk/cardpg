-- Defining rendering orphans which are frontend only
{-# options_ghc -fno-warn-orphans #-}
{-# LANGUAGE DeriveAnyClass #-}

module Frontend.Card
  ( ) where

import Control.Lens hiding ((<|))
import Data.Generics.Labels ()
import Data.List.NonEmpty (NonEmpty(..), (<|))
import Data.Text (Text, pack)
import qualified Data.Vector as V

import Reflex.Dom.Core

import Common.Util
import Common.Card
import Common.Card.Common

import Frontend.Card.Common
import Frontend.Html

instance DomBuilder t m => Render CoreCard m where
  render c = divClass "card" $ do
    divClass "flex" $ do
      divClass "name" $ text $ c ^. #_name
      divClass "expand" blank
      render $ c ^. #_cost
    divClass "flex" $ do
      render $ c ^. #_resources
      art
    render $ c ^. #_textbox

instance DomBuilder t m => Render Cost m where
  render (Cost (Just c) _) = divClass "cost" (text c)
  render (Cost Nothing _) = blank

instance DomBuilder t m => Render Resources m where
  render (Resources red yellow blue _) = do
    divClass "numbers" $ do
      render $ ResourceValue Red red
      render $ ResourceValue Yellow yellow
      render $ ResourceValue Blue blue

instance (DomBuilder t m) => Render Textbox m where
  render t = divClass "textbox" $ do
    render $ t ^. #_action
    mapM_ (divClass "effect" . render) $ t ^. #_effect
    mapM_ (divClass "details" . render) $ t ^. #_details

modifierText :: Int -> Maybe Text
modifierText x
  | x == 0 = Nothing
  | x > 0 = Just $ "+" <> (tshow x)
  | otherwise = Just $ tshow x

defendsList :: NonEmpty ResourceType -> CardText
defendsList (a :| [b, c]) = ResourceIcon a :| [Txt ", ", ResourceIcon b, Txt ", or", ResourceIcon c]
defendsList (a :| [b]) = ResourceIcon a :| [Txt " or ", ResourceIcon b]
defendsList (a :| []) = ResourceIcon a :| []
-- TODO make the types enforce this
defendsList _ = error "too many resources"

actionStrength :: ActionStrength -> CardText
actionStrength (ActionStrength r m) = ResourceIcon r :| maybe mempty (pure . Txt) (modifierText m)

instance DomBuilder t m => Render Action m where
  render a = divClass "action" $ render $ case a of
    GeneralAction t -> t
    AttackAction x -> attack x
    DefendAction d -> standardDefend d
    SpecialDefend t -> prependToFirstParagraph (asCardText "Defend: ") t

attack :: Attack -> CardBlocks
attack (Attack resistBy strength otherText) = case otherText of
  Nothing -> pure $ Paragraph main
  Just (Paragraph start :| rest) -> Paragraph (main <> start) :| rest
  Just t -> prependToFirstParagraph main t
  where
    main = (Txt "Attack " :| [ResourceIcon resistBy, Txt ": "]) <> actionStrength strength

standardDefend :: StandardDefend -> CardBlocks
standardDefend (StandardDefend resists strength otherText) = case otherText of
  Nothing -> pure $ Paragraph main
  Just t -> Paragraph main <| t
  where
    main = (Txt "Defend " <| defendsList resists) <> (Txt ": " <| actionStrength strength)

instance DomBuilder t m => Render AdhocCard m where
  render c = divClass "card" $ do
    divClass "name" $ text $ _ahcName c
    divClass "art" blank
    divClass "textbox" $ V.mapM_ (divClass "block" . text) $ _blocks c

instance DomBuilder t m => Render ConsequenceCard m where
  render c = divClass "card" $ do
    divClass "flex" $ do
      divClass "name" $ text $ c ^. #name
      divClass "expand" blank
      divClass "cost" $ text $ pack $ show $ severity c
    art
    divClass "textbox" $ render $ c ^. #effect
