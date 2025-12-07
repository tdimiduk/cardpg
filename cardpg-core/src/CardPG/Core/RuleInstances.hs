{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE RecordWildCards #-}
{-# LANGUAGE TemplateHaskell #-}
{-# OPTIONS_GHC -fno-warn-orphans #-}

module CardPG.Core.RuleInstances () where

import Data.Aeson (ToJSON(..), FromJSON(..), Value(..), genericParseJSON, genericToJSON, (.:))
import Data.Aeson.Types (Parser)
import Data.Text (Text)
import Control.Applicative ((<|>))

import CardPG.Core.RuleDefs (RuleT(..), DSLBase, DSLRule(DSLRule))
import CardPG.Core.TextFmt (TextFmt(..))
import CardPG.Core.DSL.Parser (parseRule)
import CardPG.Core.DSL.Printer (prettyRule)
import CardPG.Core.Json (cardpgJsonOptions, cardpgJsonDef)
import Data.Aeson.TH (deriveJSON)

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
