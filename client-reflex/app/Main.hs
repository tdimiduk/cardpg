{-# LANGUAGE CPP #-}
{-# LANGUAGE OverloadedStrings #-}

module ClientMain where

#if !defined(ghcjs_HOST_OS) && !defined(javascript_HOST_ARCH)
import Frontend.Devel (devMain)
#endif

#if defined(ghcjs_HOST_OS) || defined(javascript_HOST_ARCH)
import Language.Javascript.JSaddle (eval, valToText, liftJSM)

import Reflex.Dom.Core (mainWidgetInElementById, MonadWidget, divClass, text, button, webSocket, def, _webSocketConfig_send, traceEvent, performEvent_, _webSocket_open, _webSocket_error, dynText, holdDyn, _webSocket_recv)
import qualified Data.Text as T
import qualified Data.Text.Encoding as T
import qualified Data.ByteString.Lazy as BL
import Data.Text.Encoding (decodeUtf8)

import Frontend.App (appWidget)
#endif

main :: IO ()
main = do
#if defined(ghcjs_HOST_OS) || defined(javascript_HOST_ARCH)
  -- Hardcoding something to avoid the UUID dependency
  let clientId = read "00000000-0000-0000-0000-000000000001"

  mainWidgetInElementById "app" $ do
    protocol <- liftJSM $ valToText =<< eval "window.location.protocol"
    host <- liftJSM $ valToText =<< eval "window.location.host"
    let wsProtocol = if protocol == "https:" then "wss:" else "ws:"
        wsUrl = wsProtocol <> "//" <> host <> "/api"
    appWidget wsUrl clientId
    -- Debug Widget
    -- debugWsWidget wsUrl
#else
  devMain
  -- Clean exit for now, as devMain forks a thread.
  -- If we wanted this to be a standalone runner, we'd need to wait.
  -- But for ghciwatch, returning is correct.
  pure ()
#endif

debugWsWidget :: (MonadWidget t m) => T.Text -> m ()
debugWsWidget wsUrl = do
  divClass "fixed bottom-0 right-0 bg-red-900 text-white p-2 z-50 pointer-events-auto" $ do
    text "Debug WS: "
    btn <- button "Send Ping"
    let sendEvt = ["ping" :: T.Text] <$ btn
    ws <- webSocket (wsUrl <> "/debug") (def{_webSocketConfig_send = sendEvt})

    performEvent_ $ return () <$ traceEvent "Debug WS Open" (_webSocket_open ws)
    performEvent_ $ return () <$ traceEvent "Debug WS Error" (_webSocket_error ws)

    dynText =<< holdDyn "Waiting..." (fmap (const "Connected") $ _webSocket_open ws)

    let msg = _webSocket_recv ws
    text " Last: "
    dynText =<< holdDyn "" (fmap (T.decodeUtf8) msg)
