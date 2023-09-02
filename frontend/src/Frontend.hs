{-# LANGUAGE CPP #-}
{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE LambdaCase #-}
{-# LANGUAGE TemplateHaskell #-}

module Frontend where

import Control.Monad (join)
import Control.Monad.Fix (MonadFix)
import qualified Data.ByteString.Lazy as LBS
import Data.Maybe (fromMaybe)
import Data.Text (Text)
import qualified Data.Text as T
import Data.Csv
import Data.Sequences
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

deckFromRoute
  :: ( MonadFix m
     , MonadHold t m
     , Adjustable t m
     )
  => RoutedT t (R FrontendRoute) m (Dynamic t (Maybe Text))
deckFromRoute = do
  r <- subRoute $ \case
    FrontendRoute_Main -> pure $ pure Nothing
    FrontendRoute_Deck -> askRoute
  pure $ join r

-- This runs in a monad that can be run on the client or the server.
-- To run code in a pure client or pure server context, use one of the
-- `prerender` functions.
frontend :: Frontend (R FrontendRoute)
frontend = Frontend
  { _frontend_head = do
      deck <- deckFromRoute
      el "title" $ dynText $ fromMaybe "CaRdPG" <$> deck
      elAttr "link" ("href" =: $(static "main.css") <> "type" =: "text/css" <> "rel" =: "stylesheet") blank
  , _frontend_body = do
      deck <- deckFromRoute
      dyn_ $ renderCards <$> deck
  }


renderCards Nothing = text "put deck name in url"
renderCards (Just deck) = do
  maybeCards <- getConfig $ "common/" <> deck <> ".csv"
  case maybeCards of
    Nothing -> text "could not read cards"
    Just cardLines -> case decodeByName (LBS.fromStrict cardLines) of
      Left err -> text $ T.pack err
      Right (_header, cards) -> divClass "cards" $ mapM_ card cards
