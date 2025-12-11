{-# LANGUAGE ScopedTypeVariables #-}
{-# LANGUAGE TemplateHaskell #-}
{-# LANGUAGE TypeApplications #-}
{-# LANGUAGE DuplicateRecordFields #-}

module CardPG.Core.State where


import Data.Aeson.TH (deriveJSON)

import Data.Map.Strict (Map)

import Data.Set (Set)

import GHC.Generics (Generic)



import CardPG.Core.Card (ConsequenceCard, CoreCard, ItemCard, NatureCard, TalentCard)
import CardPG.Core.Json (cardpgJsonDef)

import CardPG.Core.Primitives (CardInstanceId (..), EquipSlot (..), TargetId (..))

-- | Sum type for all Table Assets
data TableCard
  = TCItem ItemCard
  | TCNature NatureCard
  | TCTalent TalentCard
  | TCConsequence ConsequenceCard
  deriving stock (Show, Eq, Generic)

$(deriveJSON cardpgJsonDef ''TableCard)

data CorePlayState
  = Stance -- Persistent effect on self
  | AttachedTo TargetId -- Buff/Debuff on Target (Actor/Token UUID)
  deriving stock (Show, Eq, Generic)

$(deriveJSON cardpgJsonDef ''CorePlayState)

data CoreCardState = CoreCardState
  { -- Ordered Zones
    deck :: [CardInstanceId] -- Top is head
  , hand :: [CardInstanceId] -- User-defined order
  , discard :: [CardInstanceId] -- Top is head (most recently played)
  , -- Unordered / Active Zones
    defending :: Set CardInstanceId -- Currently committed to a defense
  , inPlay :: Map CardInstanceId CorePlayState -- Buffs, Stances, Attached effects
  , registry :: Map CardInstanceId CoreCard -- ^ The Registry (Source of Truth for Core Cards)
  }
  deriving stock (Show, Eq, Generic)

$(deriveJSON cardpgJsonDef ''CoreCardState)

data TableState = TableState
  { assets :: Map CardInstanceId AssetState
  , registry :: Map CardInstanceId TableCard -- ^ The Registry (Source of Truth for Table Cards)
  }
  deriving stock (Show, Eq, Generic)

data AssetState
  = InCollection -- Passive / Stored / Sideboard
  | Equipped EquipSlot -- Active Item
  | Stashed -- Carried but inactive Item
  | Trait -- Innate (Nature/Talent)
  | Condition -- Injury/Status on Table relative to Actor
  deriving stock (Show, Eq, Generic)

$(deriveJSON cardpgJsonDef ''AssetState)

$(deriveJSON cardpgJsonDef ''TableState)

-- | The Authoritative State Container
data ActorState = ActorState
  { -- 1. The Regimes (Self-contained with their registries)
    coreState :: CoreCardState -- Handles Core Cards (Deck/Hand/Discard)
  , tableState :: TableState -- Handles Table Cards (Equipment/Conditions)
  }
  deriving stock (Show, Eq, Generic)


$(deriveJSON cardpgJsonDef ''ActorState)

data GameEvent
  = CardsCreated [CardInstanceId]
  | DeckShuffled
  deriving stock (Show, Eq, Generic)

$(deriveJSON cardpgJsonDef ''GameEvent)

data GameEnv = GameEnv
  { fatigueCardTemplate :: CoreCard
  } deriving stock (Show, Eq, Generic)
