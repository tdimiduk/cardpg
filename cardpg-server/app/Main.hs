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

main :: IO ()
main = do
    hSetBuffering stdout NoBuffering
    cardsFileEnv <- lookupEnv "CARDPG_CARDS_FILE"
    let cardsFile = fromMaybe "vtt-react/src/data/generated_cards.json" cardsFileEnv

    scenarioFileEnv <- lookupEnv "CARDPG_SCENARIO_FILE"
    let scenarioFile = fromMaybe "data/scenarios/starter.yaml" scenarioFileEnv

    T.putStrLn $ "Loading starter scenario from " <> T.pack scenarioFile <> "..."
    initialGs <- loadScenario scenarioFile
    
    T.putStrLn $ "Loading card library from " <> T.pack cardsFile <> "..."
    cardLibraryResult <- eitherDecodeFileStrict cardsFile
    
    initialState <- case cardLibraryResult of
        Left err -> do
             T.putStrLn $ "WARNING: Failed to load card library: " <> T.pack err
             return (newServerState initialGs)
        Right lib -> do
             T.putStrLn $ "Card Library Loaded: " 
                <> T.pack (show (length (lib.actors))) <> " actors, " 
                <> T.pack (show (length (lib.statuses))) <> " statuses, "
                <> T.pack (show (length (lib.consequences))) <> " consequences."
             
             let env = initialGs.env
             let statusMap = Map.fromList [(getRawText c.name, c) | c <- lib.statuses]
             let consequenceMap = Map.fromList [(getRawText c.name, c) | c <- lib.consequences]
             
             let newEnv = env { statusCardTemplates = statusMap, consequenceCardTemplates = consequenceMap }
             let newGs = initialGs { env = newEnv }
             
             return $ (newServerState newGs) { library = lib }

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
            (currentClients, currentGs) <- modifyMVar state $ \s -> do
                let s' = addClient newClient s
                return (s', (s'.clients, s'.gameState))

            let initialUpdates = map (\(tid, ast) -> StateUpdate tid ast) $ Map.toList (currentGs.actors)
            sendTextData (newClient.clientConn) $ encode $ Welcome (newClient.clientId) (map (.clientName) $ Map.elems currentClients) initialUpdates (currentGs.phase)
            
            -- Notify others
            let broadcastState = ServerState (Map.delete (newClient.clientId) currentClients) (CardLibrary [] [] []) currentGs
            broadcast (ClientJoined name (newClient.clientId)) broadcastState
            
            -- Continue loop with updated client info
            talkLoop newClient state
            
            
            -- Continue loop
            talkLoop client state

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

        Just (GameCommand cmd) -> do
            T.putStrLn $ "Received command: " <> T.pack (show cmd) <> " from " <> client.clientName
            
            -- Run action against authoritative state
            (updates, actions, clientsMap, newPhase, oldPhase) <- modifyMVar state $ \s -> do
                let game = s.gameState
                let (newGame, updates, actions) = processCommand cmd game
                
                -- Update GameHistory (REMOVED)
                return (s { gameState = newGame }, (updates, actions, s.clients, newGame.phase, game.phase))

            -- Broadcast results
            let tempState = ServerState clientsMap (CardLibrary [] [] []) (error "GameState unused in broadcast")
            
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
