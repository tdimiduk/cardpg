{-# LANGUAGE DeriveAnyClass #-}
{-# LANGUAGE DeriveFunctor #-}

module CardPG.Core.RuleDefs
  ( PassiveDef (..)
  , AttackDefT (..)
  , AttackDef
  , GeneralDefT (..)
  , GeneralDef
  , TaskDefT (..)
  , TaskDef
  , TriggerDefT (..)
  , TriggerDef
  , OngoingDefT (..)
  , OngoingDef
  , RuleT (..)
  , Rule
  ) where

import Data.Aeson.TH (deriveJSON, deriveToJSON)
import GHC.Generics (Generic)

import CardPG.Core.Json (cardpgJsonDef, cardpgJsonOptions)
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
data AttackDefT rt = AttackDef
  { power :: StackPower
  , resistedBy :: ResourceType
  , effect :: Maybe rt
  }
  deriving (Show, Eq, Generic, Functor)

-- | General/Utility Actions
-- | Addresses: "Fatigue: Action (Sleep 2 hours): Remove this"
data GeneralDefT rt = GeneralDef
  { name :: NonEmptyText
  , cost :: Maybe rt
  -- ^ Narrative Cost: "Sleep 2 hours"
  , difficulty :: Maybe Difficulty
  -- ^ Optional. Fatigue removal isn't a check.
  , effect :: rt
  -- ^ Effect: "Remove this card"
  }
  deriving (Show, Eq, Generic, Functor)

-- | Persistent Effects: Ongoing (Stance, Channel, Prime)
-- | Addresses: "Stance (1 min): +1 Strength", "Until triggered: ..."
data OngoingDefT rt = OngoingDef
  { life :: rt
  -- ^ Duration or Condition: "1 min", "Until triggered", "While holding a shield"
  , effect :: rt
  -- ^ The mechanical or narrative effect
  }
  deriving (Show, Eq, Generic, Functor)

-- | Task Actions (Downtime/Narrative)
-- | Addresses: "Task: First Aid ({Blue} 3, 1 min): Remove this"
data TaskDefT rt = TaskDef
  { name :: NonEmptyText
  , check :: Maybe Difficulty
  -- ^ The difficulty check: "Check {Blue} 3"
  , time :: Maybe rt
  -- ^ Duration: "Time 1 min"
  , cost :: Maybe rt
  -- ^ Narrative Cost: "Cost Bandage"
  , effect :: rt
  -- ^ Effect: "Remove this card"
  }
  deriving (Show, Eq, Generic, Functor)

-- | Triggered Effects (When)
-- | Addresses: "When removed -> Add 1 Wound"
data TriggerDefT rt = TriggerDef
  { trigger :: NonEmptyText
  , effect :: rt
  }
  deriving (Show, Eq, Generic, Functor)

-- | The Top-Level Rule Sum Type
data RuleT rt
  = RuleAttack (AttackDefT rt)
  | RuleGeneral (GeneralDefT rt)
  | RuleTask (TaskDefT rt)
  | RuleTrigger (TriggerDefT rt)
  | RuleOngoing (OngoingDefT rt)
  | RuleNarrative rt
  | RulePassive PassiveDef
  deriving stock (Eq, Show, Generic, Functor)

-- | Base Types (Machine Readable)
type Rule = RuleT RichText

type AttackDef = AttackDefT RichText
type GeneralDef = GeneralDefT RichText
type TaskDef = TaskDefT RichText
type TriggerDef = TriggerDefT RichText
type OngoingDef = OngoingDefT RichText

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
           , ''AttackDefT
           , ''GeneralDefT
           , ''TaskDefT
           , ''TriggerDefT
           , ''OngoingDefT
           ]
     return defs
 )
