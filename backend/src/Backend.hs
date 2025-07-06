module Backend where

import Control.Monad (forever)
import Control.Monad.IO.Class
import Data.Aeson as Aeson
import Data.Pool (withResource)
import Data.Text (Text, strip, unpack)
import Snap.Core
import System.Directory
import Network.WebSockets.Snap qualified as WS
import Network.WebSockets as WS

import Gargoyle.PostgreSQL.Connect (withDb)
import Obelisk.Backend
import Obelisk.Configs
import Obelisk.ExecutableConfig.Lookup qualified as Cfg
import Obelisk.Route hiding (decode, encode)
import Reflex.Dom.GadtApi.WebSocket

import Database.Beam.Postgres qualified as Pg

import Common.Route

import Backend.Api qualified as Api
import Backend.Database.Migrate
import Backend.Database.Write
import qualified Backend.GSheets.Fetch as Fetch

data BackendEnv = BackendEnv
  { _dbPath :: String
  , _pythonScriptPath :: Maybe Text
  }

runBeam :: Pg.Connection -> Pg.Pg a -> IO a
runBeam = Pg.runBeamPostgres

getBackendEnv :: IO BackendEnv
getBackendEnv = do
  configs <- Cfg.getConfigs
  runConfigsT configs $ do
    scriptPath <- getTextConfig "backend/pythonScriptPath"
    dbConfigExists <- liftIO $ doesFileExist "config/backend/db"
    let dbPath = if dbConfigExists then "config/backend/db" else "db"
    pure $ BackendEnv
      { _dbPath = dbPath
      , _pythonScriptPath = strip <$> scriptPath
      }

fetchGSheets :: Bool
fetchGSheets = False

backend :: Backend BackendRoute FrontendRoute
backend = Backend
  { _backend_run = \serve -> do
      env <- getBackendEnv
      withDb ( _dbPath env ) $ \dbConnPool -> do
        migration dbConnPool
        if fetchGSheets
          then do
            fetched <- Fetch.cards $ unpack <$> _pythonScriptPath env
            case fetched of
              Left err -> print err
              Right c -> withResource dbConnPool $ \conn -> runBeam conn $ replaceConsequenceCards "general-wound" c
          else pure ()
        serve $ \case
          BackendRoute_WebSocket :/ () -> WS.runWebSocketsSnap $ \pc -> do
            wsConn <- WS.acceptRequest pc
            _ <- forever $ do
              m <- wsReceiveAndDecode wsConn
              case m of
                Right req -> do
                  r <- liftIO $
                    withResource dbConnPool $ \dbConn ->
                      mkTaggedResponse req $ Api.handle dbConn
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
