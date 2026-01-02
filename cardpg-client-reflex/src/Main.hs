{-# LANGUAGE LambdaCase #-}
{-# LANGUAGE MonoLocalBinds #-}
{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE RecursiveDo #-}
{-# LANGUAGE ScopedTypeVariables #-}

module Main where

import Control.Monad (void)
import Data.Aeson
  ( FromJSON (..)
  , eitherDecode
  , encode
  , genericParseJSON
  )
import Data.ByteString.Lazy qualified as BL
import Data.Map (Map)
import Data.Map qualified as Map
import Data.Text (Text)
import Data.Text qualified as T
import Data.UUID (UUID)
import Data.UUID.V4 qualified as UUID
import GHC.Generics (Generic)
import Language.Javascript.JSaddle.WebSockets (jsaddleApp, jsaddleOr)
import Network.Wai (Application)
import Network.Wai.Handler.Warp (run)
import Network.WebSockets (defaultConnectionOptions)
import Reflex.Dom.Core
import Reflex.Dom.Main (mainWidgetWithHead)
import System.Environment (lookupEnv)

import CardPG.Api.Types qualified as Api -- Still used for sending Join
import CardPG.Core.Card (CardInstance, CoreCard)
import CardPG.Core.Json (cardpgJsonDef)
import CardPG.Core.Primitives (ActorId)
import Frontend.Card ()
import Frontend.Html (Render (..))

-- Local definition matching server
data ReflexServerMessage
  = ReflexWelcome
      { yourClientId :: UUID
      , hands :: Map ActorId [CardInstance CoreCard]
      }
  | ReflexUpdate
      { hands :: Map ActorId [CardInstance CoreCard]
      }
  | ReflexError {error :: Text}
  deriving (Show, Generic)

instance FromJSON ReflexServerMessage where
  parseJSON = genericParseJSON cardpgJsonDef

main :: IO ()
main = do
  putStrLn "Starting CardPG Reflex Client..."
  clientId <- UUID.nextRandom
  port <- maybe 3003 read <$> lookupEnv "JSADDLE_WARP_PORT"
  putStrLn $ "Running jsaddle-warp server on port " <> show port

  -- Build the jsaddle application with websocket support
  jsaddleApplication <-
    jsaddleOr
      defaultConnectionOptions
      (mainWidgetWithHead headWidget (bodyWidget clientId))
      jsaddleApp

  run port jsaddleApplication

headWidget :: (DomBuilder t m) => m ()
headWidget = do
  el "title" $ text "CardPG Reflex Client"
  elAttr "meta" ("charset" =: "utf-8") blank
  elAttr "link" ("rel" =: "stylesheet" <> "href" =: "/output.css") blank

bodyWidget :: (MonadWidget t m) => UUID -> m ()
bodyWidget clientId = do
  let
    wsUrl = "ws://localhost:3004/api?clientId=" <> T.pack (show clientId) <> "&name=ReflexReflex"

  el "h1" $ text "Websocket Hand Spike"

  rec let
        -- Send Join message immediately on open using Api types for compatibility with input parser
        joinMsg = Api.Join "ReflexReflex" Nothing
        sendEvt = fmap (const [BL.toStrict $ encode joinMsg]) (_webSocket_open ws)

        wsConfig = def{_webSocketConfig_send = sendEvt}

      ws <- webSocket wsUrl wsConfig

      let serverMsgEvt = fmap (eitherDecode . BL.fromStrict) (_webSocket_recv ws)

      -- Debug: show last message status
      divClass "status" $ do
        let statusText = ffor serverMsgEvt $ \case
              Left e -> "Decode Error: " <> T.pack e
              Right (ReflexWelcome{}) -> "Welcome received"
              Right (ReflexUpdate{}) -> "Update received"
              Right (ReflexError e) -> "Error: " <> e

        dynText =<< holdDyn "Connecting..." statusText

      -- State: Hold the hands of all actors
      let
        updateHands (Right (ReflexWelcome _ h)) _ = h
        updateHands (Right (ReflexUpdate h)) _ = h
        updateHands _ old = old

      handsMapDyn <- foldDyn updateHands Map.empty serverMsgEvt

  el "h2" $ text "Cards in Hand"

  -- Render a section for each actor found
  let tshow = T.pack . show
  void $ listWithKey handsMapDyn $ \actorId cardsDyn -> do
    el "h3" $ text $ "Actor: " <> tshow actorId
    elClass "div" "hand-container" $ do
      simpleList cardsDyn $ \cardDyn -> do
        dyn_ $ ffor cardDyn render
