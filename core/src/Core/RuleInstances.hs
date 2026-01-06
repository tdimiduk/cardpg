{-# OPTIONS_GHC -fno-warn-orphans #-}

module Core.RuleInstances () where

import Data.Aeson (FromJSON (..), ToJSON (..), Value (..), genericParseJSON)

import Core.DSL.Printer (prettyRule)
import Core.DSL.RuleParser (parseRule)
import Core.Json (cardpgJsonOptions)
import Core.RuleDefs (Rule)

instance ToJSON Rule where
  toJSON = String . prettyRule

instance FromJSON Rule where
  parseJSON (String t) = case parseRule t of
    Right r -> pure r
    Left err -> fail $ "DSL parse failed: " ++ err
  parseJSON v = genericParseJSON (cardpgJsonOptions "Rule") v
