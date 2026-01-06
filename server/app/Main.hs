{-# LANGUAGE OverloadedStrings #-}

module Main where

import Control.Concurrent (newMVar)
import Data.Aeson (eitherDecodeFileStrict)
import Data.Map qualified as Map
import Data.Maybe (fromMaybe)
import Data.Pool (defaultPoolConfig, newPool)
import Data.Text qualified as T
import Data.Text.Encoding (encodeUtf8)
import Data.Text.IO qualified as T
import Database.PostgreSQL.Simple (close, connectPostgreSQL)
import Network.WebSockets qualified as WS

import System.IO (BufferMode (..), hSetBuffering, stdout)
import System.Random (newStdGen)

import Core.Card (ConsequenceCard (..), CoreCard (..))
import Core.NonEmptyText (getRawText)
import Core.State (GameEnv (..))
import Server.Config (Config (..), DBConfig (..), loadConfig)
import Server.Connection (application)
import Server.DB (initDB, initInMemoryDB, loadGame, saveGame)
import Server.Loader (loadLibrary)
import Server.Scenario (loadScenario)
import Server.Session (initGame)
import Server.Types (CardLibrary (..), GameState (..), ServerState (..), newServerState)

main :: IO ()
main = do
  hSetBuffering stdout NoBuffering
  config <- loadConfig

  backend <-
    if config.useInMemoryDB
      then do
        T.putStrLn "Starting in IN-MEMORY mode (ephemeral)..."
        initInMemoryDB
      else do
        T.putStrLn "Starting in POSTGRES mode..."
        initDB config.dbConfig

  -- Load Cards from Disk
  T.putStrLn $ "Loading card library from " <> T.pack config.cardsDir <> "..."
  lib <- loadLibrary config.cardsDir

  -- Initialize Game Session
  (gameGs, gameRng) <- initGame backend config lib False

  state <- newMVar (newServerState backend gameGs gameRng config){library = lib}

  T.putStrLn $ "Starting CardPG Server on port " <> T.pack (show config.serverPort) <> "..."
  WS.runServer "127.0.0.1" config.serverPort $ application state
