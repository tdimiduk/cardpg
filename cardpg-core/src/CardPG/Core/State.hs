module CardPG.Core.State where

import Data.Aeson.TH (deriveJSON)
import Data.Map.Strict (Map)
import Data.Map.Strict qualified as Map
import Data.Text (Text)
import GHC.Generics (Generic)

import CardPG.Core.Card (ConsequenceCard, CoreCard, ItemCard, NatureCard, TalentCard)
import CardPG.Core.Json (cardpgJsonDef)
import CardPG.Core.Primitives (CardInstanceId (..), EquipSlot (..), ResourceType, TargetId (..))

data TableCard
  = TCItem ItemCard
  | TCNature NatureCard
  | TCTalent TalentCard
  | TCConsequence ConsequenceCard
  deriving stock (Show, Eq, Generic)

$(deriveJSON cardpgJsonDef ''TableCard)

type CardRegistry c = Map CardInstanceId c

data CorePlayState
  = Stance -- Persistent effect on self
  | AttachedTo TargetId -- Buff/Debuff on Target (Actor/Token UUID)
  deriving stock (Show, Eq, Generic)

$(deriveJSON cardpgJsonDef ''CorePlayState)

data ActionStack = ActionStack
  { actionCard :: CardInstanceId
  , resources :: [CardInstanceId]
  }
  deriving stock (Show, Eq, Generic)

$(deriveJSON cardpgJsonDef ''ActionStack)

actionStack :: ActionStack -> [CardInstanceId]
actionStack (ActionStack ac res) = ac : res

data ActionStackMaterialized = ActionStackMaterialized
  { actionCard :: CoreCard
  , actionCardId :: CardInstanceId
  , resources :: [CoreCard]
  , resourcesIds :: [CardInstanceId]
  }
  deriving stock (Show, Eq, Generic)

materializeStack :: CardRegistry CoreCard -> ActionStack -> Maybe ActionStackMaterialized
materializeStack registry (ActionStack acId resIds) = do
  ac <- Map.lookup acId registry
  res <- traverse (`Map.lookup` registry) resIds
  return $ ActionStackMaterialized ac acId res resIds

dematerializeStack :: ActionStackMaterialized -> ActionStack
dematerializeStack (ActionStackMaterialized _ acId _ resIds) = ActionStack acId resIds

data RealizedAttack = RealizedAttack
  { attackCard :: CardInstanceId
  , attackStrength :: Int
  , defenseColor :: ResourceType
  }
  deriving stock (Show, Eq, Generic)

$(deriveJSON cardpgJsonDef ''RealizedAttack)

data CoreCardState = CoreCardState
  { deck :: [CardInstanceId] -- Top is head
  , hand :: [CardInstanceId] -- User-defined order
  , discard :: [CardInstanceId] -- Top is head (most recently played)
  , planned :: Maybe ActionStack
  , defending :: [CardInstanceId] -- Currently committed to a defense
  , inPlay :: Map CardInstanceId CorePlayState -- Buffs, Stances, Attached effects
  , registry :: CardRegistry CoreCard
  -- ^ The Registry (Source of Truth for Core Cards)
  }
  deriving stock (Show, Eq, Generic)

$(deriveJSON cardpgJsonDef ''CoreCardState)

data TableState = TableState
  { assets :: Map CardInstanceId AssetState
  , registry :: CardRegistry TableCard
  , consequences :: [CardInstanceId]
  , consequenceRegistry :: CardRegistry ConsequenceCard
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

data SpatialState = SpatialState
  { posX :: Int
  , posY :: Int
  , size :: Int
  , mapId :: Maybe Text
  }
  deriving stock (Show, Eq, Generic)

$(deriveJSON cardpgJsonDef ''SpatialState)

-- | The Authoritative State Container
data ActorState = ActorState
  { name :: Text
  , actorType :: Text
  , coreState :: CoreCardState -- Handles Core Cards (Deck/Hand/Discard)
  , tableState :: TableState -- Handles Table Cards (Equipment/Conditions)
  , spatial :: SpatialState
  , plannedMove :: Maybe (Int, Int)
  }
  deriving stock (Show, Eq, Generic)

$(deriveJSON cardpgJsonDef ''ActorState)

data GameEvent
  = CardsCreated [CardInstanceId]
  | DeckShuffled
  | CardDrawn CardInstanceId
  | CardDefended CardInstanceId
  | MovePlanned (Int, Int)
  | ActorMoved (Int, Int)
  | ActionPlanned ActionStack
  | PlanCanceled ActionStack
  | ActionRevealed ActionStack
  | DefenseEnded [CardInstanceId]
  | IllegalAction ActionStack (Maybe Text)
  deriving stock (Show, Eq, Generic)

$(deriveJSON cardpgJsonDef ''GameEvent)

data GameEnv = GameEnv
  { fatigueCardTemplate :: CoreCard
  , statusCardTemplates :: Map Text CoreCard
  , consequenceCardTemplates :: Map Text ConsequenceCard
  }
  deriving stock (Show, Eq, Generic)
