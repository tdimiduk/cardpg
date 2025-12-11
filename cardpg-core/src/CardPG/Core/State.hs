{-# LANGUAGE ScopedTypeVariables #-}
{-# LANGUAGE TemplateHaskell #-}
{-# LANGUAGE TypeApplications #-}
{-# LANGUAGE DuplicateRecordFields #-}

module CardPG.Core.State where


import Data.Aeson.TH (deriveJSON)

import Data.Map.Strict (Map)

import Data.Set (Set)

import GHC.Generics (Generic)
import Optics.TH (makeLenses)


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
$(makeLenses ''CorePlayState)

-- | Core Card State (Dynamic)
data CoreCardState = CoreCardState
  { -- Ordered Zones
    _deck :: [CardInstanceId] -- Top is head
  , _hand :: [CardInstanceId] -- User-defined order
  , _discard :: [CardInstanceId] -- Top is head (most recently played)
  , -- Unordered / Active Zones
    _defending :: Set CardInstanceId -- Currently committed to a defense
  , _inPlay :: Map CardInstanceId CorePlayState -- Buffs, Stances, Attached effects
  , _coreRegistry :: Map CardInstanceId CoreCard -- ^ The Registry (Source of Truth for Core Cards)
  }
  deriving stock (Show, Eq, Generic)

$(deriveJSON cardpgJsonDef ''CoreCardState)
$(makeLenses ''CoreCardState)

-- | Table Asset State (Dynamic)
-- type TableAssetState = Map CardInstanceId AssetState
data TableState = TableState
  { _assets :: Map CardInstanceId AssetState
  , _tableRegistry :: Map CardInstanceId TableCard -- ^ The Registry (Source of Truth for Table Cards)
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
$(makeLenses ''AssetState)

$(deriveJSON cardpgJsonDef ''TableState)
$(makeLenses ''TableState)

-- | The Authoritative State Container
data ActorState = ActorState
  { -- 1. The Regimes (Self-contained with their registries)
    _coreState :: CoreCardState -- Handles Core Cards (Deck/Hand/Discard)
  , _tableState :: TableState -- Handles Table Cards (Equipment/Conditions)
  }
  deriving stock (Show, Eq, Generic)

$(deriveJSON cardpgJsonDef ''ActorState)
$(makeLenses ''ActorState)
