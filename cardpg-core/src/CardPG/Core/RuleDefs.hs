{-# LANGUAGE DeriveGeneric #-}
{-# LANGUAGE DeriveAnyClass #-}
{-# LANGUAGE TemplateHaskell #-}
{-# LANGUAGE ScopedTypeVariables #-}
{-# LANGUAGE OverloadedStrings #-}

module CardPG.Core.RuleDefs
  ( PassiveDef(..)
  , AttackDef(..)
  , DefendDef(..)
  , GeneralDef(..)
  , TaskDef(..)
  , TriggerDef(..)
  , StanceDef(..)
  , ChannelDef(..)
  , PrimeDef(..)
  , Rule(..)
  ) where


import Data.Aeson.TypeScript.TH (deriveTypeScript)
import Data.Aeson.TH (deriveJSON)
import Data.List.NonEmpty (NonEmpty)
import GHC.Generics (Generic)

import CardPG.Core.Types (ResourceType(..))
import CardPG.Core.RichText (RichString, StackPower)
import CardPG.Core.Json (cardpgJsonDef, cardpgJsonOptions)
import CardPG.Core.NonEmptyText (NonEmptyText)

-- | A static modifier.
-- | Addresses: "+2 to resource values when used in a defense stack"
data PassiveDef = PassiveDef
  { _bonus     :: StackPower
  , _condition :: Maybe NonEmptyText
  } deriving (Show, Eq, Generic)

-- | Standard Attack Logic
data AttackDef = AttackDef
  { _power      :: StackPower
  , _resistedBy :: ResourceType
  , _effect     :: Maybe RichString
  } deriving (Show, Eq, Generic)

-- | Defense Logic
data DefendDef = DefendDef
  { _power   :: StackPower
  , _resists :: NonEmpty ResourceType
  , _effect  :: Maybe RichString
  } deriving (Show, Eq, Generic)

-- | General/Utility Actions
-- | Addresses: "Fatigue: Action (Sleep 2 hours): Remove this"
data GeneralDef = GeneralDef
  { _name   :: NonEmptyText
  , _cost   :: Maybe RichString -- ^ Narrative Cost: "Sleep 2 hours"
  , _power  :: Maybe StackPower -- ^ Optional. Fatigue removal isn't a check.
  , _effect :: RichString       -- ^ Effect: "Remove this card"
  } deriving (Show, Eq, Generic)

-- | Persistent Effects: Stance
data StanceDef = StanceDef
  { _duration :: NonEmptyText
  , _effect :: RichString
  } deriving (Show, Eq, Generic)

-- | Persistent Effects: Channel
data ChannelDef = ChannelDef
  { _duration :: NonEmptyText
  , _effect   :: RichString
  } deriving (Show, Eq, Generic)

-- | Persistent Effects: Prime
data PrimeDef = PrimeDef
  { _trigger  :: NonEmptyText
  , _reaction :: Rule
  } deriving (Show, Eq, Generic)

-- | Task Actions (Downtime/Narrative)
-- | Addresses: "Task: First Aid ({Blue} 3, 1 min): Remove this"
data TaskDef = TaskDef
  { _name   :: NonEmptyText
  , _check  :: Maybe StackPower -- ^ The difficulty check: "Check {Blue} 3"
  , _time   :: Maybe RichString -- ^ Duration: "Time 1 min"
  , _cost   :: Maybe RichString -- ^ Narrative Cost: "Cost Bandage"
  , _effect :: RichString       -- ^ Effect: "Remove this card"
  } deriving (Show, Eq, Generic)

-- | Triggered Effects (When)
-- | Addresses: "When removed -> Add 1 Wound"
data TriggerDef = TriggerDef
  { _trigger :: NonEmptyText
  , _effect  :: RichString
  } deriving (Show, Eq, Generic)

-- | The Top-Level Rule Sum Type
data Rule
  = RuleAttack  AttackDef
  | RuleDefend  DefendDef
  | RuleGeneral GeneralDef
  | RuleTask    TaskDef
  | RuleTrigger TriggerDef
  | RuleStance  StanceDef
  | RuleChannel ChannelDef
  | RulePrime   PrimeDef
  | RuleNarrative RichString
  | RulePassive PassiveDef
  deriving stock (Eq, Show, Generic)

$(mconcat <$> traverse (deriveTypeScript (cardpgJsonOptions "Rule")) 
  [ ''PassiveDef
  , ''AttackDef
  , ''DefendDef
  , ''GeneralDef
  , ''TaskDef
  , ''TriggerDef
  , ''StanceDef
  , ''ChannelDef
  , ''PrimeDef
  , ''Rule
  ])

-- | Note:
-- | 1. 'Rule' is excluded because it has a custom manual instance in RuleInstances.hs
-- |    to support DSL parsing (e.g. "Attack {Red}...").
-- | 2. 'PrimeDef' is excluded because it depends on 'Rule', creating a cycle if defined here.
-- |    Its instance is derived in RuleInstances.hs instead.
$(mconcat <$> traverse (deriveJSON cardpgJsonDef)
  [ ''PassiveDef
  , ''AttackDef
  , ''DefendDef
  , ''GeneralDef
  , ''TaskDef
  , ''TriggerDef
  , ''StanceDef
  , ''ChannelDef
  ])
