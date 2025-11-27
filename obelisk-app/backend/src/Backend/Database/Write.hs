{-# LANGUAGE NamedFieldPuns #-}

module Backend.Database.Write where

import Data.Text (Text)

import Control.Lens
import Data.Generics.Labels ()

import Database.Beam
import Database.Beam.Postgres

import Backend.Database.Schema
import Backend.Database.Types
import Backend.GSheets.Fetch

import Common.Card.Common

type QExprP = QExpr Postgres

replaceConsequenceCards :: (MonadBeam Postgres m) => Text -> [SheetConsequenceCard] -> m ()
replaceConsequenceCards deck newCards = do
  runDelete $ delete (_tableConsequenceCard db) ((val_ deck ==.) . view #_deck)
  runInsert $ insert (_tableConsequenceCard db) $ insertExpressions $ dbCard deck <$> newCards

replaceConditionCards :: (MonadBeam Postgres m) => Text -> [SheetConditionCard] -> m ()
replaceConditionCards deck newCards = do
  runDelete $ delete (_tableConditionCard db) ((val_ deck ==.) . view #_deck)
  runInsert $ insert (_tableConditionCard db) $ insertExpressions $ dbConditionCard deck <$> newCards

dbConditionCard :: Text -> SheetConditionCard -> ConditionCardT (QExprP s)
dbConditionCard deck apiCard = ConditionCard
  default_
  (val_ $ apiCard ^. #name)
  (val_ $ PgJSONB $ asCardBlocks $ apiCard ^. #effect)
  (val_ $ PgJSONB $ asCardBlocks $ apiCard ^. #removal)
  (val_ deck)

dbCard :: Text -> SheetConsequenceCard -> ConsequenceCardT (QExprP s)
dbCard deck apiCard = ConsequenceCard
      default_
      (val_ $ apiCard ^. #name)
      (val_ $ apiCard ^. #severity)
      -- TODO: parse this text
      (val_ $ PgJSONB $ asCardBlocks $ apiCard ^. #effect)
      (val_ deck)
