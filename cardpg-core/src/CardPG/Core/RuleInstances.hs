{-# OPTIONS_GHC -fno-warn-orphans #-}

module CardPG.Core.RuleInstances () where

import Data.Aeson (FromJSON (..), ToJSON (..), Value (..), genericParseJSON)

import CardPG.Core.DSL.Printer (prettyRule)
import CardPG.Core.DSL.RuleParser (parseRule)
import CardPG.Core.Json (cardpgJsonOptions)
import CardPG.Core.RuleDefs (Rule)
import CardPG.Core.TextFmt (TextFmt (..))

instance TextFmt Rule where
  toText = prettyRule
  fromText = parseRule

instance ToJSON Rule where
  toJSON = String . prettyRule

instance FromJSON Rule where
  parseJSON (String t) = case parseRule t of
    Right r -> pure r
    Left err -> fail $ "DSL parse failed: " ++ err
  parseJSON v = genericParseJSON (cardpgJsonOptions "Rule") v
