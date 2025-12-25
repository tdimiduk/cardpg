module CardPG.Server.Connection where

import Control.Concurrent (MVar, modifyMVar, modifyMVar_, readMVar)
import Control.Exception (finally, try)
import Control.Monad (forM_, forever, unless, when)
import Control.Monad.State (runState)
import Data.Aeson (decode, encode)
import Data.Map qualified as Map
import Data.Maybe (fromMaybe)
import Data.Text qualified as T
import Data.Text.Encoding qualified as T
import Data.Text.IO qualified as T
import Data.Time.Clock.POSIX (getPOSIXTime)
import Data.UUID qualified as UUID
import Data.UUID.V4 qualified as UUID
import Network.WebSockets
  ( ConnectionException
  , ServerApp
  , acceptRequest
  , pendingRequest
  , receiveData
  , requestPath
  , sendTextData
  , withPingThread
  )

import CardPG.Server.DB (saveGame)
import CardPG.Server.Dispatch (processCommand)
import CardPG.Server.Session (initGame)
import CardPG.Server.Types
  ( AdminCommand (..)
  , CardLibrary (..)
  , Client (..)
  , ClientMessage (..)
  , Command (..)
  , ConnectedSocket (..)
  , GameState (..)
  , ServerMessage (..)
  , ServerState (..)
  , StateUpdate (..)
  , addClient
  , clientExists
  , removeClient
  )
import CardPG.Api.Frontend qualified as Frontend

application :: MVar ServerState -> ServerApp
application state pending = do
  conn <- acceptRequest pending

  -- Parse query string for clientId
  let path = requestPath (pendingRequest pending)
  let queryText = T.decodeUtf8 path
  -- Basic parsing: split by '?', then '&', look for "clientId="
  let maybeQuery = if T.isInfixOf "?" queryText then Just (T.tail $ snd $ T.breakOn "?" queryText) else Nothing

  -- Determine Client ID
  (finalClientId, newName) <- case maybeQuery of
    Nothing -> do
      uuid <- UUID.nextRandom
      return (uuid, "Anonymous")
    Just q -> do
      let params = map (T.breakOn "=") $ T.splitOn "&" q

      -- Helper to get param value
      let getParam k =
            case lookup k params of
              Just val | not (T.null val) -> Just (T.drop 1 val) -- drop '='
              _ -> Nothing

      let maybeName = getParam "name"
      let maybeCidStr = getParam "clientId"

      case maybeCidStr of
        Just uuidStr -> do
          case UUID.fromText uuidStr of
            Just cid -> do
              -- Verify if exists
              exists <- readMVar state >>= \s -> return $ clientExists cid s
              let defaultName = if exists then "Reconnect" else "Anonymous"
              return (cid, fromMaybe defaultName maybeName)
            Nothing -> do
              u <- UUID.nextRandom
              return (u, fromMaybe "Anonymous" maybeName)
        Nothing -> do
          u <- UUID.nextRandom
          return (u, fromMaybe "Anonymous" maybeName)

  -- Generate valid Socket ID
  socketId <- UUID.nextRandom
  let connectedSocket = ConnectedSocket socketId conn

  -- Add to State
  (client, isNew) <- modifyMVar state $ \s -> do
    let (c, isNew) = case Map.lookup finalClientId (s.clients) of
          Just existing ->
            -- Append connection
            (existing{clientConns = existing.clientConns ++ [connectedSocket]}, False)
          Nothing ->
            -- New Client
            (Client finalClientId newName [connectedSocket], True)

    let s' = addClient c s
    return (s', (c, isNew))

  -- Send Welcome Immediately
  (msgs, initialUpdate, currentClients) <-
    readMVar state >>= \s -> do
      let updates =
            map (\(aid, actor) -> StateUpdate aid (Frontend.toActorState actor)) $
              Map.toList (s.gameState.actors)
      let welcomeMsg =
            Welcome
              finalClientId
              (map (.clientName) $ Map.elems s.clients)
              updates
              (s.gameState.phase)
              (s.gameState.history)
      return ([welcomeMsg], updates, s.clients)

  forM_ msgs $ \msg -> sendTextData conn (encode msg)

  if isNew
    then broadcast (ClientJoined (client.clientName) finalClientId) currentClients
    else
      T.putStrLn $
        "Client reconnected: " <> (client.clientName) <> " (" <> T.pack (show finalClientId) <> ")"

  -- Keep connection alive
  withPingThread conn 30 (return ()) $ do
    flip finally (disconnect finalClientId socketId state) $ do
      talk client connectedSocket state

disconnect :: UUID.UUID -> UUID.UUID -> MVar ServerState -> IO ()
disconnect clientId socketId state = do
  s <- modifyMVar state $ \s -> do
    let s' = removeClient clientId socketId s
    return (s', s')

  -- Check if client completely removed
  let stillExists = Map.member clientId (s.clients)
  unless stillExists $ do
    T.putStrLn $ "Client fully disconnected: " <> T.pack (show clientId)
    broadcast (ClientLeft clientId) (s.clients)

broadcast :: ServerMessage -> Map.Map UUID.UUID Client -> IO ()
broadcast msg clients = do
  let msgBytes = encode msg
  forM_ (Map.elems clients) $ \client ->
    forM_ (client.clientConns) $ \socket -> do
      result <- try (sendTextData (socket.socketConn) msgBytes) :: IO (Either ConnectionException ())
      case result of
        Left _ -> return () -- Ignore errors, cleanup happens in 'finally' of the connection thread
        Right _ -> return ()

talk :: Client -> ConnectedSocket -> MVar ServerState -> IO ()
talk client socket state = forever $ do
  msgBytes <- receiveData (socket.socketConn)
  case decode msgBytes of
    Nothing -> do
      T.putStrLn "Received invalid JSON"
      sendTextData (socket.socketConn) (encode $ ErrorMessage "Invalid JSON")
    Just (Join name _) -> do
      -- Handle Renaming (Ignore ID part)
      -- First check if name actually changed to avoid log noise
      currentClient <- readMVar state >>= \s -> return $ Map.lookup (client.clientId) (s.clients)

      let shouldUpdate = case currentClient of
            Just c -> c.clientName /= name
            Nothing -> True

      when shouldUpdate $ do
        modifyMVar_ state $ \s -> do
          case Map.lookup (client.clientId) (s.clients) of
            Just existing -> return $ addClient (existing{clientName = name}) s
            Nothing -> return s
        T.putStrLn $ "Client renamed: " <> name
    -- We could broadcast update, but current broadcast is just ClientJoined/Left.
    -- Maybe add ClientUpdated? For now just log.
    Just (GameCommand cmd) -> handleGameCommand (client.clientId) (client.clientName) state cmd
    Just (Admin ResetGame) -> do
      T.putStrLn $ "Admin: Resetting Game requested by " <> client.clientName
      (newGs, pool, clientsMap) <- modifyMVar state $ \s -> do
        (gs, rng) <- initGame (s.dbPool) (s.config) (s.library) True
        let s' = s{gameState = gs, rng = rng}
        return (s', (gs, s.dbPool, s.clients))

      -- Send custom Welcome to all clients
      let initialUpdates = map (\(aid, actor) -> StateUpdate aid (Frontend.toActorState actor)) $ Map.toList (newGs.actors)
      let connectedNames = map (.clientName) $ Map.elems clientsMap

      -- Broadcast Welcome manually to all sockets
      let welcomeMsg c = Welcome (c.clientId) connectedNames initialUpdates (newGs.phase) (newGs.history)

      forM_ (Map.elems clientsMap) $ \c ->
        forM_ (c.clientConns) $ \sock ->
          sendTextData (sock.socketConn) (encode $ welcomeMsg c)

handleGameCommand :: UUID.UUID -> T.Text -> MVar ServerState -> Command -> IO ()
handleGameCommand clientId clientName state cmd = do
  T.putStrLn $ "Received command: " <> T.pack (show cmd) <> " from " <> clientName

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

  -- Broadcast results (State updates + Logs only, no event stream)
  let messages =
        [ GameStateUpdate updates (if newPhase /= oldPhase then Just newPhase else Nothing)
        | not (null updates) || newPhase /= oldPhase
        ]
          ++ [NewLogs logs | not (null logs)]

  unless (null messages) $ broadcast (MultiMessage messages) clientsMap
