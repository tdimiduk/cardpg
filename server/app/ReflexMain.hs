{-# LANGUAGE OverloadedStrings #-}

module Main where

import Control.Concurrent (newMVar)
import Data.Text qualified as T
import Data.Text.IO qualified as T
import Network.WebSockets qualified as WS

import System.IO (BufferMode (..), hSetBuffering, stdout)

import Server.Config (Config (..), loadConfig)
import Server.DB (initDB, initInMemoryDB)
import Server.Loader (loadLibrary)
import Server.ReflexConnection (application)
import Server.Session (initGame)
import Server.Types (ServerState (..), newServerState)

main :: IO ()
main = do
  hSetBuffering stdout NoBuffering
  config <- loadConfig

  -- Override port for reflex server
  let config' = config{serverPort = 3004}

  backend <-
    if config'.useInMemoryDB
      then do
        T.putStrLn "Starting in IN-MEMORY mode (ephemeral)..."
        initInMemoryDB
      else do
        T.putStrLn "Starting in POSTGRES mode..."
        initDB config'.dbConfig

  T.putStrLn $ "Loading card library from " <> T.pack config'.cardsDir <> "..."
  lib <- loadLibrary config'.cardsDir

  (gameGs, gameRng) <- initGame backend config' lib False

  state <- newMVar (newServerState backend gameGs gameRng config'){library = lib}

  T.putStrLn $ "Starting CardPG Reflex Server on port " <> T.pack (show config'.serverPort) <> "..."
  WS.runServer "127.0.0.1" config'.serverPort $ application state
