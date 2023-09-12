{-# LANGUAGE CPP #-}
{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE LambdaCase #-}
{-# LANGUAGE TemplateHaskell #-}
{-# LANGUAGE TupleSections #-}

module Frontend where

import Control.Monad (join)
import Control.Monad.Fix (MonadFix)
import Data.ByteString (ByteString)
import Data.Csv (HasHeader(..))
import Data.Either.Combinators
import Data.Text (Text)
import qualified Data.Text as T
import Data.Text.Encoding (encodeUtf8)
import qualified Data.Vector as V
import Prelude hiding (filter)

import Obelisk.Configs
import Obelisk.Frontend
import Obelisk.Route
import Obelisk.Route.Frontend
import Obelisk.Generated.Static

import Reflex.Dom.Core

import Common.Card
import Common.Route

import Frontend.Card

data DeckType = StandardDeck | AdhocDeck

data Deck = Standard (V.Vector Card) | Adhoc (V.Vector AdhocCard)

deckFromRoute
  :: ( MonadFix m
     , MonadHold t m
     , Adjustable t m
     )
  => RoutedT t (R FrontendRoute) m (Dynamic t (Maybe (Text, DeckType)))
deckFromRoute = do
  r <- subRoute $ \case
    FrontendRoute_Main -> pure $ (constDyn Nothing)
    FrontendRoute_Deck -> do
      md <- askRoute
      pure (fmap (,StandardDeck) <$> md)
    FrontendRoute_Adhoc -> do
      md <- askRoute
      pure (fmap (, AdhocDeck) <$> md)
  pure $ join r


-- This runs in a monad that can be run on the client or the server.
-- To run code in a pure client or pure server context, use one of the
-- `prerender` functions.
frontend :: Frontend (R FrontendRoute)
frontend = Frontend
  { _frontend_head = do
      deck <- deckFromRoute
      el "title" $ dynText $ maybe "CaRdPG" fst <$> deck
      elAttr "link" ("href" =: $(static "main.css") <> "type" =: "text/css" <> "rel" =: "stylesheet") blank
  , _frontend_body = do
      deck <- deckFromRoute
      dyn_ $ cardsWidget <$> deck
  }

nonEmptyText :: Text -> Maybe Text
nonEmptyText t = if T.null (T.strip t) then Nothing else Just (T.strip t)

cardsWidget :: (DomBuilder t m, HasConfigs m, MonadFix m, MonadHold t m) => Maybe (Text, DeckType) -> m ()
cardsWidget Nothing = do
  _ <- workflow (cw Nothing)
  pure ()
  where
    cw Nothing = Workflow $ do
      text "Paste cards and hit render "
      render <- button "Render Standard"
      renderAdhoc <- button "Render Adhoc"
      input <- divClass "cardsInput" $ textAreaElement $ def
      let inputText = fmap encodeUtf8 <$> (current $ nonEmptyText <$> (_textAreaElement_value input))
          parse =  (leftmost [mapRight Standard . readStandardCards tsv <$> tagMaybe inputText render,
                              mapRight Adhoc . readAdhocCards NoHeader tsv <$> tagMaybe inputText renderAdhoc])
          (err, cards) = fanEither parse
      widgetHold_ blank (text . T.pack <$> err)
      pure $ ((), cw . Just <$> cards)
    cw (Just input) = Workflow $ do
      renderDeck input
      pure ((), never)
cardsWidget (Just (deck, deckType)) = do
  maybeCards <- getConfig $ "common/" <> deck <> ".csv"
  case maybeCards of
    Nothing -> text "could not read cards"
    Just cardLines -> case deckType of
      StandardDeck -> renderCards csv cardLines
      AdhocDeck -> renderAdhocCards csv cardLines

renderDeck :: DomBuilder t m => Deck -> m ()
renderDeck deck = divClass "cards" $ case deck of
  Standard cards -> V.mapM_ card cards
  Adhoc cards -> V.mapM_ adhocCard cards

renderCards :: DomBuilder t m => InputDelimeter -> ByteString -> m ()
renderCards del cardLines = case readStandardCards del cardLines of
  Left err -> text $ T.pack err
  Right (cards) -> divClass "cards" $ mapM_ card cards

renderAdhocCards :: DomBuilder t m => InputDelimeter -> ByteString -> m ()
renderAdhocCards del cardLines = case readAdhocCards HasHeader del cardLines of
  Left err -> text $ T.pack err
  Right cards -> divClass "cards" $ mapM_ adhocCard cards
