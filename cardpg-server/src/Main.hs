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

-- | A client connection with a unique ID and a name.
data Client = Client
  { clientId :: UUID
  , clientName :: Text
  , clientConn :: Connection
  }

-- | The state of the server, mapping client IDs to clients.
type ServerState = Map UUID Client

-- | Custom Aeson options for JSON encoding
customOptions :: Options
customOptions = defaultOptions
  { sumEncoding = TaggedObject "tag" "contents"
  }

-- | Messages sent from Client to Server.
data ClientMessage
  = Join { name :: Text }
  | Broadcast { payload :: Value }
  deriving (Show, Generic)

instance FromJSON ClientMessage where
  parseJSON = genericParseJSON customOptions

instance ToJSON ClientMessage where
  toJSON = genericToJSON customOptions

-- | Messages sent from Server to Client.
data ServerMessage
  = Welcome { yourClientId :: UUID, connectedClients :: [Text] }
  | BroadcastMessage { fromClientId :: UUID, payload :: Value }
  | ClientJoined { newClientName :: Text, newClientId :: UUID }
  | ClientLeft { leftClientId :: UUID }
  | ErrorMessage { error :: Text }
  deriving (Show, Generic)

instance FromJSON ServerMessage where
  parseJSON = genericParseJSON customOptions

instance ToJSON ServerMessage where
  toJSON = genericToJSON customOptions

newServerState :: ServerState
newServerState = Map.empty

numClients :: ServerState -> Int
numClients = Map.size

clientExists :: Client -> ServerState -> Bool
clientExists client = Map.member (clientId client)

addClient :: Client -> ServerState -> ServerState
addClient client = Map.insert (clientId client) client

removeClient :: Client -> ServerState -> ServerState
removeClient client = Map.delete (clientId client)

broadcast :: ServerMessage -> ServerState -> IO ()
broadcast msg state = do
    let msgBytes = encode msg
    forM_ (Map.elems state) $ \client ->
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
            currentClients <- modifyMVar state $ \s -> do
                let s' = addClient newClient s
                return (s', s')
            
            T.putStrLn $ "Client joined: " <> name <> " (" <> T.pack (show $ clientId newClient) <> ")"
            
            -- Send Welcome to the new client
            let clientNames = map clientName $ Map.elems currentClients
            sendTextData (clientConn newClient) $ encode $ Welcome (clientId newClient) clientNames
            
            -- Notify others
            broadcast (ClientJoined name (clientId newClient)) (removeClient newClient currentClients)
            
            -- Continue loop with updated client info
            talkLoop newClient state
            
        Just (Broadcast payload) -> do
            -- We can't broadcast if we haven't joined yet? 
            -- For MVP let's allow it but it might be weird if name is Anonymous
            currentClients <- readMVar state
            broadcast (BroadcastMessage (clientId client) payload) (removeClient client currentClients)
            
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
            currentClients <- readMVar state
            broadcast (BroadcastMessage (clientId client) payload) (removeClient client currentClients)
            talkLoop client state

disconnect :: Client -> MVar ServerState -> IO ()
disconnect client state = do
    T.putStrLn $ "Client disconnected: " <> clientName client
    s <- modifyMVar state $ \s -> do
        let s' = removeClient client s
        return (s', s')
    broadcast (ClientLeft (clientId client)) s
