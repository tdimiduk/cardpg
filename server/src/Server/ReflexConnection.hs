{-# LANGUAGE DuplicateRecordFields #-}
{-# LANGUAGE LambdaCase #-}

module Server.ReflexConnection where

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

import Reflex.Dom.GadtApi.WebSocket (TaggedRequest (..), mkTaggedResponse)

import Core.Card (CardInstance, CoreCard)
import Core.Json (cardpgJsonDef)
import Core.Primitives (ActorId)
import Core.State (ActorState (..), CoreCardState (..))
import Server.DB (saveGame)
import Server.Dispatch (processCommand)
import Server.Session (initGame)
import Server.Types
  ( AdminCommand (..)
  , Client (..)
  , Command (..)
  , ConnectedSocket (..)
  , GameState (..)
  , ServerState (..)
  , StateUpdate (..)
  , addClient
  , clientExists
  , removeClient
  )

import Api.Reflex
  ( ErrorMessage (..)
  , ErrorType (..)
  , GameView (..)
  , ServerPush (..)
  , WsMessage (..)
  )
import Api.Request (ApiRequest)
import Api.Request qualified as Req

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
      let view = GameView{actors = s.gameState.actors}
      let ph = s.gameState.phase
      return ([PushWelcome finalClientId view s.gameState.history ph], s.clients)

  forM_ msgs $ \msg -> sendTextData conn (encode $ WsMsgPush msg)

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

broadcastReflex :: ServerPush -> Map.Map UUID Client -> IO ()
broadcastReflex msg clients = do
  let msgBytes = encode (WsMsgPush msg)
  forM_ (Map.elems clients) $ \client ->
    forM_ (client.clientConns) $ \socket -> do
      _ <- try (sendTextData (socket.socketConn) msgBytes) :: IO (Either ConnectionException ())
      return ()

talk :: Client -> ConnectedSocket -> MVar ServerState -> IO ()
talk client socket state = forever $ do
  msgBytes <- receiveData (socket.socketConn)
  -- Try to parse as TaggedRequest first, fall back to legacy if needed
  case decode msgBytes of
    Just taggedReq@(TaggedRequest _ _) -> do
      result <- mkTaggedResponse taggedReq $ \case
        Req.Join name -> handleJoin client name state
        Req.SendChat aid msg -> do
          _ <- handleGameCommand client state (ChatIntent aid msg)
          pure ()
        Req.DrawCards aid -> handleGameCommand client state (DrawIntent aid)
        Req.Defend aid cid -> handleGameCommand client state (DefendIntent aid cid)
        Req.PlanMove aid x y -> handleGameCommand client state (PlanMove aid x y)
        Req.PlanAction aid acid rcids -> handleGameCommand client state (PlanAction aid acid rcids)
        Req.PlanNarrative aid cids col -> handleGameCommand client state (PlanNarrative aid cids col)
        Req.CancelPlan aid -> handleGameCommand client state (CancelPlanIntent aid)
        Req.StartResolution -> handleGameCommand client state StartResolutionIntent
        Req.EndDefense aid -> handleGameCommand client state (EndDefenseIntent aid)
        Req.Reshuffle aid -> handleGameCommand client state (ReshuffleIntent aid)
        Req.AddStatus aid st dest -> handleGameCommand client state (AddStatusIntent aid st dest)
        Req.DestroyStatus aid st mcid -> handleGameCommand client state (DestroyStatusIntent aid st mcid)
        Req.AddConsequence aid sev -> handleGameCommand client state (AddConsequenceIntent aid sev)
        Req.DestroyConsequence aid cid -> handleGameCommand client state (DestroyConsequenceIntent aid cid)
        Req.DiscardCards aid cids -> handleGameCommand client state (DiscardCardsIntent aid cids)
        Req.ReturnToDeck aid cids -> handleGameCommand client state (ReturnToDeckIntent aid cids)
        Req.EndRound -> handleGameCommand client state EndRoundIntent
        Req.Pass aid -> handleGameCommand client state (PassIntent aid)
      case result of
        Right resp -> sendTextData (socket.socketConn) (encode $ WsMsgResponse resp)
        Left err ->
          sendTextData
            (socket.socketConn)
            (encode $ WsMsgPush $ PushError (ErrorMessage (T.pack err) ErrorSystem))
    Nothing ->
      sendTextData
        (socket.socketConn)
        (encode $ WsMsgPush $ PushError (ErrorMessage "Invalid message" ErrorValidation))

handleJoin :: Client -> Text -> MVar ServerState -> IO (Either Text UUID)
handleJoin client name state = do
  modifyMVar_ state $ \s -> do
    let s' = s{clients = Map.adjust (\c -> c{clientName = name}) (client.clientId) (s.clients)}
    pure s'
  T.putStrLn $ "Client renamed: " <> name
  pure (Right client.clientId)

handleGameCommand :: Client -> MVar ServerState -> Command -> IO (Either Text [StateUpdate])
handleGameCommand client state cmd = do
  t <- getPOSIXTime
  let ts = round (t * 1000) :: Int

  (updates, newLog) <- modifyMVar state $ \s -> do
    let game = s.gameState
    let rng = s.rng
    let ((newGame, updates, _, newLog), newRng) = runState (processCommand cmd ts game) rng

    let s' = s{gameState = newGame, rng = newRng}
    return (s', (updates, newLog))

  -- Broadcast updates to others
  readMVar state >>= \s -> do
    -- We'll just pass existing phase if it didn't change, but here we can just pass current phase
    -- Actually PushUpdate takes Maybe Phase. We interpret this as "New Phase" (Change).
    -- But for simplicity we can just pass Nothing if we don't want to signal a change, or
    -- we can check if it changed.
    -- However, handleGameCommand doesn't return the OLD game state easily to check diff.
    -- Let's just always send the current phase for now if we want to be safe, OR we can accept
    -- that the client updates its phase on receiving this.
    -- Wait, PushUpdate takes Maybe Phase. If I send Just phase, client updates.
    -- If I send Nothing, client keeps old.
    -- Let's send Just (s.gameState.phase) to be sure synchronization is correct.
    broadcastReflex
      ( PushUpdate
          (GameView{actors = s.gameState.actors})
          (Just s.gameState.phase)
      )
      s.clients

  -- Broadcast new logs
  unless (null newLog) $ do
    readMVar state >>= \s -> broadcastReflex (PushNewLogs newLog) s.clients

  pure (Right updates)

handleGameCommand' = handleGameCommand
