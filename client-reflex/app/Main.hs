{-# LANGUAGE CPP #-}

module ClientMain where

#if !defined(ghcjs_HOST_OS) && !defined(javascript_HOST_ARCH)
import Frontend.Devel (devMain)
#endif

#if defined(ghcjs_HOST_OS) || defined(javascript_HOST_ARCH)
import Language.Javascript.JSaddle (eval, valToText, liftJSM)

import Reflex.Dom.Core (mainWidgetInElementById)

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
#else
  devMain
  -- Clean exit for now, as devMain forks a thread.
  -- If we wanted this to be a standalone runner, we'd need to wait.
  -- But for ghciwatch, returning is correct.
  pure ()
#endif
