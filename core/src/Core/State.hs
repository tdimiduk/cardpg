module Core.State where

import Data.Aeson.TH (deriveJSON)
import Data.List.NonEmpty (NonEmpty, toList)
import Data.Map.Strict (Map)
import Data.Map.Strict qualified as M
import Data.Maybe (isJust)
import Data.Text (Text)
import GHC.Generics (Generic)

import Core.Card (CardInstance, ConsequenceCard, CoreCard, ItemCard, NatureCard, TalentCard)
import Core.Json (cardpgJsonDef)
import Core.Primitives
  ( CardInstanceId (..)
  , CardLocation
  , ChallengeId (..)
  , EquipSlot (..)
  , Identified (..)
  , TargetId (..)
  )
import Core.Stats
  ( ResourceType
  , Stats (..)
  )

data DefenseDetails = DefenseDetails
  { values :: Stats Int
  , impact :: Int
  , consequencesFromDefense :: Int
  , nextSeverity :: Int
  }
  deriving stock (Show, Eq, Generic)

$(deriveJSON cardpgJsonDef ''DefenseDetails)

data TableCard
  = TCItem ItemCard
  | TCNature NatureCard
  | TCTalent TalentCard
  deriving stock (Show, Eq, Generic)

$(deriveJSON cardpgJsonDef ''TableCard)

data CorePlayState
  = Ongoing -- Persistent effect on self
  | AttachedTo TargetId -- Buff/Debuff on Target (Actor/Token UUID)
  deriving stock (Show, Eq, Generic)

$(deriveJSON cardpgJsonDef ''CorePlayState)

data ActionStack = ActionStack
  { actionCard :: CardInstance CoreCard
  , resources :: [CardInstance CoreCard]
  }
  deriving stock (Show, Eq, Generic)

$(deriveJSON cardpgJsonDef ''ActionStack)

data NarrativeStack = NarrativeStack
  { cards :: NonEmpty (CardInstance CoreCard)
  , color :: ResourceType
  }
  deriving stock (Show, Eq, Generic)

$(deriveJSON cardpgJsonDef ''NarrativeStack)

data PlannedAction
  = PStandard ActionStack
  | PNarrative NarrativeStack
  | PPass
  deriving stock (Show, Eq, Generic)

$(deriveJSON cardpgJsonDef ''PlannedAction)

plannedActionCards :: PlannedAction -> [CardInstance CoreCard]
plannedActionCards (PStandard (ActionStack ac res)) = ac : res
plannedActionCards (PNarrative (NarrativeStack cs _)) = toList cs
plannedActionCards PPass = []

data ChallengeSource
  = CSAdHoc {name :: Text, description :: Maybe Text}
  | CSCard CardInstanceId
  deriving stock (Show, Eq, Generic)

$(deriveJSON cardpgJsonDef ''ChallengeSource)

data ActiveChallenge = ActiveChallenge
  { id :: ChallengeId
  , source :: ChallengeSource
  , challengeStrength :: Int
  , challengeColor :: ResourceType
  }
  deriving stock (Show, Eq, Generic)

$(deriveJSON cardpgJsonDef ''ActiveChallenge)

data RevealedEffect
  = REPass
  | REChallenge ActiveChallenge
  | REInvalid Text
  deriving stock (Show, Eq, Generic)

$(deriveJSON cardpgJsonDef ''RevealedEffect)

data ActiveDefense = ActiveDefense
  { activeChallenge :: ActiveChallenge
  , cards :: [CardInstance CoreCard]
  }
  deriving stock (Show, Eq, Generic)

$(deriveJSON cardpgJsonDef ''ActiveDefense)

data CoreCardState = CoreCardState
  { deck :: [CardInstance CoreCard] -- Top is head
  , hand :: [CardInstance CoreCard] -- User-defined order
  , discard :: [CardInstance CoreCard] -- Top is head (most recently played)
  , planned :: Maybe PlannedAction
  , defending :: Maybe ActiveDefense -- Currently committed to a defense
  , inPlay :: Map CardInstanceId (CardInstance CoreCard, CorePlayState) -- Buffs, Stances, Attached effects
  , revealed :: Maybe RevealedEffect
  }
  deriving stock (Show, Eq, Generic)

$(deriveJSON cardpgJsonDef ''CoreCardState)

data TableState = TableState
  { assets :: Map CardInstanceId (CardInstance TableCard, AssetState)
  , consequences :: [CardInstance ConsequenceCard]
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

data IllegalActionDetails = IllegalActionDetails
  { planned :: Maybe PlannedAction
  , reason :: Maybe Text
  }
  deriving stock (Show, Eq, Generic)

$(deriveJSON cardpgJsonDef ''IllegalActionDetails)

data GameEvent
  = CardsCreated [CardInstance CoreCard]
  | DeckShuffled
  | CardDrawn (CardInstance CoreCard)
  | CardDefended ActiveChallenge (CardInstance CoreCard)
  | MovePlanned (Int, Int)
  | ActorMoved (Int, Int)
  | ActionPlanned PlannedAction
  | PlanCanceled PlannedAction
  | ActionRevealed PlannedAction RevealedEffect
  | DefenseEnded ActiveDefense DefenseDetails
  | IllegalAction IllegalActionDetails
  | -- | Type, Destination
    StatusAdded Text CardLocation
  | -- | Type, Destination
    StatusRemoved Text Text
  | -- | Severity
    ConsequenceAdded (CardInstance ConsequenceCard)
  | -- | Card ID/Name
    ConsequenceRemoved Text
  deriving stock (Show, Eq, Generic)

$(deriveJSON cardpgJsonDef ''GameEvent)

data GameEnv = GameEnv
  { fatigueCardTemplate :: CoreCard
  , statusCardTemplates :: Map Text CoreCard
  , consequenceCardTemplates :: Map Text ConsequenceCard
  }
  deriving stock (Show, Eq, Generic)

$(deriveJSON cardpgJsonDef ''GameEnv)

isActorReady :: ActorState -> Bool
isActorReady as = isJust as.coreState.planned

isActorPC :: ActorState -> Bool
isActorPC as = as.actorType == "PC"

identifiedLookup :: (Ord id) => id -> Map id a -> Maybe (Identified id a)
identifiedLookup key m = Identified key <$> M.lookup key m
