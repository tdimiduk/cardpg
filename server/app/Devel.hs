module Main where

import Server.Run (runServer)

-- | Development entry point. Simply runs the server.
-- Hot-reload is handled by ghciwatch restarting the GHCi session.
main :: IO ()
main = runServer
