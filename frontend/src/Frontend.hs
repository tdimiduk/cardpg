{-# LANGUAGE CPP #-}
{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE LambdaCase #-}
{-# LANGUAGE TemplateHaskell #-}

module Frontend where

import qualified Data.ByteString.Lazy as LBS
import qualified Data.Text as T
import Data.Csv
import Data.Sequences
import Prelude hiding (filter)

import Obelisk.Configs
import Obelisk.Frontend
import Obelisk.Route
import Obelisk.Generated.Static

import Reflex.Dom.Core

import Common.Card
import Common.Route

import Frontend.Card

deck :: T.Text
deck = "monsters"

-- This runs in a monad that can be run on the client or the server.
-- To run code in a pure client or pure server context, use one of the
-- `prerender` functions.
frontend :: Frontend (R FrontendRoute)
frontend = Frontend
  { _frontend_head = do
      el "title" $ text deck
      elAttr "link" ("href" =: $(static "main.css") <> "type" =: "text/css" <> "rel" =: "stylesheet") blank
  , _frontend_body = do
      maybeCards <- getConfig $ "common/" <> deck <> ".csv"
      case maybeCards of
        Nothing -> text "could not read cards"
        Just cardLines -> case decodeByName (LBS.fromStrict cardLines) of
          Left err -> text $ T.pack err
          Right (_header, cards) -> divClass "cards" $ mapM_ card cards
      return ()
  }
