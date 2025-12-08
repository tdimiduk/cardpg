{-# LANGUAGE DeriveAnyClass #-}
{-# LANGUAGE DeriveFunctor #-}
{-# LANGUAGE DeriveGeneric #-}
{-# LANGUAGE DuplicateRecordFields #-}
{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE ScopedTypeVariables #-}
{-# LANGUAGE TemplateHaskell #-}

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
  , StanceDefT (..)
  , StanceDef
  , ChannelDefT (..)
  , ChannelDef
  , PrimeDefT (..)
  , PrimeDef
  , RuleT (..)
  , Rule
  , DSLBase
  , DSLRule (..)
  ) where

import Data.Aeson (FromJSON, ToJSON)
import Data.Aeson.TH (deriveJSON)
import Data.Functor.Classes (Eq1, Show1, eq1, liftEq, liftShowsPrec, showsPrec1)
import GHC.Generics (Generic)

import CardPG.Core.Json (cardpgJsonDef, cardpgJsonOptions)
import CardPG.Core.NonEmptyText (NonEmptyText)
import CardPG.Core.RichText (RichString, RichText, StackPower)
import CardPG.Core.Types (Difficulty, ResourceType (..))

-- | A static modifier.
-- | Addresses: "+2 to resource values when used in a defense stack"
data PassiveDef = PassiveDef
  { _bonus :: StackPower
  , _condition :: Maybe NonEmptyText
  }
  deriving (Show, Eq, Generic)

-- | Standard Attack Logic
data AttackDefT rt = AttackDef
  { _power :: StackPower
  , _resistedBy :: ResourceType
  , _effect :: Maybe rt
  }
  deriving (Show, Eq, Generic, Functor)

-- | General/Utility Actions
-- | Addresses: "Fatigue: Action (Sleep 2 hours): Remove this"
data GeneralDefT rt = GeneralDef
  { _name :: NonEmptyText
  , _cost :: Maybe rt
  -- ^ Narrative Cost: "Sleep 2 hours"
  , _difficulty :: Maybe Difficulty
  -- ^ Optional. Fatigue removal isn't a check.
  , _effect :: rt
  -- ^ Effect: "Remove this card"
  }
  deriving (Show, Eq, Generic, Functor)

-- | Persistent Effects: Stance
data StanceDefT rt = StanceDef
  { _duration :: NonEmptyText
  , _effect :: rt
  }
  deriving (Show, Eq, Generic, Functor)

-- | Persistent Effects: Channel
data ChannelDefT rt = ChannelDef
  { _duration :: NonEmptyText
  , _effect :: rt
  }
  deriving (Show, Eq, Generic, Functor)

-- | Persistent Effects: Prime
data PrimeDefT rt = PrimeDef
  { _trigger :: NonEmptyText
  , _reaction :: RuleT rt
  }
  deriving (Show, Eq, Generic, Functor)

-- | Task Actions (Downtime/Narrative)
-- | Addresses: "Task: First Aid ({Blue} 3, 1 min): Remove this"
data TaskDefT rt = TaskDef
  { _name :: NonEmptyText
  , _check :: Maybe Difficulty
  -- ^ The difficulty check: "Check {Blue} 3"
  , _time :: Maybe rt
  -- ^ Duration: "Time 1 min"
  , _cost :: Maybe rt
  -- ^ Narrative Cost: "Cost Bandage"
  , _effect :: rt
  -- ^ Effect: "Remove this card"
  }
  deriving (Show, Eq, Generic, Functor)

-- | Triggered Effects (When)
-- | Addresses: "When removed -> Add 1 Wound"
data TriggerDefT rt = TriggerDef
  { _trigger :: NonEmptyText
  , _effect :: rt
  }
  deriving (Show, Eq, Generic, Functor)

-- | The Top-Level Rule Sum Type
data RuleT rt
  = RuleAttack (AttackDefT rt)
  | RuleGeneral (GeneralDefT rt)
  | RuleTask (TaskDefT rt)
  | RuleTrigger (TriggerDefT rt)
  | RuleStance (StanceDefT rt)
  | RuleChannel (ChannelDefT rt)
  | RulePrime (PrimeDefT rt)
  | RuleNarrative rt
  | RulePassive PassiveDef
  deriving stock (Eq, Show, Generic, Functor)

-- | Base Types (Machine Readable)
type Rule = RuleT RichText

type AttackDef = AttackDefT RichText
type GeneralDef = GeneralDefT RichText
type TaskDef = TaskDefT RichText
type TriggerDef = TriggerDefT RichText
type StanceDef = StanceDefT RichText
type ChannelDef = ChannelDefT RichText
type PrimeDef = PrimeDefT RichText

-- | DSL Base (Human Readable)
type DSLBase = RuleT RichString

newtype DSLRule = DSLRule {unDSLRule :: DSLBase}
  deriving (Show, Eq, Generic)

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
           , ''StanceDefT
           , ''ChannelDefT
           , ''PrimeDefT
           ]
     rule <- deriveJSON (cardpgJsonOptions "Rule") ''RuleT
     return (defs ++ rule)
 )
