{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE RecordWildCards #-}
{-# LANGUAGE DeriveGeneric #-}

module Main where

import Control.Concurrent (MVar, newMVar, modifyMVar_, modifyMVar, readMVar)
import Control.Exception (finally)
import Control.Monad (forM_, forever)
import Data.Aeson (FromJSON(..), ToJSON(..), Value, encode, decode, genericToJSON, genericParseJSON, defaultOptions, Options(..), SumEncoding(..))
import qualified Data.ByteString.Lazy as B
import Data.Map (Map)
import qualified Data.Map as Map
import Data.Text (Text)
import qualified Data.Text as T
import qualified Data.Text.IO as T
import Data.UUID (UUID)
import qualified Data.UUID.V4 as UUID
import GHC.Generics (Generic)
import Network.WebSockets (Connection, ServerApp, acceptRequest, receiveData, sendTextData, withPingThread)
import qualified Network.WebSockets as WS

import CardPG.Server.Types (Client(..), ClientMessage(..), ServerMessage(..))

-- | The state of the server, mapping client IDs to clients and storing action history.
data ServerState = ServerState
  { clients :: Map UUID Client
  , actionLog :: [Value]
  }

newServerState :: ServerState
newServerState = ServerState Map.empty []

numClients :: ServerState -> Int
numClients = Map.size . clients

clientExists :: Client -> ServerState -> Bool
clientExists client state = Map.member (clientId client) (clients state)

addClient :: Client -> ServerState -> ServerState
addClient client state = state { clients = Map.insert (clientId client) client (clients state) }

removeClient :: Client -> ServerState -> ServerState
removeClient client state = state { clients = Map.delete (clientId client) (clients state) }

addAction :: Value -> ServerState -> ServerState
addAction action state = state { actionLog = actionLog state ++ [action] }

broadcast :: ServerMessage -> ServerState -> IO ()
broadcast msg state = do
    let msgBytes = encode msg
    forM_ (Map.elems (clients state)) $ \client ->
        sendTextData (clientConn client) msgBytes

main :: IO ()
main = do
    state <- newMVar newServerState
    T.putStrLn "Starting CardPG Server on port 8080..."
    WS.runServer "127.0.0.1" 8080 $ application state

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
    msgBytes <- receiveData (clientConn client)
    case decode msgBytes of
        Nothing -> do
            T.putStrLn "Received invalid JSON"
            sendTextData (clientConn client) (encode $ ErrorMessage "Invalid JSON")
        Just (Join name) -> do
            let newClient = client { clientName = name }
            
            -- Update state with new client
            (currentClients, historyLog) <- modifyMVar state $ \s -> do
                let s' = addClient newClient s
                return (s', (clients s', actionLog s'))
            
            T.putStrLn $ "Client joined: " <> name <> " (" <> T.pack (show $ clientId newClient) <> ")"
            
            -- Send Welcome to the new client
            let clientNames = map clientName $ Map.elems currentClients
            sendTextData (clientConn newClient) $ encode $ Welcome (clientId newClient) clientNames historyLog
            
            -- Notify others
            -- We construct a temporary state for broadcasting to everyone else
            let broadcastState = ServerState (Map.delete (clientId newClient) currentClients) []
            broadcast (ClientJoined name (clientId newClient)) broadcastState
            
            -- Continue loop with updated client info
            talkLoop newClient state
            
        Just (Broadcast payload) -> do
            -- Update log and broadcast
            currentClients <- modifyMVar state $ \s -> do
                let s' = addAction payload s
                return (s', clients s')

            -- Broadcast to others
            let broadcastState = ServerState (Map.delete (clientId client) currentClients) []
            broadcast (BroadcastMessage (clientId client) payload) broadcastState
            
            -- Continue loop
            talkLoop client state

-- | Inner loop after initial handshake/join logic if needed. 
-- Actually 'talk' handles dispatching, so we can just recurse 'talk' or have a dedicated loop.
-- But since 'Join' updates the client record (name), we need to pass that updated record around.
talkLoop :: Client -> MVar ServerState -> IO ()
talkLoop client state = do
    msgBytes <- receiveData (clientConn client)
    case decode msgBytes of
        Nothing -> do
            T.putStrLn "Received invalid JSON"
            sendTextData (clientConn client) (encode $ ErrorMessage "Invalid JSON")
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
                return (s', clients s')

            let broadcastState = ServerState (Map.delete (clientId client) currentClients) []
            broadcast (BroadcastMessage (clientId client) payload) broadcastState
            
            talkLoop client state

disconnect :: Client -> MVar ServerState -> IO ()
disconnect client state = do
    T.putStrLn $ "Client disconnected: " <> clientName client
    s <- modifyMVar state $ \s -> do
        let s' = removeClient client s
        return (s', s')
    broadcast (ClientLeft (clientId client)) s
