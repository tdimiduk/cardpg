{-# LANGUAGE UndecidableInstances #-}

module Backend.Database.Schema where

import Database.Beam
import Database.Beam.Postgres

import Backend.Database.Types

db :: DatabaseSettings Postgres Db
db = defaultDbSettings

data Db f = Db
  { _tableConsequenceCard :: f (TableEntity ConsequenceCardT)
  , _tableGSheetsRef :: f (TableEntity GSheetsReferenceT)
  }
  deriving stock Generic
  deriving anyclass (Database be)
