{-# LANGUAGE DeriveAnyClass #-}
{-# LANGUAGE DeriveFunctor #-}

module CardPG.Core.RuleDefs
  ( PassiveDef (..)
  , AttackDef (..)
  , GeneralDef (..)
  , TaskDef (..)
  , TriggerDef (..)
  , OngoingDef (..)
  , Rule (..)
  ) where

import Data.Aeson.TH (deriveJSON)
import GHC.Generics (Generic)

import CardPG.Core.Json (cardpgJsonDef)
import CardPG.Core.NonEmptyText (NonEmptyText)
import CardPG.Core.Primitives (Difficulty, ResourceType (..))
import CardPG.Core.RichText (RichText, StackPower)

-- | A static modifier.
-- | Addresses: "+2 to resource values when used in a defense stack"
data PassiveDef = PassiveDef
  { bonus :: StackPower
  , condition :: Maybe NonEmptyText
  }
  deriving (Show, Eq, Generic)

-- | Standard Attack Logic
data AttackDef = AttackDef
  { power :: StackPower
  , resistedBy :: ResourceType
  , effect :: Maybe RichText
  }
  deriving (Show, Eq, Generic)

-- | General/Utility Actions
-- | Addresses: "Fatigue: Action (Sleep 2 hours): Remove this"
data GeneralDef = GeneralDef
  { name :: NonEmptyText
  , cost :: Maybe RichText
  -- ^ Narrative Cost: "Sleep 2 hours"
  , difficulty :: Maybe Difficulty
  -- ^ Optional. Fatigue removal isn't a check.
  , effect :: RichText
  -- ^ Effect: "Remove this card"
  }
  deriving (Show, Eq, Generic)

-- | Persistent Effects: Ongoing (Stance, Channel, Prime)
-- | Addresses: "Stance (1 min): +1 Strength", "Until triggered: ..."
data OngoingDef = OngoingDef
  { life :: RichText
  -- ^ Duration or Condition: "1 min", "Until triggered", "While holding a shield"
  , effect :: RichText
  -- ^ The mechanical or narrative effect
  }
  deriving (Show, Eq, Generic)

-- | Task Actions (Downtime/Narrative)
-- | Addresses: "Task: First Aid ({Blue} 3, 1 min): Remove this"
data TaskDef = TaskDef
  { name :: NonEmptyText
  , check :: Maybe Difficulty
  -- ^ The difficulty check: "Check {Blue} 3"
  , time :: Maybe RichText
  -- ^ Duration: "Time 1 min"
  , cost :: Maybe RichText
  -- ^ Narrative Cost: "Cost Bandage"
  , effect :: RichText
  -- ^ Effect: "Remove this card"
  }
  deriving (Show, Eq, Generic)

-- | Triggered Effects (When)
-- | Addresses: "When removed -> Add 1 Wound"
data TriggerDef = TriggerDef
  { trigger :: NonEmptyText
  , effect :: RichText
  }
  deriving (Show, Eq, Generic)

-- | The Top-Level Rule Sum Type
data Rule
  = RuleAttack AttackDef
  | RuleGeneral GeneralDef
  | RuleTask TaskDef
  | RuleTrigger TriggerDef
  | RuleOngoing OngoingDef
  | RuleNarrative RichText
  | RulePassive PassiveDef
  deriving stock (Eq, Show, Generic)

-- | Note:
-- | 1. 'Rule' is excluded because it has a custom manual instance in RuleInstances.hs
-- |    to support DSL parsing (e.g. "Attack {Red}...").
-- | 2. 'PrimeDef' is excluded because it depends on 'Rule', creating a cycle if defined here.
-- |    Its instance is derived in RuleInstances.hs instead.
$( do
     defs <-
       mconcat
         <$> traverse
           (deriveJSON cardpgJsonDef)
           [ ''PassiveDef
           , ''AttackDef
           , ''GeneralDef
           , ''TaskDef
           , ''TriggerDef
           , ''OngoingDef
           ]
     return defs
 )
