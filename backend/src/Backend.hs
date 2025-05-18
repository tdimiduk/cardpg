module Backend where

import Control.Monad.IO.Class
import System.Directory

import Gargoyle.PostgreSQL.Connect
import Obelisk.Backend

import Common.Route

import Backend.Database.Migrate
import Backend.GSheets.Fetch (syncCards)

data BackendEnv = BackendEnv
  { _dbPath :: String }

getBackendEnv :: IO BackendEnv
getBackendEnv = do
  dbConfigExists <- liftIO $ doesFileExist "config/backend/db"
  let dbPath = if dbConfigExists then "config/backend/db" else "db"
  pure $ BackendEnv
    { _dbPath = dbPath }

backend :: Backend BackendRoute FrontendRoute
backend = Backend
  { _backend_run = \serve -> do
      env <- getBackendEnv
      withDb ( _dbPath env ) $ \dbConnPool -> do
        migration dbConnPool
        serve $ const $ pure ()


  , _backend_routeEncoder = fullRouteEncoder
  }
