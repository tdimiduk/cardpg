module Backend.Database.Migrate
  ( migration
  )
where


import Data.Pool (Pool, withResource)

import Database.Beam
import Database.Beam.AutoMigrate qualified as BA
import Database.Beam.Postgres
import Database.PostgreSQL.Simple (withTransaction)

import Backend.Database.Schema

migration :: Pool Connection -> IO ()
migration pool = withResource pool $ \conn -> do
  autoMigration conn

autoMigration :: Connection -> IO ()
autoMigration conn = BA.tryRunMigrationsWithEditUpdate annotatedDb conn

annotatedDb :: BA.AnnotatedDatabaseSettings Postgres Db
annotatedDb = BA.defaultAnnotatedDbSettings defaultDbSettings
