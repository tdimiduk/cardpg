{-# LANGUAGE CPP #-}
{-# LANGUAGE OverloadedStrings #-}

module ClientMain where

#if !defined(ghcjs_HOST_OS) && !defined(javascript_HOST_ARCH)
import Frontend.Devel (devMain)
#endif

#if defined(ghcjs_HOST_OS) || defined(javascript_HOST_ARCH)
import Reflex.Dom.Core (mainWidgetInElementById)

import Frontend.App (appWidget)
#endif

main :: IO ()
main = do
#if defined(ghcjs_HOST_OS) || defined(javascript_HOST_ARCH)
  let wsUrl = "wss:" <> "//" <> "localhost:3004" <> "/api"
  -- Hardcoding something to avoid the UUID dependency
  let clientId = read "00000000-0000-0000-0000-000000000001"

  mainWidgetInElementById "app" (appWidget wsUrl clientId)
#else
  devMain
  -- Clean exit for now, as devMain forks a thread.
  -- If we wanted this to be a standalone runner, we'd need to wait.
  -- But for ghciwatch, returning is correct.
  pure ()
#endif
