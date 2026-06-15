{-# LANGUAGE DeriveAnyClass #-}
{-# LANGUAGE FieldSelectors #-}
{-# LANGUAGE TypeFamilies #-}

module Server.DB where

import Data.Aeson (Result (..), Value (..), fromJSON, toJSON)
import Data.IORef (modifyIORef', newIORef, readIORef)
import Data.Map qualified as Map
import Data.Pool (defaultPoolConfig, newPool, withResource)
import Data.Text (Text)
import Data.Text qualified as T
import Data.Text.Encoding (encodeUtf8)
import Data.Time (UTCTime, getCurrentTime)
import Database.Beam
import Database.Beam.AutoMigrate (AnnotatedDatabaseSettings, defaultAnnotatedDbSettings)
import Database.Beam.AutoMigrate qualified as BA
import Database.Beam.Postgres
import Database.PostgreSQL.Simple qualified as Pg

import Core.Card (CustomCard, customCardCategoryText, customCardIdText, customCardNameText)
import Server.Config (DBConfig (..))
import Server.Types (GameState, StorageBackend (..))

import Gargoyle.PostgreSQL.Connect (withDb)

-- | The Game Table
data GameT f = Game
  { gameId :: C f Text
  , gameStatus :: C f Text -- "Active", "Finished", etc.
  , gameState :: C f (PgJSONB Value) -- Store full JSON blob for now
  , gameUpdatedAt :: C f UTCTime
  }
  deriving (Generic, Beamable)

type Game = GameT Identity
type GameId = PrimaryKey GameT Identity

instance Table GameT where
  data PrimaryKey GameT f = GameId (C f Text)
    deriving (Generic, Beamable)
  primaryKey (Game gId _ _ _) = GameId gId

-- | The Custom Card Table
data CustomCardT f = CustomCard
  { customCardId :: C f Text -- e.g. "Sunburn" or "action-strike"
  , customCardCategory :: C f Text -- "core", "items", "monsters", etc.
  , customCardName :: C f Text
  , customCardData :: C f (PgJSONB Value) -- Serialized CustomCard JSON
  , customCardSourceFile :: C f Text -- e.g. "pc/vallhach.yaml"
  , customCardAuthor :: C f Text -- E.g. "Jeff" or "GM"
  , customCardUpdatedAt :: C f UTCTime
  }
  deriving (Generic, Beamable)

type CustomCardRecord = CustomCardT Identity
type CustomCardId = PrimaryKey CustomCardT Identity

instance Table CustomCardT where
  data PrimaryKey CustomCardT f = CustomCardId (C f Text)
    deriving (Generic, Beamable)
  primaryKey (CustomCard cId _ _ _ _ _ _) = CustomCardId cId

-- | The Database
data CardPGDB f = CardPGDB
  { games :: f (TableEntity GameT)
  , customCards :: f (TableEntity CustomCardT)
  }
  deriving stock (Generic)
  deriving anyclass (Database be)

cardpgDb :: DatabaseSettings be CardPGDB
cardpgDb = defaultDbSettings

annotatedDb :: AnnotatedDatabaseSettings Postgres CardPGDB
annotatedDb = defaultAnnotatedDbSettings cardpgDb

-- | Helper Functions
initDB :: DBConfig -> IO StorageBackend
initDB cfg = do
  let passStr = if null cfg.dbPass then "" else " password=" <> cfg.dbPass
      connStr =
        "host="
          <> cfg.dbHost
          <> " user="
          <> cfg.dbUser
          <> passStr
          <> " dbname="
          <> cfg.dbName
  pool <- newPool $ defaultPoolConfig (connectPostgreSQL (encodeUtf8 $ T.pack connStr)) close 10 10
  withResource pool $ \conn ->
    Pg.withTransaction conn $
      BA.tryRunMigrationsWithEditUpdate annotatedDb conn
  pure $ PostgresBackend pool

withGargoyleDB :: FilePath -> (StorageBackend -> IO a) -> IO a
withGargoyleDB dbPath f = withDb dbPath $ \pool -> do
  withResource pool $ \conn ->
    Pg.withTransaction conn $
      BA.tryRunMigrationsWithEditUpdate annotatedDb conn
  f $ PostgresBackend pool

initInMemoryDB :: IO StorageBackend
initInMemoryDB = InMemoryBackend <$> newIORef Map.empty

saveGame :: StorageBackend -> Text -> GameState -> IO ()
saveGame (InMemoryBackend ref) gId gs = do
  modifyIORef' ref (Map.insert gId gs)
saveGame (PostgresBackend pool) gId gs = do
  now <- getCurrentTime
  let game = Game gId "Active" (PgJSONB (toJSON gs)) now

  withResource pool $ \conn -> do
    -- Explicit Check for Upsert
    existing <-
      runBeamPostgres conn $
        runSelectReturningOne $
          select $
            filter_ (\g -> gameId g ==. val_ gId) (all_ (games cardpgDb))

    case existing of
      Just _ -> do
        runBeamPostgres conn $
          runUpdate $
            update
              (games cardpgDb)
              ( \g ->
                  mconcat
                    [ gameState g <-. val_ (PgJSONB (toJSON gs))
                    , gameUpdatedAt g <-. val_ now
                    ]
              )
              (\g -> gameId g ==. val_ gId)
      Nothing -> do
        runBeamPostgres conn $ runInsert $ insert (games cardpgDb) (insertValues [game])

loadGame :: StorageBackend -> Text -> IO (Maybe GameState)
loadGame (InMemoryBackend ref) gId = do
  m <- readIORef ref
  return $ Map.lookup gId m
loadGame (PostgresBackend pool) gId = do
  withResource pool $ \conn -> do
    res <-
      runBeamPostgres conn $
        runSelectReturningOne $
          select $
            filter_ (\g -> gameId g ==. val_ gId) (all_ (games cardpgDb))
    case res of
      Nothing -> return Nothing
      Just g -> do
        let (PgJSONB val) = gameState g
        case fromJSON val of
          Error e -> do
            putStrLn $ "Failed to decode game state: " ++ e
            return Nothing
          Success s -> return (Just s)

saveCustomCard :: StorageBackend -> CustomCard -> Text -> Text -> IO (Either Text ())
saveCustomCard (InMemoryBackend _) _ _ _ = do
  return $ Right ()
saveCustomCard (PostgresBackend pool) card sourceFile author = do
  now <- getCurrentTime
  let cId = customCardIdText card
      category = customCardCategoryText card
      name = customCardNameText card
      dbRecord = CustomCard cId category name (PgJSONB (toJSON card)) sourceFile author now

  withResource pool $ \conn -> do
    existing <-
      runBeamPostgres conn $
        runSelectReturningOne $
          select $
            filter_ (\c -> customCardId c ==. val_ cId) (all_ (customCards cardpgDb))

    case existing of
      Just _ -> do
        runBeamPostgres conn $
          runUpdate $
            update
              (customCards cardpgDb)
              ( \c ->
                  mconcat
                    [ customCardCategory c <-. val_ category
                    , customCardName c <-. val_ name
                    , customCardData c <-. val_ (PgJSONB (toJSON card))
                    , customCardSourceFile c <-. val_ sourceFile
                    , customCardAuthor c <-. val_ author
                    , customCardUpdatedAt c <-. val_ now
                    ]
              )
              (\c -> customCardId c ==. val_ cId)
      Nothing -> do
        runBeamPostgres conn $ runInsert $ insert (customCards cardpgDb) (insertValues [dbRecord])

    return $ Right ()
