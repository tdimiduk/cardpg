{-# LANGUAGE DeriveAnyClass #-}
{-# LANGUAGE FieldSelectors #-}
{-# LANGUAGE TypeFamilies #-}

module Server.DB.Schema
  ( GameT (..)
  , Game
  , GameId
  , CustomCardT (..)
  , CustomCardRecord
  , CustomCardId
  , GameEventRecordT (..)
  , GameEventRecord
  , GameEventRecordId
  , CardPGDB (..)
  , cardpgDb
  , annotatedDb
  , SqlSerial (..)
  , PgJSONB
  ) where

import Data.Aeson (Value)
import Data.Int (Int32)
import Data.Text (Text)
import Data.Time (UTCTime)
import Database.Beam
import Database.Beam.AutoMigrate (AnnotatedDatabaseSettings, defaultAnnotatedDbSettings)
import Database.Beam.Backend.SQL.Types (SqlSerial (..))
import Database.Beam.Postgres (PgJSONB, Postgres)

-- | The Game Table
data GameT f = Game
  { gameId :: C f Text
  , scenarioName :: C f Text
  , gameStatus :: C f Text
  , actorNames :: C f (PgJSONB [Text])
  , currentRound :: C f Int32
  , gameState :: C f (PgJSONB Value)
  , gameStartedAt :: C f UTCTime
  , gameUpdatedAt :: C f UTCTime
  }
  deriving (Generic, Beamable)

type Game = GameT Identity
type GameId = PrimaryKey GameT Identity

instance Table GameT where
  data PrimaryKey GameT f = GameId (C f Text)
    deriving (Generic, Beamable)
  primaryKey g = GameId g.gameId

-- | The Custom Card Table
data CustomCardT f = CustomCard
  { customCardId :: C f Text
  , customCardCategory :: C f Text
  , customCardName :: C f Text
  , customCardData :: C f (PgJSONB Value)
  , customCardSourceFile :: C f Text
  , customCardAuthor :: C f Text
  , customCardUpdatedAt :: C f UTCTime
  }
  deriving (Generic, Beamable)

type CustomCardRecord = CustomCardT Identity
type CustomCardId = PrimaryKey CustomCardT Identity

instance Table CustomCardT where
  data PrimaryKey CustomCardT f = CustomCardId (C f Text)
    deriving (Generic, Beamable)
  primaryKey c = CustomCardId c.customCardId

-- | The Append-Only Game Event Table
data GameEventRecordT f = GameEventRecord
  { eventId :: C f (SqlSerial Int32)
  , gameId :: C f Text
  , roundNumber :: C f Int32
  , eventTimestamp :: C f UTCTime
  , actorId :: C f (Maybe Text)
  , eventType :: C f Text
  , eventData :: C f (PgJSONB Value)
  }
  deriving (Generic, Beamable)

type GameEventRecord = GameEventRecordT Identity
type GameEventRecordId = PrimaryKey GameEventRecordT Identity

instance Table GameEventRecordT where
  data PrimaryKey GameEventRecordT f = GameEventRecordId (C f (SqlSerial Int32))
    deriving (Generic, Beamable)
  primaryKey e = GameEventRecordId e.eventId

-- | The Database
data CardPGDB f = CardPGDB
  { games :: f (TableEntity GameT)
  , customCards :: f (TableEntity CustomCardT)
  , gameEvents :: f (TableEntity GameEventRecordT)
  }
  deriving stock (Generic)
  deriving anyclass (Database be)

cardpgDb :: DatabaseSettings be CardPGDB
cardpgDb =
  defaultDbSettings
    `withDbModification` dbModification
      { gameEvents =
          setEntityName "events"
            <> modifyTableFields
              tableModification
                { eventId = fieldNamed "id"
                , gameId = fieldNamed "game_id"
                , roundNumber = fieldNamed "round_number"
                , eventTimestamp = fieldNamed "timestamp"
                , actorId = fieldNamed "actor_id"
                , eventType = fieldNamed "type"
                , eventData = fieldNamed "data"
                }
      }

annotatedDb :: AnnotatedDatabaseSettings Postgres CardPGDB
annotatedDb = defaultAnnotatedDbSettings cardpgDb
