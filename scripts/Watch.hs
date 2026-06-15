module Main where

import Control.Concurrent (forkIO, threadDelay)
import qualified Control.Exception as E
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
import System.Exit (ExitCode (..))
import System.FilePath ((</>))
import System.IO.Error (catchIOError)
import System.Process
  ( callProcess
  , createProcess
  , getProcessExitCode
  , proc
  , rawSystem
  , readProcess
  , terminateProcess
  , waitForProcess
  )

clientWatchedPaths :: [FilePath]
clientWatchedPaths =
  [ "client/src"
  , "core/src"
  , "api/src"
  , "client/client.cabal"
  , "core/core.cabal"
  , "api/api.cabal"
  , "reflex-atomic-css/src"
  , "reflex-atomic-css/reflex-atomic-css.cabal"
  , "design/rules"
  ]

serverWatchedPaths :: [FilePath]
serverWatchedPaths =
  [ "server/src"
  , "server/app"
  , "core/src"
  , "api/src"
  , "server/server.cabal"
  , "core/core.cabal"
  , "api/api.cabal"
  ]

runWithRetry :: IO ExitCode -> [FilePath] -> IO ()
runWithRetry action watched = do
  initialTime <- monitorPaths watched
  let loop lastTime = do
        result <- E.try action :: IO (Either E.IOException ExitCode)
        case result of
          Right ExitSuccess -> return ()
          Right (ExitFailure code)
            | code < 0 || code == 130 || code == 143 -> E.throwIO (ExitFailure code)
            | otherwise -> do
                putStrLn "\n========================================================================="
                putStrLn $ "ERROR: Process failed with exit code " ++ show code
                putStrLn "Waiting for file changes to retry..."
                putStrLn "=========================================================================\n"
                newTime <- waitForChange lastTime
                loop newTime
          Left err -> do
            putStrLn "\n========================================================================="
            putStrLn $ "ERROR: IO exception: " ++ show err
            putStrLn "Waiting for file changes to retry..."
            putStrLn "=========================================================================\n"
            newTime <- waitForChange lastTime
            loop newTime
      waitForChange lastTime = do
        threadDelay 2000000 -- Poll every 2 seconds
        newTime <- monitorPaths watched
        if newTime > lastTime
          then do
            putStrLn "File change detected! Retrying..."
            return newTime
          else waitForChange lastTime
  loop initialTime

watchCompiledServer :: [FilePath] -> IO ()
watchCompiledServer watched = do
  initialTime <- monitorPaths watched
  let loop lastTime = do
        putStrLn "Building server..."
        buildResult <-
          E.try (rawSystem "cabal" ["build", "exe:server"]) :: IO (Either E.IOException ExitCode)
        case buildResult of
          Right ExitSuccess -> runServer lastTime
          Right (ExitFailure code)
            | code < 0 || code == 130 || code == 143 -> E.throwIO (ExitFailure code)
            | otherwise -> do
                putStrLn "\n========================================================================="
                putStrLn $ "ERROR: Server build failed with exit code " ++ show code
                putStrLn "Waiting for file changes to rebuild..."
                putStrLn "=========================================================================\n"
                newTime <- waitForChange lastTime
                loop newTime
          Left err -> do
            putStrLn "\n========================================================================="
            putStrLn $ "ERROR: Build failed with IO exception: " ++ show err
            putStrLn "Waiting for file changes to rebuild..."
            putStrLn "=========================================================================\n"
            newTime <- waitForChange lastTime
            loop newTime

      runServer lastTime = do
        serverBinPath <-
          catchIOError
            (init <$> readProcess "cabal" ["list-bin", "exe:server"] "")
            (\_ -> return "")
        if null serverBinPath
          then do
            putStrLn "Could not find precompiled server binary, falling back to cabal run..."
            runFallbackServer lastTime
          else do
            putStrLn $ "Running server binary at: " ++ serverBinPath
            (_, _, _, ph) <- createProcess (proc serverBinPath [])
            monitorLoop ph lastTime

      runFallbackServer lastTime = do
        result <- E.try (rawSystem "cabal" ["run", "exe:server"]) :: IO (Either E.IOException ExitCode)
        case result of
          Right ExitSuccess -> return ()
          Right (ExitFailure code)
            | code < 0 || code == 130 || code == 143 -> E.throwIO (ExitFailure code)
            | otherwise -> do
                putStrLn "\n========================================================================="
                putStrLn $ "ERROR: cabal run failed with exit code " ++ show code
                putStrLn "Waiting for file changes to retry..."
                putStrLn "=========================================================================\n"
                newTime <- waitForChange lastTime
                loop newTime
          Left err -> do
            putStrLn "\n========================================================================="
            putStrLn $ "ERROR: cabal run failed with IO exception: " ++ show err
            putStrLn "Waiting for file changes to retry..."
            putStrLn "=========================================================================\n"
            newTime <- waitForChange lastTime
            loop newTime

      monitorLoop ph lastTime = do
        threadDelay 2000000 -- Poll every 2 seconds
        mExitCode <- getProcessExitCode ph
        case mExitCode of
          Just exitCode -> do
            putStrLn $ "Server process exited with code: " ++ show exitCode
            newTime <- monitorPaths watched
            loop newTime
          Nothing -> do
            newTime <- monitorPaths watched
            if newTime > lastTime
              then do
                putStrLn "\n========================================================================="
                putStrLn "WARNING: Backend/shared source files changed in compiled server dev mode!"
                putStrLn "Terminating server to rebuild..."
                putStrLn "=========================================================================\n"
                terminateProcess ph
                _ <- waitForProcess ph
                loop newTime
              else monitorLoop ph lastTime

      waitForChange lastTime = do
        threadDelay 2000000
        newTime <- monitorPaths watched
        if newTime > lastTime
          then do
            putStrLn "File change detected! Retrying..."
            return newTime
          else waitForChange lastTime

  loop initialTime

watchClient :: IO ()
watchClient = runWithRetry action clientWatchedPaths
  where
    action = do
      putStrLn "Starting ghciwatch for client..."
      putStrLn "Ensuring gen-css is built..."
      buildExit <- rawSystem "cabal" ["build", "reflex-atomic-css:gen-css"]
      case buildExit of
        ExitSuccess -> do
          binPath <-
            catchIOError
              (init <$> readProcess "cabal" ["list-bin", "reflex-atomic-css:gen-css"] "")
              (\_ -> return "cabal run reflex-atomic-css:gen-css")
          putStrLn $ "Using gen-css binary at: " ++ binPath
          runWatch (Client binPath)
        ExitFailure code -> return (ExitFailure code)

watchGhciwatchServer :: IO ()
watchGhciwatchServer = runWithRetry (runWatch Server) serverWatchedPaths

main :: IO ()
main = do
  args <- getArgs
  case args of
    ["client"] -> watchClient
    ["server"] -> do
      root <- getCurrentDirectory
      setEnv "CARDPG_CARDS_DIR" (root </> "data/cards")
      setEnv "CARDPG_SCENARIO_FILE" (root </> "data/scenarios/starter.yaml")
      useCompiled <- lookupEnv "CARDPG_USE_COMPILED_SERVER"
      if useCompiled == Just "1"
        then watchCompiledServer serverWatchedPaths
        else watchGhciwatchServer
    _ -> putStrLn "Usage: runghc Watch.hs {client|server}"

data Mode = Client FilePath | Server

runWatch :: Mode -> IO ExitCode
runWatch mode = rawSystem "ghciwatch" (getGhciWatchArgs mode)

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
