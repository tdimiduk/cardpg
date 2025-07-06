module Backend.Database.Types where

import Data.Int (Int32, Int64)
import Data.Text (Text)

import Database.Beam
import Database.Beam.Backend.SQL.Types
import Database.Beam.Postgres (PgJSONB(..))

import Common.Card.Common

type SerialKey = SqlSerial Int64

data ConsequenceCardT f = ConsequenceCard
  { _id :: C f SerialKey
  , _name :: C f Text
  , _severity :: C f Int32
  , _effect :: C f (PgJSONB CardText)
  , _deck :: C f Text
  }
  deriving stock Generic
  deriving anyclass Beamable

type ConsequenceCard = ConsequenceCardT Identity

instance Table ConsequenceCardT where
  data PrimaryKey ConsequenceCardT f
    = ConsequenceCardId (C f SerialKey)
    deriving stock Generic
    deriving anyclass Beamable
  primaryKey = ConsequenceCardId . _id
