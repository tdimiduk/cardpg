module Backend.Database.Types where

import Control.Lens
import Data.Generics.Labels ()
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
  , _effect :: C f (PgJSONB CardBlocks)
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
  primaryKey = ConsequenceCardId . view #_id

data GSheetsReferenceT f = GSheetsReference
  { _id :: C f SerialKey
  , _name :: C f Text
  , _key :: C f Text
  , _sheet :: C f Text
  , _deckCardType :: C f (Maybe CardType)
  }
  deriving stock Generic
  deriving anyclass Beamable

type GSheetsReference = GSheetsReferenceT Identity

instance Table GSheetsReferenceT where
  data PrimaryKey GSheetsReferenceT f
    = GSheetsReferenceId (C f SerialKey)
    deriving stock Generic
    deriving anyclass Beamable
  primaryKey = GSheetsReferenceId . view #_id
