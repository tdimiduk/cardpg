{-# LANGUAGE DeriveAnyClass #-}
{-# LANGUAGE FieldSelectors #-}
{-# LANGUAGE PartialTypeSignatures #-}
{-# LANGUAGE TypeFamilies #-}

module CardPG.Server.DB where

import Data.Aeson (FromJSON, Result (..), ToJSON, Value (..), fromJSON, toJSON)
import Data.Pool (Pool, withResource)
import Data.Text (Text)
import Data.Text.Encoding (encodeUtf8)
import Data.Time (UTCTime, getCurrentTime)
import Database.Beam
import Database.Beam.AutoMigrate (AnnotatedDatabaseSettings, defaultAnnotatedDbSettings)
import Database.Beam.AutoMigrate qualified as BA
import Database.Beam.Backend.SQL.SQL92 (IsSql92DataTypeSyntax (..))
import Database.Beam.Migrate
import Database.Beam.Postgres
import Database.PostgreSQL.Simple qualified as Pg
import GHC.Generics (Generic)

import CardPG.Server.Types (GameState)

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

-- | The Database
data CardPGDB f = CardPGDB
  { games :: f (TableEntity GameT)
  }
  deriving (Generic, Database be)

cardpgDb :: DatabaseSettings be CardPGDB
cardpgDb = defaultDbSettings

annotatedDb :: AnnotatedDatabaseSettings Postgres CardPGDB
annotatedDb = defaultAnnotatedDbSettings cardpgDb

-- | Helper Functions
initDB :: Pool Pg.Connection -> IO ()
initDB pool = do
  withResource pool $ \conn ->
    Pg.withTransaction conn $
      BA.tryRunMigrationsWithEditUpdate annotatedDb conn

saveGame :: Pool Pg.Connection -> Text -> GameState -> IO ()
saveGame pool gId gs = do
  now <- getCurrentTime
  let game = Game (gId) ("Active") (PgJSONB (toJSON gs)) (now)

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

loadGame :: Pool Pg.Connection -> Text -> IO (Maybe GameState)
loadGame pool gId = do
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
