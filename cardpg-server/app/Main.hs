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
import Data.UUID (UUID, toText)
import qualified Data.UUID.V4 as UUID
import GHC.Generics (Generic)
import Network.WebSockets (Connection, ServerApp, acceptRequest, receiveData, sendTextData, withPingThread)
import qualified Network.WebSockets as WS

import System.Random (newStdGen)

import CardPG.Core.Hardcoded (fatigueCard)
import CardPG.Core.State (GameEnv(..), GameEvent(..), ActorState)
import CardPG.Core.Primitives (TargetId(..))
import qualified CardPG.Core.Logic as Logic
import CardPG.Server.Game (GameState(..), emptyGame, runActorAction, processCommand)
import CardPG.Server.Types (Client(..), ClientMessage(..), ServerMessage(..), BroadcastAction(..), ServerState(..), newServerState, CardLibrary(..), Command(..), StateUpdate(..))


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
    -- Initialize GameState
    rng <- newStdGen
    let env = GameEnv { fatigueCardTemplate = fatigueCard }
    let emptyGs = emptyGame env rng
    
    let cardsFile = "vtt-react/src/data/generated_cards.json"
    T.putStrLn $ "Loading card library from " <> T.pack cardsFile <> "..."
    cardLibraryResult <- eitherDecodeFileStrict cardsFile
    
    initialState <- case cardLibraryResult of
        Left err -> do
             T.putStrLn $ "WARNING: Failed to load card library: " <> T.pack err
             return (newServerState emptyGs)
        Right lib -> do
             T.putStrLn $ "Card Library Loaded: " 
                <> T.pack (show (length (lib.actors))) <> " actors, " 
                <> T.pack (show (length (lib.statuses))) <> " statuses, "
                <> T.pack (show (length (lib.consequences))) <> " consequences."
             return $ (newServerState emptyGs) { library = lib }

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
            (currentClients, currentGs) <- modifyMVar state $ \s -> do
                let s' = addClient newClient s
                return (s', (s'.clients, s'.gameState))
            
            T.putStrLn $ "Client joined: " <> name <> " (" <> T.pack (show $ newClient.clientId) <> ")"
            
            -- Send Welcome to the new client
            let clientNames = map (.clientName) $ Map.elems currentClients
            -- We can pass empty history for now or s.actionLog if we had it
            -- The original code passed 'historyLog' which was returned.
            -- Wait, let's look at original code.
            -- original: (currentClients, historyLog) <- modifyMVar ... return (s', (s'.clients, s'.actionLog))
            -- I should preserve that.
            
            -- Re-reading original code:
            -- (currentClients, historyLog) <- modifyMVar state $ \s -> return (s', (s'.clients, s'.actionLog))
            
            -- New version:
            (currentClients, historyLog, currentGs) <- modifyMVar state $ \s -> do
                let s' = addClient newClient s
                return (s', (s'.clients, s'.actionLog, s'.gameState))

            -- Send Welcome
            sendTextData (newClient.clientConn) $ encode $ Welcome (newClient.clientId) (map (.clientName) $ Map.elems currentClients) historyLog
            
            -- Notify others
            let broadcastState = ServerState (Map.delete (newClient.clientId) currentClients) [] (CardLibrary [] [] []) currentGs
            broadcast (ClientJoined name (newClient.clientId)) broadcastState
            
            -- Continue loop with updated client info
            talkLoop newClient state
            
        Just (Broadcast payload) -> do
            -- Update log and broadcast
            (currentClients, currentGs) <- modifyMVar state $ \s -> do
                let s' = addAction payload s
                return (s', (s'.clients, s'.gameState))

            -- Broadcast to others
            let broadcastState = ServerState (Map.delete (client.clientId) currentClients) [] (CardLibrary [] [] []) currentGs
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
            (currentClients, currentGs) <- modifyMVar state $ \s -> do
                let s' = addAction payload s
                return (s', (s'.clients, s'.gameState))

            let broadcastState = ServerState (Map.delete (client.clientId) currentClients) [] (CardLibrary [] [] []) currentGs
            broadcast (BroadcastMessage (client.clientId) payload) broadcastState
            
            talkLoop client state
        Just (GameCommand cmd) -> do
            T.putStrLn $ "Received command: " <> T.pack (show cmd) <> " from " <> client.clientName
            
            -- Run action against authoritative state via Game module
            res <- modifyMVar state $ \s -> do
                let game = s.gameState
                let (newGame, result) = processCommand cmd game
                
                case result of
                    Nothing -> return (s, Nothing) -- Actor not found or error
                    Just (targetId, actions, actorSt) -> do
                        -- Update GameHistory
                        let s' = foldl (flip addAction) (s { gameState = newGame }) actions
                        return (s', Just (actions, actorSt, s'.clients))

            -- Broadcast results
            case res of
                Nothing -> 
                    T.putStrLn $ "Command failed (invalid actor?)"
                Just (actions, actorSt, clientsMap) -> do
                    -- 1. Broadcast Animations (Legacy/FX)
                    let tempState = ServerState clientsMap [] (CardLibrary [] [] []) (error "GameState unused in broadcast")
                    
                    forM_ actions $ \act -> 
                        broadcast (BroadcastMessage (client.clientId) act) tempState
                        
                    -- 2. Broadcast State Update
                    let updateMsg = GameStateUpdate (FullStateUpdate actorSt)
                    broadcast updateMsg tempState
            
            talkLoop client state

disconnect :: Client -> MVar ServerState -> IO ()
disconnect client state = do
    T.putStrLn $ "Client disconnected: " <> client.clientName
    s <- modifyMVar state $ \s -> do
        let s' = removeClient client s
        return (s', s')
    broadcast (ClientLeft (client.clientId)) s
