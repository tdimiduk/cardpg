module Backend.Database.Migrate
  ( migration
  )
where

import Data.Text (Text)

import Data.Pool (Pool, withResource)

import Database.Beam
import Database.Beam.AutoMigrate qualified as BA
import Database.Beam.Postgres

import Backend.Database.Schema
import Backend.Database.Types

migration :: Pool Connection -> IO ()
migration pool = withResource pool $ \conn -> do
  autoMigration conn

autoMigration :: Connection -> IO ()
autoMigration conn = BA.tryRunMigrationsWithEditUpdate annotatedDb conn

annotatedDb :: BA.AnnotatedDatabaseSettings Postgres Db
annotatedDb = BA.defaultAnnotatedDbSettings defaultDbSettings
  `withDbModification` dbModification
    { _tableGSheetsRef = mkUnique [BA.U (_name :: GSheetsReferenceT f -> C f Text), BA.U _deckCardType]
    }

mkUnique ::
  Beamable tbl =>
  [BA.UniqueConstraint tbl] ->
  EntityModification
    (BA.AnnotatedDatabaseEntity be db)
    be
    (TableEntity tbl)
mkUnique columns = BA.annotateTableFields tableModification <> BA.uniqueConstraintOn columns
