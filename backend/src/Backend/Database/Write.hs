{-# LANGUAGE NamedFieldPuns #-}

module Backend.Database.Write where

import Data.Text (Text)

import Control.Lens
import Data.Generics.Labels ()

import Database.Beam
import Database.Beam.Postgres

import Backend.Database.Schema
import Backend.Database.Types
import Backend.GSheets.Fetch (SheetConsequenceCard)

import Common.Card.Common

type QExprP = QExpr Postgres

replaceConsequenceCards :: (MonadBeam Postgres m) => Text -> [SheetConsequenceCard] -> m ()
replaceConsequenceCards deck cards = do
  runDelete $ delete (_tableConsequenceCard db) ((val_ deck ==.) . _deck)
  runInsert $ insert (_tableConsequenceCard db) $ insertExpressions $ dbCard deck <$> cards

dbCard :: Text -> SheetConsequenceCard -> ConsequenceCardT (QExprP s)
dbCard deck apiCard = ConsequenceCard
      default_
      (val_ $ apiCard ^. #name)
      (val_ $ apiCard ^. #severity)
      -- TODO: parse this text
      (val_ $ PgJSONB $ asCardBlocks $ apiCard ^. #effect)
      (val_ deck)
