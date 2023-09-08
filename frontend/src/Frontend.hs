{-# LANGUAGE CPP #-}
{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE LambdaCase #-}
{-# LANGUAGE TemplateHaskell #-}
{-# LANGUAGE TupleSections #-}

module Frontend where

import Control.Monad (join)
import Control.Monad.Fix (MonadFix)
import Data.ByteString (ByteString)
import Data.Text (Text)
import qualified Data.Text as T
import Data.Text.Encoding (encodeUtf8)
import Prelude hiding (filter)

import Obelisk.Configs
import Obelisk.Frontend
import Obelisk.Route
import Obelisk.Route.Frontend
import Obelisk.Generated.Static

import Reflex.Dom.Core

import Common.Card (readCardsCsv)
import Common.Route

import Frontend.Card

data DeckType = StandardDeck | AdhocDeck

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
      text "Paste cards csv and hit render "
      render <- button "Render"
      input <- divClass "cardsInput" $ textAreaElement $ def
      let inputText = tag (current $ nonEmptyText <$> (_textAreaElement_value input)) render
      pure $ ((), cw . fmap encodeUtf8 <$> inputText)
    cw (Just csv) = Workflow $ do
      renderCards csv
      pure ((), never)
cardsWidget (Just (deck, _)) = do
  maybeCards <- getConfig $ "common/" <> deck <> ".csv"
  case maybeCards of
    Nothing -> text "could not read cards"
    Just cardLines -> renderCards cardLines

renderCards :: DomBuilder t m => ByteString -> m ()
renderCards cardLines = case readCardsCsv cardLines of
  Left err -> text $ T.pack err
  Right (_header, cards) -> divClass "cards" $ mapM_ card cards
