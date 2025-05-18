module Backend.Database.Types where

import Data.Int (Int32, Int64)
import Data.Text (Text)

import Database.Beam
import Database.Beam.Backend.SQL.Types

type SerialKey = SqlSerial Int64

data ConsequenceCardT f = ConsequenceCard
  { _id :: C f SerialKey
  , _name :: C f Text
  , _severity :: C f Int32
  , _effect :: C f Text
  }
  deriving stock Generic
  deriving anyclass Beamable

instance Table ConsequenceCardT where
  data PrimaryKey ConsequenceCardT f
    = ConsequenceCardId (C f SerialKey)
    deriving stock Generic
    deriving anyclass Beamable
  primaryKey = ConsequenceCardId . _id
