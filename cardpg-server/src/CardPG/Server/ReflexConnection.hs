module CardPG.Server.ReflexConnection where

import Control.Concurrent (MVar, modifyMVar, modifyMVar_, readMVar)
import Control.Exception (finally, try)
import Control.Monad (forM_, forever, unless, when)
import Control.Monad.State (runState)
import Data.Aeson (ToJSON, decode, encode, genericToJSON)
import Data.Aeson.TH (deriveJSON)
import Data.Map (Map)
import Data.Map qualified as Map
import Data.Maybe (fromMaybe, isJust)
import Data.Text (Text)
import Data.Text qualified as T
import Data.Text.Encoding qualified as T
import Data.Text.IO qualified as T
import Data.Time.Clock.POSIX (getPOSIXTime)
import Data.UUID (UUID)
import Data.UUID qualified as UUID
import Data.UUID.V4 qualified as UUID
import GHC.Generics (Generic)
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

import CardPG.Core.Card (CardInstance, CoreCard)
import CardPG.Core.Json (cardpgJsonDef)
import CardPG.Core.Primitives (ActorId)
import CardPG.Core.State (ActorState (..), CoreCardState (..))
import CardPG.Server.DB (saveGame)
import CardPG.Server.Dispatch (processCommand)
import CardPG.Server.Session (initGame)
import CardPG.Server.Types
  ( AdminCommand (..)
  , Client (..)
  , ClientMessage (..)
  , Command (..)
  , ConnectedSocket (..)
  , GameState (..)
  , ServerState (..)
  , addClient
  , clientExists
  , removeClient
  )

-- | New message type using Core types directly
data ReflexServerMessage
  = ReflexWelcome
      { yourClientId :: UUID
      , hands :: Map ActorId [CardInstance CoreCard]
      }
  | ReflexUpdate
      { hands :: Map ActorId [CardInstance CoreCard]
      }
  | ReflexError {error :: Text}
  deriving (Show, Generic)

$(deriveJSON cardpgJsonDef ''ReflexServerMessage)

application :: MVar ServerState -> ServerApp
application state pending = do
  conn <- acceptRequest pending

  -- Parse query string for clientId (Same as original)
  let path = requestPath (pendingRequest pending)
  let queryText = T.decodeUtf8 path
  let maybeQuery = if T.isInfixOf "?" queryText then Just (T.tail $ snd $ T.breakOn "?" queryText) else Nothing

  (finalClientId, newName) <- case maybeQuery of
    Nothing -> do
      uuid <- UUID.nextRandom
      return (uuid, "Anonymous")
    Just q -> do
      let params = map (T.breakOn "=") $ T.splitOn "&" q
      let getParam k =
            case lookup k params of
              Just val | not (T.null val) -> Just (T.drop 1 val)
              _ -> Nothing
      let maybeName = getParam "name"
      let maybeCidStr = getParam "clientId"
      case maybeCidStr of
        Just uuidStr -> do
          case UUID.fromText uuidStr of
            Just cid -> do
              exists <- readMVar state >>= \s -> return $ clientExists cid s
              let defaultName = if exists then "Reconnect" else "Anonymous"
              return (cid, fromMaybe defaultName maybeName)
            Nothing -> do
              u <- UUID.nextRandom
              return (u, fromMaybe "Anonymous" maybeName)
        Nothing -> do
          u <- UUID.nextRandom
          return (u, fromMaybe "Anonymous" maybeName)

  socketId <- UUID.nextRandom
  let connectedSocket = ConnectedSocket socketId conn

  (client, isNew) <- modifyMVar state $ \s -> do
    let (c, isNew) = case Map.lookup finalClientId (s.clients) of
          Just existing ->
            (existing{clientConns = existing.clientConns ++ [connectedSocket]}, False)
          Nothing ->
            (Client finalClientId newName [connectedSocket], True)
    let s' = addClient c s
    return (s', (c, isNew))

  -- Send Welcome
  (msgs, currentClients) <-
    readMVar state >>= \s -> do
      let allHands = Map.map (\a -> a.coreState.hand) (s.gameState.actors)
      let welcomeMsg = ReflexWelcome finalClientId allHands
      return ([welcomeMsg], s.clients)

  forM_ msgs $ \msg -> sendTextData conn (encode msg)

  if isNew
    then T.putStrLn $ "Client Joined: " <> (client.clientName)
    else T.putStrLn $ "Client reconnected: " <> (client.clientName)

  withPingThread conn 30 (return ()) $ do
    flip finally (disconnect finalClientId socketId state) $ do
      talk client connectedSocket state

disconnect :: UUID -> UUID -> MVar ServerState -> IO ()
disconnect clientId socketId state = do
  modifyMVar_ state $ \s -> do
    return $ removeClient clientId socketId s
  T.putStrLn $ "Client disconnected: " <> T.pack (show clientId)

broadcastReflex :: ReflexServerMessage -> Map.Map UUID Client -> IO ()
broadcastReflex msg clients = do
  let msgBytes = encode msg
  forM_ (Map.elems clients) $ \client ->
    forM_ (client.clientConns) $ \socket -> do
      _ <- try (sendTextData (socket.socketConn) msgBytes) :: IO (Either ConnectionException ())
      return ()

talk :: Client -> ConnectedSocket -> MVar ServerState -> IO ()
talk client socket state = forever $ do
  msgBytes <- receiveData (socket.socketConn)
  case decode msgBytes of
    Nothing -> do
      T.putStrLn "Received invalid JSON"
      sendTextData (socket.socketConn) (encode $ ReflexError "Invalid JSON")
    Just (Join name _) -> do
      -- Rename logic
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
    Just (GameCommand cmd) -> handleGameCommand (client.clientId) (client.clientName) state cmd
    Just (Admin ResetGame) -> do
      T.putStrLn "Admin: Resetting Game"
      (newGs, _, clientsMap) <- modifyMVar state $ \s -> do
        (gs, rng) <- initGame (s.dbPool) (s.config) (s.library) True
        let s' = s{gameState = gs, rng = rng}
        return (s', (gs, s.dbPool, s.clients))

      let allHands = Map.map (\a -> a.coreState.hand) (newGs.actors)
      let msg = ReflexUpdate allHands
      broadcastReflex msg clientsMap

handleGameCommand :: UUID -> T.Text -> MVar ServerState -> Command -> IO ()
handleGameCommand _ clientName state cmd = do
  T.putStrLn $ "Received command: " <> T.pack (show cmd) <> " from " <> clientName
  t <- getPOSIXTime
  let ts = round (t * 1000) :: Int

  (newGame, pool, clientsMap, newRng) <- modifyMVar state $ \s -> do
    let game = s.gameState
    let rng = s.rng
    let ((newGame, _, _, _), newRng) = runState (processCommand cmd ts game) rng
    return
      ( s{gameState = newGame, rng = newRng}
      , (newGame, s.dbPool, s.clients, newRng)
      )

  saveGame pool "default-game" newGame

  -- Send Full Hands Update
  let allHands = Map.map (\a -> a.coreState.hand) (newGame.actors)
  let msg = ReflexUpdate allHands
  broadcastReflex msg clientsMap
