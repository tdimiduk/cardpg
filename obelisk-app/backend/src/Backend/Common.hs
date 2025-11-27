module Backend.Common where

import Control.Monad.IO.Class
import Data.Text (Text, strip)
import System.Directory

import Obelisk.ExecutableConfig.Lookup qualified as Cfg
import Obelisk.Configs

import Database.Beam.Postgres qualified as Pg

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
