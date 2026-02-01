{-# OPTIONS_GHC -fno-warn-orphans #-}

module Core.RuleInstances () where

import Data.Aeson (FromJSON (..), ToJSON (..), Value (..), genericParseJSON)

import Core.DSL.RuleParser (parseAttack, parseRule)
import Core.DSL.TextRep (TextRep (..))
import Core.Json (cardpgJsonOptions)
import Core.RuleDefs (AttackDef, Rule)

instance ToJSON Rule where
  toJSON = String . toText

instance FromJSON Rule where
  parseJSON (String t) = case parseRule t of
    Right r -> pure r
    Left err -> fail $ "DSL parse failed: " ++ err
  parseJSON v = genericParseJSON (cardpgJsonOptions "Rule") v

instance ToJSON AttackDef where
  toJSON = String . toText

instance FromJSON AttackDef where
  parseJSON (String t) = case parseAttack t of
    Right r -> pure r
    Left err -> fail $ "Attack DSL parse failed: " ++ err
  parseJSON v = genericParseJSON (cardpgJsonOptions "AttackDef") v
