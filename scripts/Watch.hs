#!/usr/bin/env runghc

module Main where

import System.Directory (getCurrentDirectory)
import System.Environment (getArgs, setEnv)
import System.FilePath ((</>))
import System.IO.Error (catchIOError)
import System.Process (callProcess, readProcess)

main :: IO ()
main = do
  args <- getArgs
  case args of
    ["client"] -> do
      putStrLn "Starting ghciwatch for client..."
      putStrLn "Ensuring gen-css is built..."
      callProcess "cabal" ["build", "client-reflex:gen-css"]
      binPath <-
        catchIOError
          (init <$> readProcess "cabal" ["list-bin", "client-reflex:gen-css"] "")
          (\_ -> return "cabal run client-reflex:gen-css")
      putStrLn $ "Using gen-css binary at: " ++ binPath
      runWatch (Client binPath)
    ["server"] -> do
      putStrLn "Starting ghciwatch for server..."
      root <- getCurrentDirectory
      setEnv "CARDPG_CARDS_DIR" (root </> "data/cards")
      setEnv "CARDPG_SCENARIO_FILE" (root </> "data/scenarios/starter.yaml")
      runWatch Server
    _ -> putStrLn "Usage: runghc Watch.hs {client|server}"

data Mode = Client FilePath | Server

runWatch :: Mode -> IO ()
runWatch mode = callProcess "ghciwatch" (getGhciWatchArgs mode)

getGhciWatchArgs :: Mode -> [String]
getGhciWatchArgs mode =
  case mode of
    Client genCssBin ->
      let cmd = "scripts/recompile-assets " ++ genCssBin
       in mkArgs "client-reflex" "lib:client-reflex" "Frontend.Devel.devMain" ["design/rules"]
            ++ [ "--before-startup-shell"
               , cmd
               , "--before-reload-shell"
               , cmd
               , "--before-restart-shell"
               , cmd
               ]
    Server -> mkArgs "server" "exe:server-devel" "Main.main" ["server/app"]
  where
    mkArgs folder component mainModule extraWatches =
      [ "--command"
      , "cabal repl " <> component
      , "--test-ghci"
      , mainModule
      , "--restart-glob"
      , folder <> "/" <> folder <> ".cabal"
      , "--watch"
      , folder <> "/src"
      ]
        ++ concatMap (\p -> ["--watch", p]) extraWatches
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
