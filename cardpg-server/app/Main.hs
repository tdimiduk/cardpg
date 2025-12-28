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

import CardPG.Core.Card (ConsequenceCard (..), CoreCard (..))
import CardPG.Core.NonEmptyText (getRawText)
import CardPG.Core.State (GameEnv (..))
import CardPG.Server.Config (Config (..), DBConfig (..), loadConfig)
import CardPG.Server.Connection (application)
import CardPG.Server.DB (initDB, initInMemoryDB, loadGame, saveGame)
import CardPG.Server.Loader (loadLibrary)
import CardPG.Server.Scenario (loadScenario)
import CardPG.Server.Session (initGame)
import CardPG.Server.Types (CardLibrary (..), GameState (..), ServerState (..), newServerState)

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
