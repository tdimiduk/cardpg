{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE RecordWildCards #-}
{-# LANGUAGE DeriveGeneric #-}

module Main where

import Control.Concurrent (MVar, newMVar, modifyMVar_, modifyMVar, readMVar)
import Control.Exception (finally)
import Control.Monad (forM_, forever)
import Data.Aeson (FromJSON(..), ToJSON(..), Value, encode, decode, genericToJSON, genericParseJSON, defaultOptions, Options(..), SumEncoding(..), eitherDecodeFileStrict)
import qualified Data.ByteString.Lazy as B
import Data.Map (Map)
import qualified Data.Map as Map
import Data.Text (Text)
import qualified Data.Text as T
import qualified Data.Text.IO as T
import Data.Text.Encoding (encodeUtf8)
import System.Environment (lookupEnv)
import System.IO (hSetBuffering, stdout, BufferMode(..))
import Data.Maybe (fromMaybe)
import qualified Network.WebSockets as WST
import Data.UUID (UUID, toText, nil)
import qualified Data.UUID.V4 as UUID
import GHC.Generics (Generic)
import Network.WebSockets (Connection, ServerApp, acceptRequest, receiveData, sendTextData, withPingThread)
import qualified Network.WebSockets as WS

import System.Random (newStdGen)

import CardPG.Core.Card (ActorDefinition, CoreCard, CoreCardT(..), ItemCard, NatureCard, TalentCard, ActorDefinitionDSL, ConsequenceCardT(..))
import CardPG.Core.Hardcoded (fatigueCard)
import CardPG.Core.State (GameEnv(..), GameEvent(..), ActorState)
import CardPG.Core.Primitives (TargetId(..))
import qualified CardPG.Core.Logic as Logic
import CardPG.Core.NonEmptyText (getRawText)
import CardPG.Server.Game (GameState(..), runActorAction, processCommand, concludeRound, revealPlannedActions)
import CardPG.Server.Scenario (loadScenario)
import CardPG.Server.Types (Client(..), ClientMessage(..), ServerMessage(..), ActorGameEvent(..), ServerState(..), newServerState, CardLibrary(..), Command(..), StateUpdate(..))
import CardPG.Server.DB (cardpgDb, GameT(..), GameId, Game, initDB, saveGame, loadGame)

import Data.Pool
import Data.Time (getCurrentTime)
import Database.PostgreSQL.Simple (close, connectPostgreSQL)


numClients :: ServerState -> Int
numClients = Map.size . (.clients)

clientExists :: Client -> ServerState -> Bool
clientExists client state = Map.member (client.clientId) (state.clients)

addClient :: Client -> ServerState -> ServerState
addClient client state = state { clients = Map.insert (client.clientId) client (state.clients) }

removeClient :: Client -> ServerState -> ServerState
removeClient client state = state { clients = Map.delete (client.clientId) (state.clients) }



broadcast :: ServerMessage -> ServerState -> IO ()
broadcast msg state = do
    let msgBytes = encode msg
    forM_ (Map.elems (state.clients)) $ \client ->
        sendTextData (client.clientConn) msgBytes

    forM_ (Map.elems (state.clients)) $ \client ->
        sendTextData (client.clientConn) msgBytes

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
    
    finalGs <- case maybeLoaded of
        Just loadedGs -> do
            T.putStrLn "Loaded persisted game state."
            return loadedGs
        Nothing -> do
            T.putStrLn $ "No persisted game found. Loading starter scenario from " <> T.pack scenarioFile <> "..."
            initialGs <- loadScenario scenarioFile
            
            -- Hydrate library into env
            let env = initialGs.env
            let statusMap = Map.fromList [(getRawText c.name, c) | c <- lib.statuses]
            let consequenceMap = Map.fromList [(getRawText c.name, c) | c <- lib.consequences]
            let newEnv = env { statusCardTemplates = statusMap, consequenceCardTemplates = consequenceMap }
            let newGs = initialGs { env = newEnv }
            
            -- Persist initial state
            saveGame pool defaultGameId newGs
            return newGs

    state <- newMVar (newServerState pool finalGs) { library = lib }
    
    portStr <- lookupEnv "PORT"
    let port = fromMaybe 8080 (fmap read portStr)

    T.putStrLn $ "Starting CardPG Server on port " <> T.pack (show port) <> "..."
    WS.runServer "127.0.0.1" port $ application state

application :: MVar ServerState -> ServerApp
application state pending = do
    conn <- acceptRequest pending
    -- Keep connection alive with pings every 30 seconds
    withPingThread conn 30 (return ()) $ do
        -- Generate a temporary ID until they join properly
        uuid <- UUID.nextRandom
        let initialClient = Client uuid "Anonymous" conn
        
        flip finally (disconnect initialClient state) $ do
            talk initialClient state

talk :: Client -> MVar ServerState -> IO ()
talk client state = forever $ do
    msgBytes <- receiveData (client.clientConn)
    case decode msgBytes of
        Nothing -> do
            T.putStrLn "Received invalid JSON"
            sendTextData (client.clientConn) (encode $ ErrorMessage "Invalid JSON")
        Just (Join name maybeId) -> do
            -- Determine Client ID (Recover or Generate)
            (clientId, isReconnect) <- case maybeId of
                Just existingId -> do
                    exists <- readMVar state >>= \s -> return $ Map.member existingId (s.clients)
                    if exists
                        then return (existingId, True)
                        else return (existingId, False) -- User claims ID, but not in memory (maybe restarted? treat as new for now)
                Nothing -> do
                    newId <- UUID.nextRandom
                    return (newId, False)

            let newClient = client { clientName = name, clientId = clientId }
            
            T.putStrLn $ "Client joining: " <> name <> " (" <> T.pack (show clientId) <> ")" 
                       <> (if isReconnect then " [RECONNECT]" else "")
            
            -- Prepare broadcast
            -- Prepare broadcast
            (currentClients, currentGs, messages, pool) <- modifyMVar state $ \s -> do
                let s' = addClient newClient s -- Overwrites existing entry if reconnecting (updating socket)
                let initialUpdates = map (\(tid, ast) -> StateUpdate tid ast) $ Map.toList (s'.gameState.actors)
                
                let welcomeMsg = Welcome clientId (map (.clientName) $ Map.elems s'.clients) initialUpdates (s'.gameState.phase)
                
                -- If it's a new client (or distinct ID), notify others. 
                -- If reconnect (same ID), effectively just updating the socket, maybe notify "Reconnected"? 
                -- For now, simplest is just treat Join as Join.
                return (s', (s'.clients, s'.gameState, [welcomeMsg], s'.dbPool))
            
            -- Send Welcome
            forM_ messages $ \msg -> sendTextData (newClient.clientConn) (encode msg)
            
            -- Notify others
            let broadcastState = ServerState (Map.delete clientId currentClients) (CardLibrary [] [] []) currentGs pool
            broadcast (ClientJoined name clientId) broadcastState
            
            -- Continue loop with updated client info
            talkLoop newClient state

talkLoop :: Client -> MVar ServerState -> IO ()
talkLoop client state = do
    msgBytes <- receiveData (client.clientConn)
    case decode msgBytes of
        Nothing -> do
            T.putStrLn "Received invalid JSON"
            sendTextData (client.clientConn) (encode $ ErrorMessage "Invalid JSON")
            talkLoop client state
        Just (Join name _) -> do
             -- Allow renaming?
            let newClient = client { clientName = name }
            modifyMVar_ state $ \s -> return $ addClient newClient s
            T.putStrLn $ "Client renamed: " <> name
            talkLoop newClient state

        Just (GameCommand cmd) -> do
            T.putStrLn $ "Received command: " <> T.pack (show cmd) <> " from " <> client.clientName
            
            -- Run action against authoritative state
            -- Run action against authoritative state
            (newGame, pool, updates, actions, clientsMap, newPhase, oldPhase) <- modifyMVar state $ \s -> do
                let game = s.gameState
                let (newGame, updates, actions) = processCommand cmd game
                
                return (s { gameState = newGame }, (newGame, s.dbPool, updates, actions, s.clients, newGame.phase, game.phase))

            -- Persist State
            saveGame pool "default-game" newGame

            -- Broadcast results
            let tempState = ServerState clientsMap (CardLibrary [] [] []) (error "GameState unused in broadcast") pool
            
            let messages =
                  (if null actions then [] else [BroadcastMessage (client.clientId) actions]) ++
                  (if not (null updates) || newPhase /= oldPhase 
                      then [GameStateUpdate updates (Just newPhase)]
                      else [])

            if not (null messages)
               then broadcast (MultiMessage messages) tempState
               else return ()
            
            talkLoop client state

disconnect :: Client -> MVar ServerState -> IO ()
disconnect client state = do
    T.putStrLn $ "Client disconnected: " <> client.clientName
    s <- modifyMVar state $ \s -> do
        let s' = removeClient client s
        return (s', s')
    broadcast (ClientLeft (client.clientId)) s
