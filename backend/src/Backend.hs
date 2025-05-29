module Backend where

import Control.Monad.IO.Class
import Data.Text (Text, strip, unpack)
import System.Directory

import Gargoyle.PostgreSQL.Connect
import Obelisk.Backend
import Obelisk.Configs
import Obelisk.ExecutableConfig.Lookup qualified as Cfg

import Common.Route

import Backend.Database.Migrate
import Backend.GSheets.Fetch (syncCards)

data BackendEnv = BackendEnv
  { _dbPath :: String
  , _pythonScriptPath :: Maybe Text
  }

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

backend :: Backend BackendRoute FrontendRoute
backend = Backend
  { _backend_run = \serve -> do
      env <- getBackendEnv
      withDb ( _dbPath env ) $ \dbConnPool -> do
        migration dbConnPool
        syncCards $ unpack <$> _pythonScriptPath env
        serve $ const $ pure ()


  , _backend_routeEncoder = fullRouteEncoder
  }
