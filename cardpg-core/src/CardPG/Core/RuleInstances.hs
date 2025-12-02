{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE RecordWildCards #-}
{-# LANGUAGE TemplateHaskell #-}
{-# OPTIONS_GHC -fno-warn-orphans #-}

module CardPG.Core.RuleInstances () where

import Data.Aeson (ToJSON(..), FromJSON(..), Value(..), withText, genericParseJSON, genericToJSON, genericToEncoding)

import CardPG.Core.RuleDefs (Rule(..), AttackDef(..), DefendDef(..), GeneralDef(..), StanceDef(..), ChannelDef(..), PrimeDef(..), PassiveDef(..))
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
  parseJSON v = withText "Rule" (\t -> case fromText t of
    Right r -> pure r
    Left _ -> genericParseJSON (cardpgJsonOptions "Rule") v) v
