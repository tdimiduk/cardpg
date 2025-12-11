{-# LANGUAGE ScopedTypeVariables #-}
{-# LANGUAGE TemplateHaskell #-}

{-# LANGUAGE TypeApplications #-}

module CardPG.Core.State where

import Data.Aeson (FromJSONKey, ToJSONKey)
import Data.Aeson.TH (deriveJSON)
import Data.List (sortOn)
import Data.Map.Strict (Map)
import qualified Data.Map.Strict as Map
import Data.Set (Set)
import Data.UUID (UUID)
import GHC.Generics (Generic)
import Optics.TH (makeLenses)
import System.Random (Random (..), RandomGen)

import CardPG.Core.Card (CoreCard, ItemCard, NatureCard, TalentCard, ConsequenceCard)
import CardPG.Core.Json (cardpgJsonDef)

import CardPG.Core.Primitives (CardInstanceId (..), TargetId (..), CardKind (..), EquipSlot (..))




-- | Sum type for all Table Assets
data TableCard 
  = TCItem ItemCard
  | TCNature NatureCard
  | TCTalent TalentCard
  | TCConsequence ConsequenceCard
  deriving stock (Show, Eq, Generic)

$(deriveJSON cardpgJsonDef ''TableCard)

data CorePlayState
  = Stance              -- Persistent effect on self
  | AttachedTo TargetId -- Buff/Debuff on Target (Actor/Token UUID)
  deriving stock (Show, Eq, Generic)

$(deriveJSON cardpgJsonDef ''CorePlayState)
$(makeLenses ''CorePlayState)

-- | Core Card State (Dynamic)
data CoreCardState = CoreCardState
  { -- Ordered Zones
    _deck      :: [CardInstanceId] -- Top is head
  , _hand      :: [CardInstanceId] -- User-defined order
  , _discard   :: [CardInstanceId] -- Top is head (most recently played)
  
    -- Unordered / Active Zones
  , _defending :: Set CardInstanceId            -- Currently committed to a defense
  , _inPlay    :: Map CardInstanceId CorePlayState -- Buffs, Stances, Attached effects
  }
  deriving stock (Show, Eq, Generic)

$(deriveJSON cardpgJsonDef ''CoreCardState)
$(makeLenses ''CoreCardState)



-- | Table Asset State (Dynamic)
type TableAssetState = Map CardInstanceId AssetState

data AssetState
  = InCollection       -- Passive / Stored / Sideboard
  | Equipped EquipSlot -- Active Item
  | Stashed            -- Carried but inactive Item
  | Trait              -- Innate (Nature/Talent)
  | Condition          -- Injury/Status on Table relative to Actor
  deriving stock (Show, Eq, Generic)

$(deriveJSON cardpgJsonDef ''AssetState)
$(makeLenses ''AssetState)

-- | The Authoritative State Container
data ActorState = ActorState
  { -- 1. The Registry (Source of Truth)
    _coreRegistry  :: Map CardInstanceId CoreCard
  , _tableRegistry :: Map CardInstanceId TableCard
  
    -- 2. The Regimes
  , _coreState    :: CoreCardState   -- Handles Deck/Hand/Discard flow
  , _assetState   :: TableAssetState -- Handles Equipment/Conditions
  }
  deriving stock (Show, Eq, Generic)

$(deriveJSON cardpgJsonDef ''ActorState)
$(makeLenses ''ActorState)




