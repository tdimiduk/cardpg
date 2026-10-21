{-# LANGUAGE LambdaCase #-}

module Core.State where

import Data.Aeson (FromJSON (..), withObject, (.!=), (.:), (.:?))
import Data.Aeson.TH (deriveJSON, deriveToJSON)
import Data.List.NonEmpty (NonEmpty, toList)
import Data.Map.Strict (Map)
import Data.Map.Strict qualified as M
import Data.Maybe (isJust)
import Data.Text (Text)
import GHC.Generics (Generic)

import Core.Card
  ( CardInstance
  , ConsequenceCard
  , CoreCard
  , DefenseProfile (..)
  , ItemCard (..)
  , Keyword
  , NatureCard (..)
  , TalentCard (..)
  )
import Core.Card.Exploration
  ( ChallengeDef
  , ClockDeckId
  , ClockEffect
  , ClockEventCard
  , ClockEventId
  , ExitStatus
  , LocationCard
  , LocationId
  , ModuleId
  , TravelCard
  , TravelId
  )
import Core.Json (cardpgJsonDef)
import Core.NonEmptyText (NonEmptyText)
import Core.Primitives
  ( CardInstanceId (..)
  , CardLocation
  , ChallengeId (..)
  , EquipSlot (..)
  , Identified (..)
  , TargetId (..)
  )
import Core.RichText (RichText)
import Core.Stats
  ( ResourceType
  , Stats (..)
  )
import Core.Time (Duration, ExpeditionTime)

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

data ChallengeDomain
  = CombatTrauma
  | PhysicalLabor [Text]
  | EnvironmentalHazard [Text]
  deriving stock (Show, Eq, Generic)

$(deriveJSON cardpgJsonDef ''ChallengeDomain)

data ActiveChallenge = ActiveChallenge
  { id :: ChallengeId
  , source :: ChallengeSource
  , challengeStrength :: Int
  , challengeColor :: ResourceType
  , challengeDomain :: ChallengeDomain
  , consequencePool :: Maybe (NonEmpty Text)
  , timePerImpact :: Maybe Duration
  }
  deriving stock (Show, Eq, Generic)

$(deriveToJSON cardpgJsonDef ''ActiveChallenge)

instance FromJSON ActiveChallenge where
  parseJSON = withObject "ActiveChallenge" $ \o -> do
    cid <- o .: "id"
    src <- o .: "source"
    str <- o .: "challengeStrength"
    col <- o .: "challengeColor"
    dom <- o .:? "challengeDomain" .!= CombatTrauma
    pool <- o .:? "consequencePool"
    tpi <- o .:? "timePerImpact"
    pure $ ActiveChallenge cid src str col dom pool tpi

mkActiveChallenge :: ChallengeId -> ChallengeSource -> Int -> ResourceType -> ActiveChallenge
mkActiveChallenge cid src str col =
  ActiveChallenge
    { id = cid
    , source = src
    , challengeStrength = str
    , challengeColor = col
    , challengeDomain = CombatTrauma
    , consequencePool = Nothing
    , timePerImpact = Nothing
    }

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
  , vigilanceDial :: Int
  , vigilancePool :: [CardInstance CoreCard]
  , readiedCard :: Maybe (CardInstance CoreCard)
  , committedVigilance :: Bool
  }
  deriving stock (Show, Eq, Generic)

$(deriveToJSON cardpgJsonDef ''CoreCardState)

instance FromJSON CoreCardState where
  parseJSON = withObject "CoreCardState" $ \o -> do
    deck <- o .: "deck"
    hand <- o .: "hand"
    discard <- o .: "discard"
    planned <- o .:? "planned"
    defending <- o .:? "defending"
    inPlay <- o .:? "inPlay" .!= M.empty
    revealed <- o .:? "revealed"
    vigilanceDial <- o .:? "vigilanceDial" .!= 2
    vigilancePool <- o .:? "vigilancePool" .!= []
    readiedCard <- o .:? "readiedCard"
    committedVigilance <- o .:? "committedVigilance" .!= False
    pure CoreCardState{..}

emptyCoreCardState :: CoreCardState
emptyCoreCardState =
  CoreCardState
    { deck = []
    , hand = []
    , discard = []
    , planned = Nothing
    , defending = Nothing
    , inPlay = M.empty
    , revealed = Nothing
    , vigilanceDial = 2
    , vigilancePool = []
    , readiedCard = Nothing
    , committedVigilance = False
    }

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

data MapMode = MapModeGrid | MapModeRank
  deriving stock (Show, Eq, Ord, Generic)

$(deriveJSON cardpgJsonDef ''MapMode)

data BattleRank = FrontRank | BackRank
  deriving stock (Show, Eq, Ord, Generic)

$(deriveJSON cardpgJsonDef ''BattleRank)

data SpatialState = SpatialState
  { posX :: Int
  , posY :: Int
  , size :: Int
  , mapId :: Maybe Text
  , rank :: Maybe BattleRank
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
  , plannedRank :: Maybe (BattleRank, CardInstance CoreCard)
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
  | RankMovePlanned BattleRank
  | ActorRankMoved BattleRank
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
  | -- | Round number
    RoundStarted Int
  | -- | Vigilance Dial changed
    VigilanceDialSet Int
  | -- | Readied Card selected or cleared
    CardReadied (Maybe (CardInstance CoreCard))
  | -- | Vigilance committed to Hand
    VigilanceCommitted
  | -- | Vigilance flushed and refilled
    VigilanceFlushed
  deriving stock (Show, Eq, Generic)

$(deriveJSON cardpgJsonDef ''GameEvent)

data GameEnv = GameEnv
  { fatigueCardTemplate :: CoreCard
  , statusCardTemplates :: Map Text CoreCard
  , consequenceCardTemplates :: Map Text ConsequenceCard
  }
  deriving stock (Show, Eq, Generic)

$(deriveJSON cardpgJsonDef ''GameEnv)

--------------------------------------------------------------------------------
-- Exploration & World State
--------------------------------------------------------------------------------

data Direction = Forward | Reverse
  deriving stock (Show, Eq, Ord, Generic, Enum, Bounded)

$(deriveJSON cardpgJsonDef ''Direction)

data ExplorationFocus
  = AtLocation LocationId
  | OnTravel TravelId Direction
  deriving stock (Show, Eq, Generic)

$(deriveJSON cardpgJsonDef ''ExplorationFocus)

data ActiveClockEffect = ActiveClockEffect
  { effect :: ClockEffect
  , expiresAtMinute :: Maybe Int
  , sourceCard :: Maybe ClockEventId
  }
  deriving stock (Show, Eq, Generic)

$(deriveJSON cardpgJsonDef ''ActiveClockEffect)

data LocationRuntimeState = LocationRuntimeState
  { exitStatuses :: Map LocationId ExitStatus
  , activeEffects :: [ActiveClockEffect]
  , enabledActions :: [Text]
  , modifiedStrengths :: Map Text Int
  , spawnedActors :: [Text]
  }
  deriving stock (Show, Eq, Generic)

$(deriveJSON cardpgJsonDef ''LocationRuntimeState)

data ClockDeckState = ClockDeckState
  { drawPile :: [ClockEventCard]
  , discardPile :: [ClockEventCard]
  , tickInterval :: Duration
  , accumulatedMinutes :: Int
  }
  deriving stock (Show, Eq, Generic)

$(deriveJSON cardpgJsonDef ''ClockDeckState)

newtype LightSourceState = LightSourceState
  { activeLight :: Maybe (Text, Int)
  }
  deriving stock (Show, Eq, Generic)

$(deriveJSON cardpgJsonDef ''LightSourceState)

data TeamworkProgress = TeamworkProgress
  { activeChallenge :: ActiveChallenge
  , totalStrengthContributed :: Int
  , totalCardsFlipped :: Int
  , totalImpactTimeAdded :: Duration
  , participatingActors :: [Text]
  }
  deriving stock (Show, Eq, Generic)

$(deriveJSON cardpgJsonDef ''TeamworkProgress)

data WorldState = WorldState
  { moduleId :: Maybe ModuleId
  , time :: ExpeditionTime
  , focus :: ExplorationFocus
  , locations :: Map LocationId LocationCard
  , travelCards :: Map TravelId TravelCard
  , locationStates :: Map LocationId LocationRuntimeState
  , clockDecks :: Map ClockDeckId ClockDeckState
  , lightState :: LightSourceState
  , activeTeamworkChallenge :: Maybe TeamworkProgress
  }
  deriving stock (Show, Eq, Generic)

$(deriveToJSON cardpgJsonDef ''WorldState)

instance FromJSON WorldState where
  parseJSON = withObject "WorldState" $ \o -> do
    moduleId <- o .:? "moduleId"
    time <- o .: "time"
    focus <- o .: "focus"
    locations <- o .: "locations"
    travelCards <- o .: "travelCards"
    locationStates <- o .: "locationStates"
    clockDecks <- o .: "clockDecks"
    lightState <- o .: "lightState"
    activeTeamworkChallenge <- o .:? "activeTeamworkChallenge"
    pure WorldState{..}

data ExplorationEvent
  = TimeAdvanced Duration ExpeditionTime
  | LightFuelDecreased (Maybe (Text, Int))
  | LightExtinguished Text
  | ClockEffectExpired LocationId ActiveClockEffect
  | EffortCycleFlushed
  | ClockCardDrawn ClockDeckId ClockEventCard
  | ClockDeckShuffled ClockDeckId
  | ClockEffectApplied LocationId ClockEffect
  | ClockHazardTriggered LocationId ChallengeDef
  | ActorsSpawned LocationId [Text]
  | ExitStatusChanged LocationId LocationId ExitStatus
  | PartyMoved ExplorationFocus ExplorationFocus
  deriving stock (Show, Eq, Generic)

$(deriveJSON cardpgJsonDef ''ExplorationEvent)

isActorReady :: ActorState -> Bool
isActorReady as = isJust as.coreState.planned

isActorPC :: ActorState -> Bool
isActorPC as = as.actorType == "PC"

identifiedLookup :: (Ord id) => id -> Map id a -> Maybe (Identified id a)
identifiedLookup key m = Identified key <$> M.lookup key m

-- | Canonical field accessors for TableCard sum type
tableCardName :: TableCard -> NonEmptyText
tableCardName = \case
  TCItem ItemCard{name} -> name
  TCNature NatureCard{name} -> name
  TCTalent TalentCard{name} -> name

tableCardDefenses :: TableCard -> DefenseProfile
tableCardDefenses = \case
  TCItem ItemCard{defenses} -> defenses
  TCNature NatureCard{defenses} -> defenses
  TCTalent TalentCard{defenses} -> defenses

tableCardDefense :: TableCard -> Maybe Int
tableCardDefense tc = tableCardDefenses tc.defense

tableCardResilience :: TableCard -> Maybe Int
tableCardResilience tc = tableCardDefenses tc.resilience

tableCardBurden :: TableCard -> Maybe Int
tableCardBurden tc = tableCardDefenses tc.burden

tableCardTags :: TableCard -> Maybe (NonEmpty Keyword)
tableCardTags = \case
  TCItem ItemCard{tags} -> tags
  TCNature NatureCard{tags} -> tags
  TCTalent TalentCard{tags} -> tags

tableCardPassive :: TableCard -> Maybe Text
tableCardPassive = \case
  TCItem ItemCard{passive} -> passive
  TCNature NatureCard{passive} -> passive
  TCTalent TalentCard{passive} -> passive

tableCardFlavor :: TableCard -> Maybe RichText
tableCardFlavor = \case
  TCItem ItemCard{flavor} -> flavor
  TCNature NatureCard{flavor} -> flavor
  TCTalent TalentCard{flavor} -> flavor
