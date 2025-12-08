{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE RecordWildCards #-}
{-# LANGUAGE TemplateHaskell #-}
{-# OPTIONS_GHC -fno-warn-orphans #-}

module CardPG.Core.RuleInstances () where

import Control.Applicative ((<|>))
import Data.Aeson (FromJSON (..), ToJSON (..), Value (..), genericParseJSON, genericToJSON, (.:))
import Data.Aeson.TH (deriveJSON)
import Data.Aeson.Types (Parser)
import Data.Text (Text)

import CardPG.Core.DSL.Parser (parseRule)
import CardPG.Core.DSL.Printer (prettyRule)
import CardPG.Core.Json (cardpgJsonDef, cardpgJsonOptions)
import CardPG.Core.RuleDefs (DSLBase, DSLRule (DSLRule), RuleT (..))
import CardPG.Core.TextFmt (TextFmt (..))

-- Component Instances
-- Moved to RuleDefs.hs

-- Rule Instances

instance TextFmt DSLBase where
  toText = prettyRule
  fromText = parseRule

instance ToJSON DSLRule where
  toJSON (DSLRule r) = String $ toText r

parseJSONorDSL :: Value -> Parser DSLBase
parseJSONorDSL v = case v of
  String t -> case fromText t of
    Right r -> pure r
    -- Fallback to generic parse if text parse fails (though usually parseRule returns Left)
    -- But genericParseJSON requires FromJSON DSLBase.
    -- Which is (RuleT RichString).
    -- If RuleT instance is derived in RuleDefs, we can use parseJSON v (as generic parse)
    Left err -> fail $ "DSL parse failed: " ++ err
  Object _ -> parseJSON v -- This uses the standard derived instance for RuleT
  _ -> fail "Rule must be a String (DSL) or Object (JSON)"

instance FromJSON DSLRule where
  parseJSON v = DSLRule <$> parseJSONorDSL v
