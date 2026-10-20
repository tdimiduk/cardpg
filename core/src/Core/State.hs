{-# LANGUAGE DataKinds #-}
{-# LANGUAGE FlexibleInstances #-}
{-# LANGUAGE LambdaCase #-}
{-# LANGUAGE MultiParamTypeClasses #-}
{-# LANGUAGE TypeApplications #-}

module Core.State where

import Data.Aeson (FromJSON (..), withObject, (.!=), (.:), (.:?))
import Data.Aeson.TH (deriveJSON, deriveToJSON)
import Data.List.NonEmpty (NonEmpty, toList)
import Data.Map.Strict (Map)
import Data.Map.Strict qualified as M
import Data.Maybe (isJust)
import Data.Text (Text)
import GHC.Generics (Generic)
import GHC.Records qualified

import Control.Lens qualified as L
import Core.Card
  ( CardInstance
  , ConsequenceCard
  , CoreCard
  , DefenseProfile (..)
  , ItemCard
  , Keyword
  , NatureCard
  , TalentCard
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
import Data.Generics.Product.Fields qualified as GPF

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

-- | Custom GHC.Records.HasField instance to support OverloadedRecordDot (.name) on TableCard
instance GHC.Records.HasField "name" TableCard NonEmptyText where
  getField = \case
    TCItem x -> L.view (GPF.field @"name") x
    TCNature x -> L.view (GPF.field @"name") x
    TCTalent x -> L.view (GPF.field @"name") x

-- | Custom GHC.Records.HasField instance to support OverloadedLabels (#name) on TableCard
instance GPF.HasField "name" TableCard TableCard NonEmptyText NonEmptyText where
  field = L.lens getter setter
    where
      getter = \case
        TCItem x -> L.view (GPF.field @"name") x
        TCNature x -> L.view (GPF.field @"name") x
        TCTalent x -> L.view (GPF.field @"name") x
      setter tc val = case tc of
        TCItem x -> TCItem (L.set (GPF.field @"name") val x)
        TCNature x -> TCNature (L.set (GPF.field @"name") val x)
        TCTalent x -> TCTalent (L.set (GPF.field @"name") val x)

-- | Custom instances for TableCard's passive field (Maybe Text)
instance GHC.Records.HasField "passive" TableCard (Maybe Text) where
  getField = \case
    TCItem x -> L.view (GPF.field @"passive") x
    TCNature x -> L.view (GPF.field @"passive") x
    TCTalent x -> L.view (GPF.field @"passive") x

instance GPF.HasField "passive" TableCard TableCard (Maybe Text) (Maybe Text) where
  field = L.lens getter setter
    where
      getter = \case
        TCItem x -> L.view (GPF.field @"passive") x
        TCNature x -> L.view (GPF.field @"passive") x
        TCTalent x -> L.view (GPF.field @"passive") x
      setter tc val = case tc of
        TCItem x -> TCItem (L.set (GPF.field @"passive") val x)
        TCNature x -> TCNature (L.set (GPF.field @"passive") val x)
        TCTalent x -> TCTalent (L.set (GPF.field @"passive") val x)

-- | Custom instances for TableCard's flavor field (Maybe RichText)
instance GHC.Records.HasField "flavor" TableCard (Maybe RichText) where
  getField = \case
    TCItem x -> L.view (GPF.field @"flavor") x
    TCNature x -> L.view (GPF.field @"flavor") x
    TCTalent x -> L.view (GPF.field @"flavor") x

instance GPF.HasField "flavor" TableCard TableCard (Maybe RichText) (Maybe RichText) where
  field = L.lens getter setter
    where
      getter = \case
        TCItem x -> L.view (GPF.field @"flavor") x
        TCNature x -> L.view (GPF.field @"flavor") x
        TCTalent x -> L.view (GPF.field @"flavor") x
      setter tc val = case tc of
        TCItem x -> TCItem (L.set (GPF.field @"flavor") val x)
        TCNature x -> TCNature (L.set (GPF.field @"flavor") val x)
        TCTalent x -> TCTalent (L.set (GPF.field @"flavor") val x)

-- | Custom instances for TableCard's defenses field (DefenseProfile)
instance {-# OVERLAPPING #-} GHC.Records.HasField "defenses" TableCard DefenseProfile where
  getField = \case
    TCItem x -> L.view (GPF.field @"defenses") x
    TCNature x -> L.view (GPF.field @"defenses") x
    TCTalent x -> L.view (GPF.field @"defenses") x

instance {-# OVERLAPPING #-} GPF.HasField "defenses" TableCard TableCard DefenseProfile DefenseProfile where
  field = L.lens getter setter
    where
      getter = \case
        TCItem x -> L.view (GPF.field @"defenses") x
        TCNature x -> L.view (GPF.field @"defenses") x
        TCTalent x -> L.view (GPF.field @"defenses") x
      setter tc val = case tc of
        TCItem x -> TCItem (L.set (GPF.field @"defenses") val x)
        TCNature x -> TCNature (L.set (GPF.field @"defenses") val x)
        TCTalent x -> TCTalent (L.set (GPF.field @"defenses") val x)

-- | Custom instances for TableCard's defense field (Maybe Int)
instance {-# OVERLAPPING #-} GHC.Records.HasField "defense" TableCard (Maybe Int) where
  getField = \case
    TCItem x -> x.defense
    TCNature x -> x.defense
    TCTalent x -> x.defense

instance {-# OVERLAPPING #-} GPF.HasField "defense" TableCard TableCard (Maybe Int) (Maybe Int) where
  field = L.lens getter setter
    where
      getter = \case
        TCItem x -> x.defense
        TCNature x -> x.defense
        TCTalent x -> x.defense
      setter tc val = case tc of
        TCItem x ->
          let cur = L.view (GPF.field @"defenses") x
           in TCItem (L.set (GPF.field @"defenses") (cur{defense = val}) x)
        TCNature x ->
          let cur = L.view (GPF.field @"defenses") x
           in TCNature (L.set (GPF.field @"defenses") (cur{defense = val}) x)
        TCTalent x ->
          let cur = L.view (GPF.field @"defenses") x
           in TCTalent (L.set (GPF.field @"defenses") (cur{defense = val}) x)

-- | Custom instances for TableCard's resilience field (Maybe Int)
instance {-# OVERLAPPING #-} GHC.Records.HasField "resilience" TableCard (Maybe Int) where
  getField = \case
    TCItem x -> x.resilience
    TCNature x -> x.resilience
    TCTalent x -> x.resilience

instance {-# OVERLAPPING #-} GPF.HasField "resilience" TableCard TableCard (Maybe Int) (Maybe Int) where
  field = L.lens getter setter
    where
      getter = \case
        TCItem x -> x.resilience
        TCNature x -> x.resilience
        TCTalent x -> x.resilience
      setter tc val = case tc of
        TCItem x ->
          let cur = L.view (GPF.field @"defenses") x
           in TCItem (L.set (GPF.field @"defenses") (cur{resilience = val}) x)
        TCNature x ->
          let cur = L.view (GPF.field @"defenses") x
           in TCNature (L.set (GPF.field @"defenses") (cur{resilience = val}) x)
        TCTalent x ->
          let cur = L.view (GPF.field @"defenses") x
           in TCTalent (L.set (GPF.field @"defenses") (cur{resilience = val}) x)

-- | Custom instances for TableCard's burden field (Maybe Int)
instance {-# OVERLAPPING #-} GHC.Records.HasField "burden" TableCard (Maybe Int) where
  getField = \case
    TCItem x -> x.burden
    TCNature x -> x.burden
    TCTalent x -> x.burden

instance {-# OVERLAPPING #-} GPF.HasField "burden" TableCard TableCard (Maybe Int) (Maybe Int) where
  field = L.lens getter setter
    where
      getter = \case
        TCItem x -> x.burden
        TCNature x -> x.burden
        TCTalent x -> x.burden
      setter tc val = case tc of
        TCItem x ->
          let cur = L.view (GPF.field @"defenses") x
           in TCItem (L.set (GPF.field @"defenses") (cur{burden = val}) x)
        TCNature x ->
          let cur = L.view (GPF.field @"defenses") x
           in TCNature (L.set (GPF.field @"defenses") (cur{burden = val}) x)
        TCTalent x ->
          let cur = L.view (GPF.field @"defenses") x
           in TCTalent (L.set (GPF.field @"defenses") (cur{burden = val}) x)

-- | Custom instances for TableCard's tags field (Maybe (NonEmpty Keyword))
instance {-# OVERLAPPING #-} GHC.Records.HasField "tags" TableCard (Maybe (NonEmpty Keyword)) where
  getField = \case
    TCItem x -> L.view (GPF.field @"tags") x
    TCNature x -> L.view (GPF.field @"tags") x
    TCTalent x -> L.view (GPF.field @"tags") x

instance {-# OVERLAPPING #-} GPF.HasField "tags" TableCard TableCard (Maybe (NonEmpty Keyword)) (Maybe (NonEmpty Keyword)) where
  field = L.lens getter setter
    where
      getter = \case
        TCItem x -> L.view (GPF.field @"tags") x
        TCNature x -> L.view (GPF.field @"tags") x
        TCTalent x -> L.view (GPF.field @"tags") x
      setter tc val = case tc of
        TCItem x -> TCItem (L.set (GPF.field @"tags") val x)
        TCNature x -> TCNature (L.set (GPF.field @"tags") val x)
        TCTalent x -> TCTalent (L.set (GPF.field @"tags") val x)
