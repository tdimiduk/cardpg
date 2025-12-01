{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE RecordWildCards #-}
{-# OPTIONS_GHC -fno-warn-orphans #-}

module CardPG.Core.RuleInstances () where

import Data.Aeson (ToJSON(..), FromJSON(..), Value(..), withText, genericParseJSON, genericToJSON, genericToEncoding)

import CardPG.Core.RuleDefs (Rule(..), AttackDef(..), DefendDef(..), GeneralDef(..), StanceDef(..), ChannelDef(..), PrimeDef(..), PassiveDef(..))
import CardPG.Core.TextFmt (TextFmt(..))
import CardPG.Core.DSL.Parser (parseRule)
import CardPG.Core.DSL.Printer (prettyRule)
import CardPG.Core.Json (cardpgJsonOptions, cardpgJsonDef)

-- Component Instances

instance ToJSON PassiveDef where
  toJSON = genericToJSON cardpgJsonDef
  toEncoding = genericToEncoding cardpgJsonDef
instance FromJSON PassiveDef where
  parseJSON = genericParseJSON cardpgJsonDef

instance ToJSON AttackDef where
  toJSON = genericToJSON cardpgJsonDef
  toEncoding = genericToEncoding cardpgJsonDef
instance FromJSON AttackDef where
  parseJSON = genericParseJSON cardpgJsonDef

instance ToJSON DefendDef where
  toJSON = genericToJSON cardpgJsonDef
  toEncoding = genericToEncoding cardpgJsonDef
instance FromJSON DefendDef where
  parseJSON = genericParseJSON cardpgJsonDef

instance ToJSON GeneralDef where
  toJSON = genericToJSON cardpgJsonDef
  toEncoding = genericToEncoding cardpgJsonDef
instance FromJSON GeneralDef where
  parseJSON = genericParseJSON cardpgJsonDef

instance ToJSON StanceDef where
  toJSON = genericToJSON cardpgJsonDef
  toEncoding = genericToEncoding cardpgJsonDef
instance FromJSON StanceDef where
  parseJSON = genericParseJSON cardpgJsonDef

instance ToJSON ChannelDef where
  toJSON = genericToJSON cardpgJsonDef
  toEncoding = genericToEncoding cardpgJsonDef
instance FromJSON ChannelDef where
  parseJSON = genericParseJSON cardpgJsonDef

instance ToJSON PrimeDef where
  toJSON = genericToJSON cardpgJsonDef
  toEncoding = genericToEncoding cardpgJsonDef
instance FromJSON PrimeDef where
  parseJSON = genericParseJSON cardpgJsonDef

-- Rule Instances

instance TextFmt Rule where
  toText = prettyRule
  fromText = parseRule

instance ToJSON Rule where
  toJSON = String . toText

instance FromJSON Rule where
  parseJSON v = withText "Rule" (\t -> case fromText t of
    Right r -> pure r
    Left _ -> genericParseJSON (cardpgJsonOptions "Rule") v) v
