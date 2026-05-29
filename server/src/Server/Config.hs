module Server.Config where

import Data.Char (toLower)
import Data.Maybe (fromMaybe)
import System.Environment (lookupEnv)
import System.IO (hPutStrLn, stderr)

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
  , cardsDir :: FilePath
  , scenarioFile :: FilePath
  , savedGameFile :: Maybe FilePath
  , useInMemoryDB :: Bool
  , useGargoyle :: Bool
  , seed :: Maybe Int
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
  let port = maybe 3004 read portStr

  -- File Config
  cDir <- fromMaybe "data/cards" <$> lookupEnv "CARDPG_CARDS_DIR"
  sFile <- fromMaybe "data/scenarios/starter.yaml" <$> lookupEnv "CARDPG_SCENARIO_FILE"
  savedGameFileVal <- lookupEnv "CARDPG_SAVED_GAME_FILE"

  -- Feature Flags
  inMem <- lookupEnv "CARDPG_USE_IN_MEMORY_DB"
  let useInMem = case inMem of
        Just s | map toLower s == "true" -> True
        _ -> False

  gargoyle <- lookupEnv "CARDPG_USE_GARGOYLE"
  let useGargoyleVal = case gargoyle of
        Just s | map toLower s == "true" -> True
        _ -> False

  hPutStrLn stderr $ "Config Loaded:"
  hPutStrLn stderr $ "  PORT: " ++ show port
  hPutStrLn stderr $ "  USE_IN_MEMORY_DB: " ++ show useInMem ++ " (env: " ++ show inMem ++ ")"
  hPutStrLn stderr $ "  USE_GARGOYLE: " ++ show useGargoyleVal ++ " (env: " ++ show gargoyle ++ ")"
  hPutStrLn stderr $ "  DB_HOST: " ++ dbConfig.dbHost
  hPutStrLn stderr $ "  SAVED_GAME_FILE: " ++ show savedGameFileVal

  -- Seed Config
  seedStr <- lookupEnv "CARDPG_SEED"
  let seedVal = read <$> seedStr

  pure
    Config
      { dbConfig = dbConfig
      , serverPort = port
      , cardsDir = cDir
      , scenarioFile = sFile
      , savedGameFile = savedGameFileVal
      , useInMemoryDB = useInMem
      , useGargoyle = useGargoyleVal
      , seed = seedVal
      }
