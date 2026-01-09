{-# LANGUAGE MonoLocalBinds #-}
{-# LANGUAGE MultilineStrings #-}
{-# LANGUAGE RankNTypes #-}

module Main where

import Data.UUID.V4 qualified as UUID
import Language.Javascript.JSaddle.WebSockets (jsaddleJs, jsaddleOr)
import Network.HTTP.Types (status200)
import Network.Wai (Application, pathInfo, requestMethod, responseLBS)
import Network.Wai.Application.Static (defaultWebAppSettings, staticApp)
import Network.Wai.Handler.Warp (run)
import Network.WebSockets (defaultConnectionOptions)
import Reflex.Dom.Core
import System.Environment (lookupEnv)
import WaiAppStatic.Types (ssIndices, unsafeToPiece)

import Api.Reflex ()
import Frontend.App (appWidget)

-- | Middleware that serves /jsaddle.js, falling back to another app for all other routes.
-- Unlike jsaddleAppWithJsOr, this does NOT intercept the root "/" path.
serveJsaddleJs :: Application -> Application
serveJsaddleJs fallback req sendResponse =
  case (requestMethod req, pathInfo req) of
    ("GET", ["jsaddle.js"]) ->
      sendResponse $ responseLBS status200 [("Content-Type", "application/javascript")] (jsaddleJs False)
    _ ->
      fallback req sendResponse

main :: IO ()
main = do
  putStrLn "Starting CardPG Reflex Client (STATIC REFACTOR VERSION)..."
  clientId <- UUID.nextRandom
  port <- maybe 3003 read <$> lookupEnv "JSADDLE_WARP_PORT"
  putStrLn $ "Running jsaddle-warp server on port " <> show port

  -- Static app settings: serve from "static" directory
  let staticSettings =
        (defaultWebAppSettings "static")
          { ssIndices = [unsafeToPiece "index.html"]
          }

  -- Build the jsaddle application with websocket support
  -- serveJsaddleJs serves /jsaddle.js, falling back to staticApp for other routes
  -- (Unlike jsaddleAppWithJsOr, this doesn't hijack the root "/" path)
  jsaddleApplication <-
    jsaddleOr
      defaultConnectionOptions
      (mainWidgetInElementById "app" (appWidget clientId))
      (serveJsaddleJs (staticApp staticSettings))

  run port jsaddleApplication
