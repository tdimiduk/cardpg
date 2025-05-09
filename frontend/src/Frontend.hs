{-# LANGUAGE CPP #-}
{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE LambdaCase #-}
{-# LANGUAGE TemplateHaskell #-}
{-# LANGUAGE TupleSections #-}

module Frontend (frontend) where

import Control.Monad (join)
import Control.Monad.Fix (MonadFix)
import Data.ByteString (ByteString)
import Data.Csv (HasHeader(..))
import Data.Either.Combinators
import Data.Text (Text)
import qualified Data.Text as T
import Data.Text.Encoding (decodeUtf8, encodeUtf8)
import qualified Data.Vector as V
import Prelude hiding (filter)

import Obelisk.Configs
import Obelisk.Frontend
import Obelisk.Route
import Obelisk.Route.Frontend
import Obelisk.Generated.Static

import Reflex.Dom.Core

import Common.Card
import Common.CardParser
import Common.Route

import Frontend.Card
import Frontend.Demo

data DeckType = StandardDeck | AdhocDeck

data Deck = Standard [Card] | Adhoc (V.Vector AdhocCard)

deckFromRoute
  :: ( MonadFix m
     , MonadHold t m
     , Adjustable t m
     )
  => RoutedT t (R FrontendRoute) m (Dynamic t (Maybe (Text, DeckType)))
deckFromRoute = do
  r <- subRoute $ \case
    FrontendRoute_Deck -> do
      md <- askRoute
      pure (fmap (,StandardDeck) <$> md)
    FrontendRoute_Adhoc -> do
      md <- askRoute
      pure (fmap (, AdhocDeck) <$> md)
    _ -> pure $ (constDyn Nothing)
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
  , _frontend_body = subRoute_ $ \case
    FrontendRoute_Deck -> do
      md <- askRoute
      dyn_ $ cardsWidget <$> fmap (,StandardDeck) <$> md
    FrontendRoute_Adhoc -> do
      md <- askRoute
      dyn_ $ cardsWidget <$> fmap (,AdhocDeck) <$> md
    FrontendRoute_Main -> cardsWidget Nothing
    FrontendRoute_Demo -> do
      layoutOptions
  }

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
      let inputText = (current $ nonEmptyText <$> (_textAreaElement_value input))
          parse =  (leftmost [mapRight Standard . parseCards "pasted input" <$> traceEvent "pasted" (tagMaybe inputText render),
                              mapRight Adhoc . readAdhocCards NoHeader tsv . encodeUtf8 <$> tagMaybe (inputText) renderAdhoc])
          (err, cards) = fanEither parse
      widgetHold_ blank (el "pre" . text . T.pack <$> err)
      pure $ ((), cw . Just <$> cards)
    cw (Just input) = Workflow $ do
      renderDeck input
      pure ((), never)
cardsWidget (Just (deckName, deckType)) = do
  let deckPath = "common/" <> deckName <> ".tsv"
  maybeCards <- getConfig deckPath
  case maybeCards of
    Nothing -> text $ "could not read " <> deckPath
    Just cardLines -> case deckType of
      StandardDeck -> case parseCards (T.unpack deckName) (decodeUtf8 cardLines) of
        Left err -> el "pre" $ text $ T.pack err
        Right deck -> renderDeck $ Standard deck
      AdhocDeck -> renderAdhocCards cardLines

renderDeck :: DomBuilder t m => Deck -> m ()
renderDeck deck = divClass "cards" $ case deck of
  Standard cards -> mapM_ card cards
  Adhoc cards -> V.mapM_ adhocCard cards

renderAdhocCards :: DomBuilder t m => ByteString -> m ()
renderAdhocCards cardLines = case readAdhocCards HasHeader tsv cardLines of
  Left err -> text $ T.pack err
  Right cards -> divClass "cards" $ mapM_ adhocCard cards
