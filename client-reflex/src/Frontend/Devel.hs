{-# LANGUAGE CPP #-}
{-# LANGUAGE MonoLocalBinds #-}
{-# LANGUAGE MultilineStrings #-}
{-# LANGUAGE RankNTypes #-}

module Frontend.Devel where

#if !defined(ghcjs_HOST_OS) && !defined(javascript_HOST_ARCH)
import Control.Concurrent (forkIO, killThread)
import Control.Exception (SomeException, catch)
import Data.Word (Word32)
import Foreign.Store (Store (..), lookupStore, readStore, writeStore)
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

-- | Store index for the server thread IDs.
-- Using foreign-store to persist state across GHCi reloads.
serverStoreIndex :: Word32
serverStoreIndex = 0

-- | Stop the currently running server if any.
stopServer :: IO ()
stopServer = do
  mStore <- lookupStore serverStoreIndex
  case mStore of
    Nothing -> pure ()
    Just store -> do
      tid <- readStore store
      putStrLn "Stopping previous server instance..."
      killThread tid `catch` \(_ :: SomeException) -> pure ()

devMain :: IO ()
devMain = do
  -- Kill any existing server from previous reload
  stopServer

  putStrLn "Starting CardPG Reflex Client ..."
  -- Hardcoding something to avoid the UUID dependency
  let clientId = read "00000000-0000-0000-0000-000000000001"
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
  -- The appWidget connects to localhost:3004/api for the backend
  jsaddleApplication <-
    jsaddleOr
      defaultConnectionOptions
      (mainWidgetInElementById "app" (appWidget "ws://localhost:3004/api" clientId))
      (serveJsaddleJs (staticApp staticSettings))

  -- Run in a background thread so main returns immediately,
  -- allowing ghciwatch to process reloads while the server runs
  tid <- forkIO $ run port jsaddleApplication

  -- Store the thread ID using foreign-store so it survives GHCi reloads
  writeStore (Store serverStoreIndex) tid
  putStrLn "Server started in background (ghciwatch dev mode)"

#else

devMain :: IO ()
devMain = pure ()

#endif
