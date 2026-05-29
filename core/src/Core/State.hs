{-# LANGUAGE DataKinds #-}
{-# LANGUAGE FlexibleInstances #-}
{-# LANGUAGE LambdaCase #-}
{-# LANGUAGE MultiParamTypeClasses #-}
{-# LANGUAGE TypeApplications #-}

module Core.State where

import Data.Aeson.TH (deriveJSON)
import Data.List.NonEmpty (NonEmpty, toList)
import Data.Map.Strict (Map)
import Data.Map.Strict qualified as M
import Data.Maybe (isJust)
import Data.Text (Text)
import GHC.Generics (Generic)
import GHC.Records qualified

import Control.Lens qualified as L
import Core.Card (CardInstance, ConsequenceCard, CoreCard, ItemCard, NatureCard, TalentCard)
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

-- | Custom instances for TableCard's traits field (Maybe (NonEmpty Text))
instance GHC.Records.HasField "traits" TableCard (Maybe (NonEmpty Text)) where
  getField = \case
    TCItem x -> L.view (GPF.field @"traits") x
    TCNature x -> L.view (GPF.field @"traits") x
    TCTalent x -> L.view (GPF.field @"traits") x

instance GPF.HasField "traits" TableCard TableCard (Maybe (NonEmpty Text)) (Maybe (NonEmpty Text)) where
  field = L.lens getter setter
    where
      getter = \case
        TCItem x -> L.view (GPF.field @"traits") x
        TCNature x -> L.view (GPF.field @"traits") x
        TCTalent x -> L.view (GPF.field @"traits") x
      setter tc val = case tc of
        TCItem x -> TCItem (L.set (GPF.field @"traits") val x)
        TCNature x -> TCNature (L.set (GPF.field @"traits") val x)
        TCTalent x -> TCTalent (L.set (GPF.field @"traits") val x)

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

-- | Custom instances for TableCard's defense field (Maybe Int)
instance GHC.Records.HasField "defense" TableCard (Maybe Int) where
  getField = \case
    TCItem x -> L.view (GPF.field @"defense") x
    TCNature x -> L.view (GPF.field @"defense") x
    TCTalent x -> L.view (GPF.field @"defense") x

instance GPF.HasField "defense" TableCard TableCard (Maybe Int) (Maybe Int) where
  field = L.lens getter setter
    where
      getter = \case
        TCItem x -> L.view (GPF.field @"defense") x
        TCNature x -> L.view (GPF.field @"defense") x
        TCTalent x -> L.view (GPF.field @"defense") x
      setter tc val = case tc of
        TCItem x -> TCItem (L.set (GPF.field @"defense") val x)
        TCNature x -> TCNature (L.set (GPF.field @"defense") val x)
        TCTalent x -> TCTalent (L.set (GPF.field @"defense") val x)

-- | Custom instances for TableCard's resilience field (Maybe Int)
instance GHC.Records.HasField "resilience" TableCard (Maybe Int) where
  getField = \case
    TCItem x -> L.view (GPF.field @"resilience") x
    TCNature x -> L.view (GPF.field @"resilience") x
    TCTalent x -> L.view (GPF.field @"resilience") x

instance GPF.HasField "resilience" TableCard TableCard (Maybe Int) (Maybe Int) where
  field = L.lens getter setter
    where
      getter = \case
        TCItem x -> L.view (GPF.field @"resilience") x
        TCNature x -> L.view (GPF.field @"resilience") x
        TCTalent x -> L.view (GPF.field @"resilience") x
      setter tc val = case tc of
        TCItem x -> TCItem (L.set (GPF.field @"resilience") val x)
        TCNature x -> TCNature (L.set (GPF.field @"resilience") val x)
        TCTalent x -> TCTalent (L.set (GPF.field @"resilience") val x)

-- | Custom instances for TableCard's tags field (Maybe (NonEmpty Text))
instance GHC.Records.HasField "tags" TableCard (Maybe (NonEmpty Text)) where
  getField = \case
    TCItem x -> L.view (GPF.field @"tags") x
    TCNature x -> L.view (GPF.field @"tags") x
    TCTalent x -> L.view (GPF.field @"tags") x

instance GPF.HasField "tags" TableCard TableCard (Maybe (NonEmpty Text)) (Maybe (NonEmpty Text)) where
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
