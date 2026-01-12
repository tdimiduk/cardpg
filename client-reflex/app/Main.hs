module ClientMain where

import Control.Concurrent (threadDelay)
import Frontend.Devel (devMain)

main :: IO ()
main = do
  devMain
  -- Clean exit for now, as devMain forks a thread.
  -- If we wanted this to be a standalone runner, we'd need to wait.
  -- But for ghciwatch, returning is correct.
  pure ()
