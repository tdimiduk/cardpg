module CardPG.Server.Config where

import Data.Maybe (fromMaybe)
import Data.Text (Text)
import Data.Text qualified as T
import System.Environment (lookupEnv)

data DBConfig = DBConfig
  { dbHost :: String
  , dbUser :: String
  , dbPass :: String
  , dbName :: String
  }
  deriving (Show, Eq)

data Config = Config
  { dbConfig :: DBConfig
  , serverPort :: Int
  , cardsFile :: FilePath
  , scenarioFile :: FilePath
  }
  deriving (Show, Eq)

loadDbConfig :: IO DBConfig
loadDbConfig = do
  -- DB Config
  host <- fromMaybe "localhost" <$> lookupEnv "CARDPG_DB_HOST"
  user <- fromMaybe "cardpg" <$> lookupEnv "CARDPG_DB_USER"
  pass <- fromMaybe "cardpg" <$> lookupEnv "CARDPG_DB_PASS"
  name <- fromMaybe "cardpg" <$> lookupEnv "CARDPG_DB_NAME"
  pure DBConfig{dbHost = host, dbUser = user, dbPass = pass, dbName = name}

loadConfig :: IO Config
loadConfig = do
  dbConfig <- loadDbConfig

  -- Server Config
  portStr <- lookupEnv "PORT"
  let port = fromMaybe 8080 (read <$> portStr)

  -- File Config
  cFile <- fromMaybe "vtt-react/src/data/generated_cards.json" <$> lookupEnv "CARDPG_CARDS_FILE"
  sFile <- fromMaybe "data/scenarios/starter.yaml" <$> lookupEnv "CARDPG_SCENARIO_FILE"

  pure
    Config
      { dbConfig = dbConfig
      , serverPort = port
      , cardsFile = cFile
      , scenarioFile = sFile
      }
