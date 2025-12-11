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
import CardPG.Core.Hardcoded (fatigueCard)


-- | Unique Identity for any card instance
newtype CardInstanceId = CardInstanceId UUID 
  deriving stock (Show, Eq, Ord)
  deriving newtype (FromJSONKey, ToJSONKey)

$(deriveJSON cardpgJsonDef ''CardInstanceId)

-- | Identity for an Actor or Token on the board
newtype TargetId = TargetId UUID
  deriving stock (Show, Eq, Ord)
  deriving newtype (FromJSONKey, ToJSONKey)

$(deriveJSON cardpgJsonDef ''TargetId)

-- | Discriminator for Logic
data CardKind = KindCore | KindTable
  deriving stock (Show, Eq, Generic)

$(deriveJSON cardpgJsonDef ''CardKind)

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

data EquipSlot = SlotMainHand | SlotOffHand | SlotBody | SlotAccessory | SlotUnspecified
  deriving stock (Show, Eq, Generic)

$(deriveJSON cardpgJsonDef ''EquipSlot)
$(makeLenses ''EquipSlot)

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

-- | Helper to shuffle a list
-- Uses O(N log N) sort-based shuffle which is sufficient for game logic
shuffleList :: RandomGen g => [a] -> g -> ([a], g)
shuffleList xs gen = 
    let len = length xs
        (randomInts, gen') = splitGenList len gen
        shuffled = map snd $ sortOn fst $ zip randomInts xs
     in (shuffled, gen')

splitGenList :: RandomGen g => Int -> g -> ([Int], g)
splitGenList 0 g = ([], g)
splitGenList n g =
    let (i, g1) = random g
        (is, g2) = splitGenList (n - 1) g1
     in (i : is, g2)

-- | Perform the Fatigue Cycle
-- 1. Take Discard
-- 2. Generate (2 + burden) new Fatigue Cards with new UUIDs (requires RandomGen)
-- 3. Update Registry with new Fatigue Cards
-- 4. Shuffle (Discard + NewFatigue) -> Deck
-- 5. Clear Discard
performFatigueCycle :: RandomGen g => Int -> g -> ActorState -> (ActorState, g)
performFatigueCycle burden gen st = 
  let 
    core = _coreState st
    sources = _discard core
    
    countNeeded = 2 + burden
    
    -- Recursive generator to get N UUIDs and final generator state
    genUUIDs :: RandomGen g => Int -> g -> ([UUID], g)
    genUUIDs 0 g_ = ([], g_)
    genUUIDs n g_ = 
        let (u, g1) = random @UUID g_
            (us, g2) = genUUIDs (n-1) g1
        in (u:us, g2)
        
    (newFatigueUUIDs, gen2) = genUUIDs countNeeded gen
    newFatigueIds = map CardInstanceId newFatigueUUIDs
    
    -- Update Registry
    newRegistryEntries = Map.fromList [ (cid, fatigueCard) | cid <- newFatigueIds ]
    updatedRegistry = Map.union (_coreRegistry st) newRegistryEntries
    
    -- Shuffle
    toShuffle = sources ++ newFatigueIds
    (newDeck, gen3) = shuffleList toShuffle gen2
    
    newCore = core 
      { _deck = newDeck
      , _discard = [] 
      }
      
  in (st { _coreState = newCore, _coreRegistry = updatedRegistry }, gen3)


