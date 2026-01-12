#!/usr/bin/env runghc

module Main where

import System.Environment (getArgs)
import System.Process (callProcess)

main :: IO ()
main = do
  args <- getArgs
  case args of
    ["client"] -> runWatch Client
    ["server"] -> runWatch Server
    _ -> putStrLn "Usage: runghc Watch.hs {client|server}"

data Mode = Client | Server

runWatch :: Mode -> IO ()
runWatch mode = callProcess "ghciwatch" (getGhciWatchArgs mode)

getGhciWatchArgs :: Mode -> [String]
getGhciWatchArgs mode =
  case mode of
    Client -> mkArgs "client-reflex" "lib:client-reflex" "Frontend.Devel.devMain"
    Server -> mkArgs "server" "exe:server-devel" "Main.main"
  where
    mkArgs folder component mainModule =
      [ "--command"
      , "cabal repl " <> component
      , "--test-ghci"
      , mainModule
      , "--restart-glob"
      , folder <> "/" <> folder <> ".cabal"
      , "--watch"
      , folder <> "/src"
      , "--watch"
      , folder <> "/app"
      ]
        ++ commonArgs

    commonArgs =
      [ "--restart-glob"
      , "core/core.cabal"
      , "--restart-glob"
      , "api/api.cabal"
      , "--watch"
      , "core/src"
      , "--watch"
      , "api/src"
      ]
