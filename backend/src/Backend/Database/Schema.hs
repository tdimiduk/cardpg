{-# LANGUAGE UndecidableInstances #-}

module Backend.Database.Schema where

import Database.Beam

import Backend.Database.Types

data Db f = Db
  { _consequenceCard :: f (TableEntity ConsequenceCardT)
  }
  deriving stock Generic
  deriving anyclass (Database be)
