module Backend where

import Control.Monad (forever)
import Control.Monad.IO.Class
import Data.Aeson as Aeson
import Data.Pool (withResource)
import Snap.Core
import Network.WebSockets.Snap qualified as WS
import Network.WebSockets as WS

import Gargoyle.PostgreSQL.Connect (withDb)
import Obelisk.Backend
import Obelisk.Route hiding (decode, encode)
import Reflex.Dom.GadtApi.WebSocket

import Common.Route

import Backend.Api qualified as Api
import Backend.Common
import Backend.Database.Migrate

backend :: Backend BackendRoute FrontendRoute
backend = Backend
  { _backend_run = \serve -> do
      env <- getBackendEnv
      withDb ( _dbPath env ) $ \dbConnPool -> do
        migration dbConnPool
        serve $ \case
          BackendRoute_WebSocket :/ () -> WS.runWebSocketsSnap $ \pc -> do
            wsConn <- WS.acceptRequest pc
            _ <- forever $ do
              m <- wsReceiveAndDecode wsConn
              case m of
                Right req -> do
                  r <- liftIO $
                    withResource dbConnPool $ \dbConn ->
                      mkTaggedResponse req $ Api.handle dbConn env
                  case r of
                    Left err -> error err
                    Right rsp ->
                      WS.sendDataMessage wsConn $ WS.Text (Aeson.encode rsp) Nothing
                Left err -> error err
            pure ()
          BackendRoute_Missing :/ _ -> do
            modifyResponse $ setResponseStatus 404 "Not Found"
            writeText "404 Nothing to see here."

  , _backend_routeEncoder = fullRouteEncoder
  }

wsReceiveAndDecode :: FromJSON a => Connection -> IO (Either String a)
wsReceiveAndDecode conn = do
  dm <- WS.receiveDataMessage conn
  pure $ eitherDecode $ case dm of
        WS.Text v _ -> v
        WS.Binary v -> v
