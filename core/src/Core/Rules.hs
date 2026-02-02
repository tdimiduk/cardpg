{-# LANGUAGE FlexibleInstances #-}
{-# LANGUAGE OverloadedStrings #-}

module Core.Rules
  ( Rule (..)
  , PassiveDef (..)
  , AttackDef (..)
  , GeneralDef (..)
  , TaskDef (..)
  , TriggerDef (..)
  , OngoingDef (..)
  , ruleParser
  , attackParser
  , passiveParser
  , ongoingParser
  , taskParser
  , triggerParser
  , generalParser
  , narrativeParser
  , layoutRule
  , layoutAttackDef
  ) where

import Data.Aeson (FromJSON (..), ToJSON (..), Value (..), genericParseJSON)
import GHC.Generics (Generic)
import Text.Megaparsec (eof)

import Core.DSL (Parser, TextRep (..), parseText, tryChoice)
import Core.Json (cardpgJsonOptions)
import Core.Layout (LayoutItem (..), renderLayoutText)
import Core.RichText (RichText, richTextParser)
import Core.Rules.Attack (AttackDef (..), attackParser, layoutAttackDef)
import Core.Rules.General (GeneralDef (..), generalParser, layoutGeneralDef)
import Core.Rules.Ongoing (OngoingDef (..), layoutOngoingDef, ongoingParser)
import Core.Rules.Passive (PassiveDef (..), layoutPassiveDef, passiveParser)
import Core.Rules.Task (TaskDef (..), layoutTaskDef, taskParser)
import Core.Rules.Trigger (TriggerDef (..), layoutTriggerDef, triggerParser)

-- | The Top-Level Rule Sum Type
data Rule
  = RuleGeneral GeneralDef
  | RuleTask TaskDef
  | RuleTrigger TriggerDef
  | RuleOngoing OngoingDef
  | RuleNarrative RichText
  | RulePassive PassiveDef
  deriving stock (Eq, Show, Generic)

-- Rule (top-level, fully roundtrippable)
instance TextRep Rule where
  toText = renderLayoutText . layoutRule
  textParser = ruleParser

instance ToJSON Rule where
  toJSON = String . toText

instance FromJSON Rule where
  parseJSON (String t) = case parseText t of
    Right r -> pure r
    Left err -> fail $ "DSL parse failed: " ++ err
  parseJSON v = genericParseJSON (cardpgJsonOptions "Rule") v

layoutRule :: Rule -> [LayoutItem]
layoutRule (RuleGeneral def) = layoutGeneralDef def
layoutRule (RuleOngoing def) = layoutOngoingDef def
layoutRule (RulePassive def) = layoutPassiveDef def
layoutRule (RuleTask def) = layoutTaskDef def
layoutRule (RuleTrigger def) = layoutTriggerDef def
layoutRule (RuleNarrative rt) = [RichContent rt]

-- Parsers

ruleParser :: Parser Rule
ruleParser =
  tryChoice $
    (<* eof)
      <$> [ RuleOngoing <$> ongoingParser
          , RulePassive <$> passiveParser
          , RuleTask <$> taskParser
          , RuleTrigger <$> triggerParser
          , RuleGeneral <$> generalParser
          , narrativeParser
          ]

-- Narrative (Fallback for General)
narrativeParser :: Parser Rule
narrativeParser = RuleNarrative <$> richTextParser
