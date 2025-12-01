{-# LANGUAGE DeriveGeneric #-}
{-# LANGUAGE DeriveAnyClass #-}
{-# LANGUAGE OverloadedStrings #-}

module CardPG.Core.RuleDefs
  ( PassiveDef(..)
  , AttackDef(..)
  , DefendDef(..)
  , GeneralDef(..)
  , StanceDef(..)
  , ChannelDef(..)
  , PrimeDef(..)
  , Rule(..)
  ) where


import Data.List.NonEmpty (NonEmpty)
import GHC.Generics (Generic)


import CardPG.Core.Types (ResourceType(..))
import CardPG.Core.RichText (RichString, StackPower)

-- | A static modifier.
-- | Addresses: "+2 to resource values when used in a defense stack"
import CardPG.Core.NonEmptyText (NonEmptyText)

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
  { _power  :: Maybe StackPower -- ^ Optional. Fatigue removal isn't a check.
  , _cost   :: Maybe RichString -- ^ Narrative Cost: "Sleep 2 hours"
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

-- | The Top-Level Rule Sum Type
data Rule
  = RuleAttack  AttackDef
  | RuleDefend  DefendDef
  | RuleGeneral GeneralDef
  | RuleStance  StanceDef
  | RuleChannel ChannelDef
  | RulePrime   PrimeDef
  | RuleNarrative RichString
  | RulePassive PassiveDef
  deriving stock (Eq, Show, Generic)
