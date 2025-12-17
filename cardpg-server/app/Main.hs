{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE RecordWildCards #-}

module Main where

import Control.Concurrent (newMVar)
import Data.Aeson (eitherDecodeFileStrict)
import Data.Map qualified as Map
import Data.Maybe (fromMaybe)
import Data.Pool (createPool)
import Data.Text qualified as T
import Data.Text.IO qualified as T
import Data.Text.Encoding (encodeUtf8)
import Database.PostgreSQL.Simple (close, connectPostgreSQL)
import Network.WebSockets qualified as WS
import System.Environment (lookupEnv)
import System.IO (hSetBuffering, stdout, BufferMode(..))
import System.Random (newStdGen)

import CardPG.Core.Card (CoreCardT(..), CoreCard, ConsequenceCardT(..), ConsequenceCard)
import CardPG.Core.NonEmptyText (getRawText)
import CardPG.Core.State (GameEnv(..))
import CardPG.Server.Connection (application)
import CardPG.Server.DB (initDB, loadGame, saveGame)
import CardPG.Server.Scenario (loadScenario)
import CardPG.Server.Types (CardLibrary(..), ServerState(..), newServerState, GameState(..))

main :: IO ()
main = do
    hSetBuffering stdout NoBuffering
    
    -- DB Connection
    dbHost <- fromMaybe "localhost" <$> lookupEnv "CARDPG_DB_HOST"
    dbUser <- fromMaybe "cardpg" <$> lookupEnv "CARDPG_DB_USER"
    dbPass <- fromMaybe "cardpg" <$> lookupEnv "CARDPG_DB_PASS"
    dbName <- fromMaybe "cardpg" <$> lookupEnv "CARDPG_DB_NAME"
    
    let connStr = "host=" <> dbHost <> " user=" <> dbUser <> " password=" <> dbPass <> " dbname=" <> dbName
    pool <- createPool (connectPostgreSQL (encodeUtf8 $ T.pack connStr)) close 1 10 10

    initDB pool

    cardsFileEnv <- lookupEnv "CARDPG_CARDS_FILE"
    let cardsFile = fromMaybe "vtt-react/src/data/generated_cards.json" cardsFileEnv

    scenarioFileEnv <- lookupEnv "CARDPG_SCENARIO_FILE"
    let scenarioFile = fromMaybe "data/scenarios/starter.yaml" scenarioFileEnv

    -- Load Cards from Disk
    T.putStrLn $ "Loading card library from " <> T.pack cardsFile <> "..."
    cardLibraryResult <- eitherDecodeFileStrict cardsFile
    
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
            T.putStrLn $ "No persisted game found. Loading starter scenario from " <> T.pack scenarioFile <> "..."
            (initialGs, rng) <- loadScenario scenarioFile
            
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
    
    portStr <- lookupEnv "PORT"
    let port = fromMaybe 8080 (fmap read portStr)

    T.putStrLn $ "Starting CardPG Server on port " <> T.pack (show port) <> "..."
    WS.runServer "127.0.0.1" port $ application state
