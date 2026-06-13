#!/usr/bin/env runghc

module Main where

import Control.Concurrent (forkIO, threadDelay)
import Control.Monad (forM)
import Data.Maybe (catMaybes)
import Data.Time.Clock (UTCTime)
import System.Directory
  ( doesDirectoryExist
  , getCurrentDirectory
  , getModificationTime
  , listDirectory
  )
import System.Environment (getArgs, lookupEnv, setEnv)
import System.FilePath ((</>))
import System.IO.Error (catchIOError)
import System.Process
  ( callProcess
  , createProcess
  , proc
  , readProcess
  , terminateProcess
  , waitForProcess
  )

main :: IO ()
main = do
  args <- getArgs
  case args of
    ["client"] -> do
      putStrLn "Starting ghciwatch for client..."
      putStrLn "Ensuring gen-css is built..."
      callProcess "cabal" ["build", "reflex-atomic-css:gen-css"]
      binPath <-
        catchIOError
          (init <$> readProcess "cabal" ["list-bin", "reflex-atomic-css:gen-css"] "")
          (\_ -> return "cabal run reflex-atomic-css:gen-css")
      putStrLn $ "Using gen-css binary at: " ++ binPath
      runWatch (Client binPath)
    ["server"] -> do
      root <- getCurrentDirectory
      setEnv "CARDPG_CARDS_DIR" (root </> "data/cards")
      setEnv "CARDPG_SCENARIO_FILE" (root </> "data/scenarios/starter.yaml")
      useCompiled <- lookupEnv "CARDPG_USE_COMPILED_SERVER"
      if useCompiled == Just "1"
        then do
          putStrLn "Running precompiled server..."
          serverBinPath <-
            catchIOError
              (init <$> readProcess "cabal" ["list-bin", "exe:server"] "")
              (\_ -> return "")
          if null serverBinPath
            then do
              putStrLn "Could not find precompiled server binary, falling back to cabal run..."
              callProcess "cabal" ["run", "exe:server"]
            else do
              putStrLn $ "Running server binary at: " ++ serverBinPath
              let watchedPaths =
                    [ "server/src"
                    , "core/src"
                    , "api/src"
                    , "server/server.cabal"
                    , "core/core.cabal"
                    , "api/api.cabal"
                    ]
              initialTime <- monitorPaths watchedPaths
              (_, _, _, ph) <- createProcess (proc serverBinPath [])
              _ <- forkIO $ do
                let loop lastTime = do
                      threadDelay 2000000 -- Poll every 2 seconds
                      newTime <- monitorPaths watchedPaths
                      if newTime > lastTime
                        then do
                          putStrLn "\n========================================================================="
                          putStrLn "WARNING: Backend/shared source files changed in compiled server dev mode!"
                          putStrLn "Terminating server to prevent stale state..."
                          putStrLn "=========================================================================\n"
                          terminateProcess ph
                        else loop lastTime
                loop initialTime
              _ <- waitForProcess ph
              return ()
        else do
          putStrLn "Starting ghciwatch for server..."
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
       in mkArgs "client" "lib:client" "Frontend.Devel.devMain" ["design/rules"]
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
      , "--restart-glob"
      , "reflex-atomic-css/reflex-atomic-css.cabal"
      , "--watch"
      , "core/src"
      , "--watch"
      , "api/src"
      , "--watch"
      , "reflex-atomic-css/src"
      ]

getRecursiveModificationTime :: FilePath -> IO (Maybe UTCTime)
getRecursiveModificationTime path = do
  isDir <- doesDirectoryExist path
  if isDir
    then do
      contents <- catchIOError (listDirectory path) (\_ -> return [])
      times <- forM contents $ \name -> getRecursiveModificationTime (path </> name)
      return $ safeMaximum (catMaybes times)
    else catchIOError (Just <$> getModificationTime path) (\_ -> return Nothing)
  where
    safeMaximum [] = Nothing
    safeMaximum xs = Just (maximum xs)

monitorPaths :: [FilePath] -> IO (Maybe UTCTime)
monitorPaths paths = do
  times <- mapM getRecursiveModificationTime paths
  return $ safeMaximum (catMaybes times)
  where
    safeMaximum [] = Nothing
    safeMaximum xs = Just (maximum xs)
