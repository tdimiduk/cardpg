{-# LANGUAGE UndecidableInstances #-}
-- Defining Beam orphans that are backend-only
{-# options_ghc -fno-warn-orphans #-}

module Backend.Database.Schema where

import Data.Proxy (Proxy(..))
import Data.Text (Text)
import Text.Read (readEither)

import Database.Beam
import Database.Beam.AutoMigrate qualified as BA
import Database.Beam.Backend.SQL
import Database.Beam.Postgres
import Database.Beam.Postgres.Syntax
import Database.PostgreSQL.Simple.FromField
import Database.PostgreSQL.Simple.ToField

import Common.Card.Common

import Backend.Database.Types

db :: DatabaseSettings Postgres Db
db = defaultDbSettings

data Db f = Db
  { _tableConsequenceCard :: f (TableEntity ConsequenceCardT)
  , _tableGSheetsRef :: f (TableEntity GSheetsReferenceT)
  }
  deriving stock Generic
  deriving anyclass (Database be)

newtype ReadShowColumn a = ReadShowColumn { unReadShowColumn :: a }

instance Show a => HasSqlValueSyntax PgValueSyntax (ReadShowColumn a) where
  sqlValueSyntax (ReadShowColumn x) = sqlValueSyntax $ show x
instance (Typeable a, Read a) => FromField (ReadShowColumn a) where
  fromField f d = fromField @String f d >>=
    either (returnError ConversionFailed f) (pure . ReadShowColumn) . readEither
instance Show a => ToField (ReadShowColumn a) where
  toField a = toField (show $ unReadShowColumn a)
instance BA.HasColumnType (ReadShowColumn a) where
  defaultColumnType _ = BA.defaultColumnType (Proxy @Text)

instance HasSqlValueSyntax PgValueSyntax CardType where
  sqlValueSyntax = sqlValueSyntax . ReadShowColumn
instance FromField CardType where
  fromField f d = unReadShowColumn <$> fromField f d
instance FromBackendRow Postgres CardType
instance HasSqlEqualityCheck Postgres CardType
instance BA.HasColumnType CardType where
  defaultColumnType _ = BA.defaultColumnType $ Proxy @(ReadShowColumn CardType)
