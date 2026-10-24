{-# LANGUAGE DuplicateRecordFields #-}
{-# LANGUAGE ScopedTypeVariables #-}

module Server.ReflexConnection where

import Control.Concurrent (MVar, modifyMVar, modifyMVar_, readMVar)
import Control.Exception (SomeException, finally, try)
import Control.Lens hiding (view)
import Control.Monad (forM_, forever, unless, when)
import Control.Monad.State (runState)
import Data.Aeson (Result (..), decode, encode, fromJSON)
import Data.Generics.Labels ()
import Data.Map qualified as Map
import Data.Maybe (fromMaybe)
import Data.Text (Text)
import Data.Text qualified as T
import Data.Text.Encoding qualified as T
import Data.Text.IO qualified as T
import Data.UUID (UUID)
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
import System.Random.Stateful (uniform)

import Data.ByteString.Lazy.Char8 qualified as BSL
import Reflex.Dom.GadtApi.WebSocket (TaggedRequest (..), TaggedResponse, mkTaggedResponse)

import System.FilePath (takeBaseName)

import Server.Config (Config (..))
import Server.DB (deleteLatestSnapshot, saveCustomCard, saveGame, saveGameEvents, saveSnapshot)
import Server.Dispatch (processCommand)
import Server.Types
  ( Client (..)
  , ConnectedSocket (..)
  , GameState (..)
  , ServerState (..)
  , addClient
  , appendHistoryEntry
  , clientExists
  , removeClient
  )

import Api.Reflex
  ( ClientInfo (..)
  , ErrorMessage (..)
  , ErrorType (..)
  , GameView (..)
  , ServerPush (..)
  , WsMessage (..)
  )
import Api.Request qualified as Req
import Api.Types
  ( ClientRole (..)
  , LogEntry (..)
  , LogPayload (..)
  , LogSender (..)
  , StateUpdate (..)
  )

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
            (existing{conns = existing.conns ++ [connectedSocket]}, False)
          Nothing ->
            (Client finalClientId newName RoleUnassigned [connectedSocket], True)
    let s' = addClient c s
    return (s', (c, isNew))

  -- Send Welcome
  (msgs, _) <-
    readMVar state >>= \s -> do
      let view = makeGameView s
      let ph = s.gameState.phase
      return ([PushWelcome finalClientId view s.gameState.history ph], s.clients)

  forM_ msgs $ \msg -> sendTextData conn (encode $ WsMsgPush msg)

  if isNew
    then T.putStrLn $ "Client Joined: " <> (client.name)
    else T.putStrLn $ "Client reconnected: " <> (client.name)

  -- Broadcast update to others because activeClients changed
  readMVar state >>= \s -> do
    let view = makeGameView s
    broadcastReflex (PushUpdate view Nothing) s.clients

  withPingThread conn 30 (return ()) $ do
    flip finally (disconnect finalClientId socketId state) $ do
      talk client connectedSocket state

disconnect :: UUID -> UUID -> MVar ServerState -> IO ()
disconnect clientId socketId state = do
  modifyMVar_ state $ \s -> do
    return $ removeClient clientId socketId s
  T.putStrLn $ "Client disconnected: " <> T.pack (show clientId)

  -- Broadcast updated client list
  s <- readMVar state
  let view = makeGameView s
  broadcastReflex (PushUpdate view Nothing) s.clients

broadcastReflex :: ServerPush -> Map.Map UUID Client -> IO ()
broadcastReflex msg clients = do
  let msgBytes = encode (WsMsgPush msg)
  T.putStrLn $ "Broadcasting: " <> T.pack (take 100 $ BSL.unpack msgBytes)
  forM_ (Map.elems clients) $ \client ->
    forM_ (client.conns) $ \socket -> do
      result <- try (sendTextData (socket.conn) msgBytes) :: IO (Either ConnectionException ())
      case result of
        Left err -> T.putStrLn $ "Send failed: " <> T.pack (show err)
        Right _ -> return ()

talk :: Client -> ConnectedSocket -> MVar ServerState -> IO ()
talk client socket state = forever $ do
  msgBytes <- receiveData (socket.conn)
  case decode msgBytes of
    Just taggedReq@(TaggedRequest _ _) -> do
      res <-
        try (mkTaggedResponse taggedReq $ \r -> handleGameCommand client state r)
          :: IO (Either SomeException (Either String TaggedResponse))
      case res of
        Left ex -> do
          T.putStrLn $ "CRITICAL ERROR in handleGameCommand: " <> T.pack (show ex)
          sendTextData
            (socket.conn)
            (encode $ WsMsgPush $ PushError (ErrorMessage (T.pack (show ex)) ErrorSystem))
        Right (Right resp) -> sendTextData (socket.conn) (encode $ WsMsgResponse resp)
        Right (Left err) ->
          sendTextData
            (socket.conn)
            (encode $ WsMsgPush $ PushError (ErrorMessage (T.pack err) ErrorSystem))
    Nothing ->
      sendTextData
        (socket.conn)
        (encode $ WsMsgPush $ PushError (ErrorMessage "Invalid message" ErrorValidation))

getClientInfoMap :: Map.Map UUID Client -> Map.Map UUID ClientInfo
getClientInfoMap = Map.map (\c -> ClientInfo{name = c.name, role = c.role})

makeGameView :: ServerState -> GameView
makeGameView s =
  GameView
    { actors = s.gameState.actors
    , mapMode = s.gameState.mapMode
    , activeClients = getClientInfoMap s.clients
    , canUndoPhase = not (null s.checkpoints)
    , playMode = s.gameState.playMode
    , worldState = s.gameState.worldState
    }

handleJoin :: Client -> Text -> MVar ServerState -> IO (Either Text UUID)
handleJoin client name state = do
  modifyMVar_ state $ \s -> do
    pure (s & #clients . at client.id . _Just . #name .~ name)
  T.putStrLn $ "Client renamed: " <> name

  -- Broadcast updated client list
  s <- readMVar state
  let view = makeGameView s
  broadcastReflex (PushUpdate view Nothing) s.clients

  pure (Right client.id)

handleSetRole :: Client -> ClientRole -> MVar ServerState -> IO (Either Text ())
handleSetRole client role state = do
  modifyMVar_ state $ \s -> do
    pure (s & #clients . at client.id . _Just . #role .~ role)
  T.putStrLn $ "Client " <> client.name <> " set role to: " <> T.pack (show role)

  -- Broadcast updated client list
  s <- readMVar state
  let view = makeGameView s
  broadcastReflex (PushUpdate view Nothing) s.clients

  pure (Right ())

checkPermission :: ClientRole -> Req.ApiRequest a -> Bool
checkPermission role cmd =
  case role of
    RoleGM -> True
    RoleUnassigned ->
      case cmd of
        Req.Join _ -> True
        Req.SetRole _ -> True
        _ -> False
    RolePlayer actorId ->
      case cmd of
        Req.Join _ -> True
        Req.SetRole _ -> True
        Req.SendChat maybeAid _ -> maybeAid == Just actorId
        Req.DrawCards aid -> aid == actorId
        Req.Defend aid _ -> aid == actorId
        Req.PlanMove aid _ _ -> aid == actorId
        Req.PlanRankMove aid _ _ -> aid == actorId
        Req.PlanAction aid _ _ -> aid == actorId
        Req.PlanNarrative aid _ _ -> aid == actorId
        Req.CancelPlan aid -> aid == actorId
        Req.EndDefense aid -> aid == actorId
        Req.Reshuffle aid -> aid == actorId
        Req.AddStatus aid _ _ -> aid == actorId
        Req.DestroyStatus aid _ _ -> aid == actorId
        Req.AddConsequence aid _ _ -> aid == actorId
        Req.DestroyConsequence aid _ -> aid == actorId
        Req.DiscardCards aid _ -> aid == actorId
        Req.ReturnToDeck aid _ -> aid == actorId
        Req.Pass aid -> aid == actorId
        Req.PlanExplorationIntent aid _ -> aid == actorId
        Req.SetVigilanceDial aid _ -> aid == actorId
        Req.SelectReadiedCard aid _ -> aid == actorId
        Req.CommitVigilance aid -> aid == actorId
        Req.AbortExplorationChallenge _ -> True
        Req.SetMapMode _ -> False
        Req.StartResolution -> False
        Req.EndRound -> False
        Req.UndoPhase -> False
        Req.SaveCustomCard _ _ -> False
        Req.AdvanceTimeManual _ -> False
        Req.DrawClockManual _ -> False
        Req.TransitionMode _ -> False

handleGameCommand :: Client -> MVar ServerState -> Req.ApiRequest a -> IO a
handleGameCommand client state cmd = do
  sCurrent <- readMVar state
  let mClient = Map.lookup (client.id) (sCurrent.clients)
      clientRole = maybe RoleUnassigned (.role) mClient

  if not (checkPermission clientRole cmd)
    then do
      T.putStrLn $ "Permission denied for client " <> client.name <> " attempting GADT command."
      case cmd of
        Req.Join _ -> pure (Left "Permission denied")
        Req.SetRole _ -> pure (Left "Permission denied")
        Req.SendChat _ _ -> pure ()
        Req.DrawCards _ -> pure (Left "Permission denied")
        Req.Defend _ _ -> pure (Left "Permission denied")
        Req.PlanMove{} -> pure (Left "Permission denied")
        Req.PlanRankMove{} -> pure (Left "Permission denied")
        Req.SetMapMode _ -> pure (Left "Permission denied")
        Req.PlanAction{} -> pure (Left "Permission denied")
        Req.PlanNarrative{} -> pure (Left "Permission denied")
        Req.CancelPlan _ -> pure (Left "Permission denied")
        Req.StartResolution -> pure (Left "Permission denied")
        Req.EndDefense _ -> pure (Left "Permission denied")
        Req.Reshuffle _ -> pure (Left "Permission denied")
        Req.AddStatus{} -> pure (Left "Permission denied")
        Req.DestroyStatus{} -> pure (Left "Permission denied")
        Req.AddConsequence{} -> pure (Left "Permission denied")
        Req.DestroyConsequence _ _ -> pure (Left "Permission denied")
        Req.DiscardCards _ _ -> pure (Left "Permission denied")
        Req.ReturnToDeck _ _ -> pure (Left "Permission denied")
        Req.EndRound -> pure (Left "Permission denied")
        Req.UndoPhase -> pure (Left "Permission denied")
        Req.Pass _ -> pure (Left "Permission denied")
        Req.SaveCustomCard _ _ -> pure (Left "Permission denied")
        Req.PlanExplorationIntent{} -> pure (Left "Permission denied")
        Req.SetVigilanceDial{} -> pure (Left "Permission denied")
        Req.SelectReadiedCard{} -> pure (Left "Permission denied")
        Req.CommitVigilance{} -> pure (Left "Permission denied")
        Req.AbortExplorationChallenge{} -> pure (Left "Permission denied")
        Req.AdvanceTimeManual{} -> pure (Left "Permission denied")
        Req.DrawClockManual{} -> pure (Left "Permission denied")
        Req.TransitionMode{} -> pure (Left "Permission denied")
    else case cmd of
      Req.Join name -> handleJoin client name state
      Req.SetRole role -> handleSetRole client role state
      Req.SaveCustomCard cardVal file -> do
        s <- readMVar state
        let backend = s.dbPool
            author = client.name
        case fromJSON cardVal of
          Success card -> saveCustomCard backend card file author
          Error err -> return $ Left $ T.pack err
      Req.UndoPhase -> do
        (ret, mRestoredState) <- modifyMVar state $ \s -> do
          case s.checkpoints of
            [] -> return (s, (Left "No phase checkpoint to undo.", Nothing))
            ((restoredGame :: GameState) : remainingCheckpoints) -> do
              let backend = s.dbPool
                  gId = s.gameId
                  scenario = T.pack (takeBaseName s.config.scenarioFile)
              -- Delete latest snapshot from DB
              deleteLatestSnapshot backend gId

              -- Append undo notification log
              let (logId, newRng) = uniform s.rng
                  entry =
                    LogEntry
                      { id = logId
                      , sender = SenderGM
                      , payload = LogInfo "GM rewound phase transition."
                      }
                  finalGame = appendHistoryEntry entry restoredGame

              -- Persist restored game to DB
              saveGame backend gId scenario finalGame

              let s' = s{gameState = finalGame, checkpoints = remainingCheckpoints, rng = newRng}
              let stateUpdates = [StateUpdate aid a | (aid, a) <- Map.toList (finalGame :: GameState).actors]
              return (s', (Right stateUpdates, Just finalGame))

        case mRestoredState of
          Nothing -> pure ()
          Just (restoredGame :: GameState) -> do
            s <- readMVar state
            let view = makeGameView s
            broadcastReflex (PushResetLogs restoredGame.history) s.clients
            broadcastReflex (PushUpdate view (Just restoredGame.phase)) s.clients

        pure ret
      _ -> do
        (ret, newLog) <- modifyMVar state $ \s -> do
          let game = s.gameState
          let rng = s.rng
          let ((newGame, ret, events, newLogs), newRng) = runState (processCommand cmd game) rng

          let isPhaseTransition = game.phase /= newGame.phase
              newCheckpoints =
                if isPhaseTransition
                  then take 20 (game : s.checkpoints)
                  else s.checkpoints

          let s' = s{gameState = newGame, rng = newRng, checkpoints = newCheckpoints}

          -- Persist events and latest game state
          let backend = s.dbPool
              gId = s.gameId
              scenario = T.pack (takeBaseName s.config.scenarioFile)

          when isPhaseTransition $
            saveSnapshot backend gId game

          saveGameEvents backend gId newGame.roundNumber events newLogs
          saveGame backend gId scenario newGame

          return (s', (ret, newLogs))

        -- Broadcast updates to others
        readMVar state >>= \s -> do
          let view = makeGameView s
          broadcastReflex (PushUpdate view (Just s.gameState.phase)) s.clients

        -- Broadcast new logs
        T.putStrLn $ "Processing " <> T.pack (show (length newLog)) <> " new logs."
        unless (null newLog) $ do
          readMVar state >>= \s -> broadcastReflex (PushNewLogs newLog) s.clients

        pure ret
