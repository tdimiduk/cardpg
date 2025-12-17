module CardPG.Server.Connection where

import Control.Concurrent (MVar, modifyMVar, modifyMVar_, readMVar)
import Control.Exception (finally)
import Control.Monad (forM_, forever, unless, when)
import Control.Monad.State (runState)
import Data.Aeson (decode, encode)
import Data.Map qualified as Map
import Data.Text qualified as T
import Data.Text.IO qualified as T
import Data.Time.Clock.POSIX (getPOSIXTime)
import Data.UUID qualified as UUID
import Data.UUID.V4 qualified as UUID
import Network.WebSockets (ServerApp, acceptRequest, receiveData, sendTextData, withPingThread)

import CardPG.Server.DB (saveGame)
import CardPG.Server.Dispatch (processCommand)
import CardPG.Server.Session (initGame)
import CardPG.Server.Types
  ( AdminCommand (..)
  , CardLibrary (..)
  , Client (..)
  , ClientMessage (..)
  , Command (..)
  , GameState (..)
  , ServerMessage (..)
  , ServerState (..)
  , StateUpdate (..)
  , addClient
  , clientExists
  , removeClient
  )

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

disconnect :: Client -> MVar ServerState -> IO ()
disconnect client state = do
  T.putStrLn $ "Client disconnected: " <> client.clientName
  s <- modifyMVar state $ \s -> do
    let s' = removeClient client s
    return (s', s')
  broadcast (ClientLeft (client.clientId)) (s.clients)

broadcast :: ServerMessage -> Map.Map UUID.UUID Client -> IO ()
broadcast msg clients = do
  let msgBytes = encode msg
  forM_ (Map.elems clients) $ \client ->
    sendTextData (client.clientConn) msgBytes

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

      let newClient = client{clientName = name, clientId = clientId}

      T.putStrLn $
        "Client joining: "
          <> name
          <> " ("
          <> T.pack (show clientId)
          <> ")"
          <> (if isReconnect then " [RECONNECT]" else "")

      -- Prepare broadcast
      (currentClients, currentGs, messages, pool) <- modifyMVar state $ \s -> do
        let s' = addClient newClient s -- Overwrites existing entry if reconnecting (updating socket)
        let initialUpdates = map (uncurry StateUpdate) $ Map.toList (s'.gameState.actors)

        let welcomeMsg =
              Welcome
                clientId
                (map (.clientName) $ Map.elems s'.clients)
                initialUpdates
                (s'.gameState.phase)
                (s'.gameState.history)

        return (s', (s'.clients, s'.gameState, [welcomeMsg], s'.dbPool))

      -- Send Welcome
      forM_ messages $ \msg -> sendTextData (newClient.clientConn) (encode msg)

      -- Notify others
      broadcast (ClientJoined name clientId) currentClients

      -- Continue loop with updated client info
      talkLoop newClient state
    Just (GameCommand cmd) -> do
      -- Clients must Join before sending commands.
      T.putStrLn "Received command before Join"
      sendTextData (client.clientConn) (encode $ ErrorMessage "Please Join first")
    Just (Admin _) -> do
      T.putStrLn "Received admin command before Join"
      sendTextData (client.clientConn) (encode $ ErrorMessage "Please Join first")

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
      let newClient = client{clientName = name}
      modifyMVar_ state $ \s -> return $ addClient newClient s
      T.putStrLn $ "Client renamed: " <> name
      talkLoop newClient state
    Just (GameCommand cmd) -> handleGameCommand client state cmd
    Just (Admin ResetGame) -> do
      T.putStrLn $ "Admin: Resetting Game requested by " <> client.clientName
      (newGs, pool, clientsMap) <- modifyMVar state $ \s -> do
        (gs, rng) <- initGame (s.dbPool) (s.config) (s.library) True
        let s' = s{gameState = gs, rng = rng}
        return (s', (gs, s.dbPool, s.clients))

      -- Send custom Welcome to all clients
      let initialUpdates = map (uncurry StateUpdate) $ Map.toList (newGs.actors)
      let connectedNames = map (.clientName) $ Map.elems clientsMap

      forM_ (Map.elems clientsMap) $ \c -> do
        let welcomeMsg =
              Welcome
                (c.clientId)
                connectedNames
                initialUpdates
                (newGs.phase)
                (newGs.history)
        sendTextData (c.clientConn) (encode welcomeMsg)

      talkLoop client state

handleGameCommand :: Client -> MVar ServerState -> Command -> IO ()
handleGameCommand client state cmd = do
  T.putStrLn $ "Received command: " <> T.pack (show cmd) <> " from " <> client.clientName

  -- Run action against authoritative state
  t <- getPOSIXTime
  let ts = round (t * 1000) :: Int

  (newGame, pool, updates, actions, logs, clientsMap, newPhase, oldPhase, newRng) <- modifyMVar state $ \s -> do
    let game = s.gameState
    let rng = s.rng

    -- Run monadic action
    let ((newGame, updates, actions, logs), newRng) = runState (processCommand cmd ts game) rng

    return
      ( s{gameState = newGame, rng = newRng}
      , (newGame, s.dbPool, updates, actions, logs, s.clients, newGame.phase, game.phase, newRng)
      )

  -- Persist State
  saveGame pool "default-game" newGame

  -- Broadcast results
  let messages =
        [BroadcastMessage (client.clientId) actions | not (null actions)]
          ++ [ GameStateUpdate updates (if newPhase /= oldPhase then Just newPhase else Nothing)
             | not (null updates) || newPhase /= oldPhase
             ]
          ++ [NewLogs logs | not (null logs)]

  unless (null messages) $ broadcast (MultiMessage messages) clientsMap

  talkLoop client state
