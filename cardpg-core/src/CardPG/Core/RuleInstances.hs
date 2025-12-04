{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE RecordWildCards #-}
{-# LANGUAGE TemplateHaskell #-}
{-# OPTIONS_GHC -fno-warn-orphans #-}

module CardPG.Core.RuleInstances () where

import Data.Aeson (ToJSON(..), FromJSON(..), Value(..), genericParseJSON, (.:))
import Data.Text (Text)
import Control.Applicative ((<|>))

import CardPG.Core.RuleDefs (Rule(..), PrimeDef(..))
import CardPG.Core.TextFmt (TextFmt(..))
import CardPG.Core.DSL.Parser (parseRule)
import CardPG.Core.DSL.Printer (prettyRule)
import CardPG.Core.Json (cardpgJsonOptions, cardpgJsonDef)
import Data.Aeson.TH (deriveJSON)

-- Component Instances

-- Component Instances moved to RuleDefs.hs via deriveJSON
-- PrimeDef must be here because it depends on Rule (which is defined here)
$(deriveJSON cardpgJsonDef ''PrimeDef)

-- Rule Instances

instance TextFmt Rule where
  toText = prettyRule
  fromText = parseRule

instance ToJSON Rule where
  toJSON = String . toText

instance FromJSON Rule where
  parseJSON v = case v of
    String t -> case fromText t of
      Right r -> pure r
      Left _  -> genericParseJSON (cardpgJsonOptions "Rule") v
    Object o -> do
      t <- o .: "type"
      case (t :: Text) of
        "attack"   -> (RuleAttack   <$> parseJSON v) <|> genericParseJSON (cardpgJsonOptions "Rule") v
        "general"  -> (RuleGeneral  <$> parseJSON v) <|> genericParseJSON (cardpgJsonOptions "Rule") v
        "stance"   -> (RuleStance   <$> parseJSON v) <|> genericParseJSON (cardpgJsonOptions "Rule") v
        "channel"  -> (RuleChannel  <$> parseJSON v) <|> genericParseJSON (cardpgJsonOptions "Rule") v
        "prime"    -> (RulePrime    <$> parseJSON v) <|> genericParseJSON (cardpgJsonOptions "Rule") v
        "passive"  -> (RulePassive  <$> parseJSON v) <|> genericParseJSON (cardpgJsonOptions "Rule") v
        "narrative" -> (RuleNarrative <$> parseJSON v) <|> genericParseJSON (cardpgJsonOptions "Rule") v
        _          -> genericParseJSON (cardpgJsonOptions "Rule") v
    _ -> fail "Rule must be a String (DSL) or Object (JSON)"
