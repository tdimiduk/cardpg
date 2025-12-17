{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE RecordWildCards #-}

module Main where

import Control.Concurrent (newMVar)
import Data.Aeson (eitherDecodeFileStrict)
import Data.Map qualified as Map
import Data.Maybe (fromMaybe)
import Data.Pool (newPool, defaultPoolConfig)
import Data.Text qualified as T
import Data.Text.IO qualified as T
import Data.Text.Encoding (encodeUtf8)
import Database.PostgreSQL.Simple (close, connectPostgreSQL)
import Network.WebSockets qualified as WS

import System.IO (hSetBuffering, stdout, BufferMode(..))
import System.Random (newStdGen)

import CardPG.Core.Card (CoreCardT(..), CoreCard, ConsequenceCardT(..), ConsequenceCard)
import CardPG.Core.NonEmptyText (getRawText)
import CardPG.Core.State (GameEnv(..))
import CardPG.Server.Connection (application)
import CardPG.Server.Config (Config(..), DBConfig(..), loadConfig)
import CardPG.Server.DB (initDB, loadGame, saveGame)
import CardPG.Server.Scenario (loadScenario)
import CardPG.Server.Types (CardLibrary(..), ServerState(..), newServerState, GameState(..))



main :: IO ()
main = do
    hSetBuffering stdout NoBuffering
    config <- loadConfig
    
    -- DB Connection
    let db = config.dbConfig
    let connStr = "host=" <> db.dbHost <> " user=" <> db.dbUser <> " password=" <> db.dbPass <> " dbname=" <> db.dbName
    pool <- newPool $ defaultPoolConfig (connectPostgreSQL (encodeUtf8 $ T.pack connStr)) close 10 10

    initDB pool

    -- Load Cards from Disk
    T.putStrLn $ "Loading card library from " <> T.pack config.cardsFile <> "..."
    cardLibraryResult <- eitherDecodeFileStrict config.cardsFile
    
    lib <- case cardLibraryResult of
        Left err -> do
             T.putStrLn $ "WARNING: Failed to load card library: " <> T.pack err
             return (CardLibrary [] [] [])
        Right l -> return l

    -- Try to load default game
    let defaultGameId = "default-game"
    maybeLoaded <- loadGame pool defaultGameId
    
    (finalGs, finalRng) <- case maybeLoaded of
        Just loadedGs -> do
            T.putStrLn "Loaded persisted game state."
            -- Since we don't save RNG, we must generate a new one on restart.
            -- This is acceptable for simple restarts, though deterministic replay would require saving it.
            rng <- newStdGen
            return (loadedGs, rng)
        Nothing -> do
            T.putStrLn $ "No persisted game found. Loading starter scenario from " <> T.pack config.scenarioFile <> "..."
            (initialGs, rng) <- loadScenario config.scenarioFile
            
            -- Hydrate library into env
            let env = initialGs.env
            let statusMap = Map.fromList [(getRawText c.name, c) | c <- lib.statuses]
            let consequenceMap = Map.fromList [(getRawText c.name, c) | c <- lib.consequences]
            let newEnv = env { statusCardTemplates = statusMap, consequenceCardTemplates = consequenceMap }
            let newGs = initialGs { env = newEnv }
            
            -- Persist initial state
            saveGame pool defaultGameId newGs
            return (newGs, rng)

    state <- newMVar (newServerState pool finalGs finalRng) { library = lib }

    T.putStrLn $ "Starting CardPG Server on port " <> T.pack (show config.serverPort) <> "..."
    WS.runServer "127.0.0.1" config.serverPort $ application state
