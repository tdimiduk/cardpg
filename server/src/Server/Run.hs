{-# LANGUAGE OverloadedStrings #-}

module Server.Run where

import Control.Concurrent (newMVar)
import Data.Text qualified as T
import Data.Text.IO qualified as T
import Network.WebSockets qualified as WS
import System.IO (BufferMode (..), hSetBuffering, stdout)

import Server.Config (Config (..), loadConfig)
import Server.DB (initDB, initInMemoryDB, withGargoyleDB)
import Server.Loader (loadLibrary)
import Server.ReflexConnection (application)
import Server.Session (initGame)
import Server.Types (ServerState (..), newServerState)

-- | Run the server. This function blocks indefinitely.
runServer :: IO ()
runServer = do
  hSetBuffering stdout NoBuffering

  config <- loadConfig

  let startWithBackend backend = do
        -- Load Cards from Disk
        T.putStrLn $ "Loading card library from " <> T.pack config.cardsDir <> "..."
        lib <- loadLibrary config.cardsDir

        -- Initialize Game Session
        (gameGs, gameRng) <- initGame backend config lib False

        state <- newMVar (newServerState backend gameGs gameRng config){library = lib}

        T.putStrLn $ "Starting CardPG Server on port " <> T.pack (show config.serverPort) <> "..."
        WS.runServer "127.0.0.1" config.serverPort $ application state

  if
    | config.useInMemoryDB -> do
        T.putStrLn "Starting in IN-MEMORY mode (ephemeral)..."
        backend <- initInMemoryDB
        startWithBackend backend
    | config.useGargoyle -> do
        T.putStrLn "Starting in GARGOYLE mode (managed postgres)..."
        withGargoyleDB "db" startWithBackend
    | otherwise -> do
        T.putStrLn "Starting in POSTGRES mode..."
        backend <- initDB config.dbConfig
        startWithBackend backend
