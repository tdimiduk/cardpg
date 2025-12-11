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
import System.Environment (lookupEnv)
import Data.Maybe (fromMaybe)
import qualified Network.WebSockets as WST
import Data.UUID (UUID)
import qualified Data.UUID.V4 as UUID
import GHC.Generics (Generic)
import Network.WebSockets (Connection, ServerApp, acceptRequest, receiveData, sendTextData, withPingThread)
import qualified Network.WebSockets as WS

import CardPG.Server.Types (Client(..), ClientMessage(..), ServerMessage(..), BroadcastAction(..), ServerState(..), newServerState, CardLibrary(..))


numClients :: ServerState -> Int
numClients = Map.size . (.clients)

clientExists :: Client -> ServerState -> Bool
clientExists client state = Map.member (client.clientId) (state.clients)

addClient :: Client -> ServerState -> ServerState
addClient client state = state { clients = Map.insert (client.clientId) client (state.clients) }

removeClient :: Client -> ServerState -> ServerState
removeClient client state = state { clients = Map.delete (client.clientId) (state.clients) }

addAction :: BroadcastAction -> ServerState -> ServerState
addAction action state = state { actionLog = state.actionLog ++ [action] }

broadcast :: ServerMessage -> ServerState -> IO ()
broadcast msg state = do
    let msgBytes = encode msg
    forM_ (Map.elems (state.clients)) $ \client ->
        sendTextData (client.clientConn) msgBytes

main :: IO ()
main = do
    let cardsFile = "vtt-react/src/data/generated_cards.json"
    T.putStrLn $ "Loading card library from " <> T.pack cardsFile <> "..."
    cardLibraryResult <- eitherDecodeFileStrict cardsFile
    
    initialState <- case cardLibraryResult of
        Left err -> do
             T.putStrLn $ "WARNING: Failed to load card library: " <> T.pack err
             return newServerState
        Right lib -> do
             T.putStrLn $ "Card Library Loaded: " 
                <> T.pack (show (length (lib.actors))) <> " actors, " 
                <> T.pack (show (length (lib.statuses))) <> " statuses, "
                <> T.pack (show (length (lib.consequences))) <> " consequences."
             return $ newServerState { library = lib }

    state <- newMVar initialState
    
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
        Just (Join name) -> do
            let newClient = client { clientName = name }
            
            -- Update state with new client
            (currentClients, historyLog) <- modifyMVar state $ \s -> do
                let s' = addClient newClient s
                return (s', (s'.clients, s'.actionLog))
            
            T.putStrLn $ "Client joined: " <> name <> " (" <> T.pack (show $ newClient.clientId) <> ")"
            
            -- Send Welcome to the new client
            let clientNames = map (.clientName) $ Map.elems currentClients
            sendTextData (newClient.clientConn) $ encode $ Welcome (newClient.clientId) clientNames historyLog
            
            -- Notify others
            -- We construct a temporary state for broadcasting to everyone else
            let broadcastState = ServerState (Map.delete (newClient.clientId) currentClients) [] (CardLibrary [] [] [])
            broadcast (ClientJoined name (newClient.clientId)) broadcastState
            
            -- Continue loop with updated client info
            talkLoop newClient state
            
        Just (Broadcast payload) -> do
            -- Update log and broadcast
            currentClients <- modifyMVar state $ \s -> do
                let s' = addAction payload s
                return (s', s'.clients)

            -- Broadcast to others
            let broadcastState = ServerState (Map.delete (client.clientId) currentClients) [] (CardLibrary [] [] [])
            broadcast (BroadcastMessage (client.clientId) payload) broadcastState
            
            -- Continue loop
            talkLoop client state

-- | Inner loop after initial handshake/join logic if needed. 
-- Actually 'talk' handles dispatching, so we can just recurse 'talk' or have a dedicated loop.
-- But since 'Join' updates the client record (name), we need to pass that updated record around.
talkLoop :: Client -> MVar ServerState -> IO ()
talkLoop client state = do
    msgBytes <- receiveData (client.clientConn)
    case decode msgBytes of
        Nothing -> do
            T.putStrLn "Received invalid JSON"
            sendTextData (client.clientConn) (encode $ ErrorMessage "Invalid JSON")
            talkLoop client state
        Just (Join name) -> do
             -- Allow renaming?
            let newClient = client { clientName = name }
            modifyMVar_ state $ \s -> return $ addClient newClient s
            T.putStrLn $ "Client renamed: " <> name
            talkLoop newClient state
        Just (Broadcast payload) -> do
            -- Update log and broadcast
            currentClients <- modifyMVar state $ \s -> do
                let s' = addAction payload s
                return (s', s'.clients)

            let broadcastState = ServerState (Map.delete (client.clientId) currentClients) [] (CardLibrary [] [] [])
            broadcast (BroadcastMessage (client.clientId) payload) broadcastState
            
            talkLoop client state

disconnect :: Client -> MVar ServerState -> IO ()
disconnect client state = do
    T.putStrLn $ "Client disconnected: " <> client.clientName
    s <- modifyMVar state $ \s -> do
        let s' = removeClient client s
        return (s', s')
    broadcast (ClientLeft (client.clientId)) s
