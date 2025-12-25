{-# LANGUAGE DuplicateRecordFields #-}
{-# LANGUAGE RecordWildCards #-}

-- | Frontend types shared with the client.
-- These types are explicit DTOs (Data Transfer Objects) that decouple
-- the internal Core representation from the external API contract.
--
-- Key features:
-- 1. Flattened IDs: 'id' is a field on the record, not a wrapper.
-- 2. Explicit JSON: We use standard Generic deriving without complex custom options.
-- 3. Stability: Changes to Core don't automatically break Frontend.
module CardPG.Server.Types.Frontend
  ( -- * Actors
    ActorState (..)
  , DefenseDetails (..)

    -- * Cards
  , CoreCard (..)
  , TableCard (..)
  , ItemCard (..)
  , NatureCard (..)
  , TalentCard (..)
  , ConsequenceCard (..)

    -- * State Containers
  , CoreCardState (..)
  , TableState (..)

    -- * Events & Actions
  , GameEvent (..)
  , ActionStack (..)
  , NarrativeStack (..)
  , PlannedAction (..)

    -- * Converters
  , toActorState
  , toGameEvent
  , toPlannedAction
  , toCoreCard
  , toTableCard
  , toConsequenceCard
  ) where

import Data.Aeson.TH (deriveJSON)
import Data.Bifunctor qualified
import Data.List.NonEmpty (NonEmpty, toList)
import Data.Map.Strict qualified as Map
import Data.Text (Text)
import GHC.Generics (Generic)

import CardPG.Core.Card (DSLRule, Rule)
import CardPG.Core.Card qualified as Core
import CardPG.Core.Json (cardpgJsonDef, cardpgTaggedOptions)
import CardPG.Core.Logic.Combat (computeDefense, computeResilience)
import CardPG.Core.NonEmptyText (NonEmptyText)
import CardPG.Core.Primitives (CardInstanceId, CardLocation, ResourceType, Stats (..))
import CardPG.Core.RichText (RichString, RichText)
import CardPG.Core.State
  ( AssetState
  , CorePlayState
  , RevealedEffect
  , SpatialState
  )
import CardPG.Core.State qualified as Core

-- * Cards (Explicit DTOs)

-- | Frontend version of 'Core.CoreCard' with ID flattened.
data CoreCard = CoreCard
  { id :: CardInstanceId
  , name :: NonEmptyText
  , tags :: Maybe (NonEmpty Text)
  , stats :: Stats Int
  , cost :: Maybe Int
  , rules :: Maybe (NonEmpty Rule)
  , flavor :: Maybe RichText
  }
  deriving (Show, Eq, Generic)

$(deriveJSON cardpgJsonDef ''CoreCard)

-- | Frontend version of 'Core.ItemCard' with ID flattened.
data ItemCard = ItemCard
  { id :: CardInstanceId
  , name :: NonEmptyText
  , tags :: Maybe (NonEmpty Text)
  , flavor :: Maybe RichText
  , weight :: Maybe Int
  , value :: Maybe Int
  , traits :: Maybe (NonEmpty Text)
  , passive :: Maybe Text
  , defense :: Maybe Int
  , resilience :: Maybe Int
  , burden :: Maybe Int
  }
  deriving (Show, Eq, Generic)

$(deriveJSON cardpgJsonDef ''ItemCard)

-- | Frontend version of 'Core.NatureCard' with ID flattened.
data NatureCard = NatureCard
  { id :: CardInstanceId
  , name :: NonEmptyText
  , tags :: Maybe (NonEmpty Text)
  , flavor :: Maybe RichText
  , traits :: Maybe (NonEmpty Text)
  , passive :: Maybe Text
  , defense :: Maybe Int
  , resilience :: Maybe Int
  , specialDefend :: Maybe Core.SpecialDefend
  }
  deriving (Show, Eq, Generic)

$(deriveJSON cardpgJsonDef ''NatureCard)

-- | Frontend version of 'Core.TalentCard' with ID flattened.
data TalentCard = TalentCard
  { id :: CardInstanceId
  , name :: NonEmptyText
  , tags :: Maybe (NonEmpty Text)
  , flavor :: Maybe RichText
  , traits :: Maybe (NonEmpty Text)
  , passive :: Maybe Text
  , defense :: Maybe Int
  , resilience :: Maybe Int
  }
  deriving (Show, Eq, Generic)

$(deriveJSON cardpgJsonDef ''TalentCard)

-- | Flattened discriminated union for Table Cards.
data TableCard
  = TCItem ItemCard
  | TCNature NatureCard
  | TCTalent TalentCard
  deriving (Show, Eq, Generic)

$(deriveJSON (cardpgTaggedOptions "TC") ''TableCard)

-- | Frontend version of 'Core.ConsequenceCard' with ID flattened.
data ConsequenceCard = ConsequenceCard
  { id :: CardInstanceId
  , name :: NonEmptyText
  , tags :: Maybe (NonEmpty Text)
  , passive :: Maybe Text
  , effects :: Maybe (NonEmpty Text)
  , severity :: Int
  , notes :: Maybe Text
  , rules :: Maybe (NonEmpty Rule)
  }
  deriving (Show, Eq, Generic)

$(deriveJSON cardpgJsonDef ''ConsequenceCard)

-- * Converters

toCoreCard :: Core.CardInstance Core.CoreCard -> CoreCard
toCoreCard (Core.Identified id Core.CoreCard{..}) = CoreCard{..}

toItemCard :: Core.CardInstance Core.ItemCard -> ItemCard
toItemCard (Core.Identified id Core.ItemCard{..}) = ItemCard{..}

toNatureCard :: Core.CardInstance Core.NatureCard -> NatureCard
toNatureCard (Core.Identified id Core.NatureCard{..}) = NatureCard{..}

toTalentCard :: Core.CardInstance Core.TalentCard -> TalentCard
toTalentCard (Core.Identified id Core.TalentCard{..}) = TalentCard{..}

toTableCard :: Core.CardInstance Core.TableCard -> TableCard
toTableCard (Core.Identified id (Core.TCItem c)) = TCItem $ toItemCard (Core.Identified id c)
toTableCard (Core.Identified id (Core.TCNature c)) = TCNature $ toNatureCard (Core.Identified id c)
toTableCard (Core.Identified id (Core.TCTalent c)) = TCTalent $ toTalentCard (Core.Identified id c)

toConsequenceCard :: Core.CardInstance Core.ConsequenceCard -> ConsequenceCard
toConsequenceCard (Core.Identified id Core.ConsequenceCard{..}) = ConsequenceCard{..}

-- * State Containers (Frontend Versions)

data ActionStack = ActionStack
  { actionCard :: CoreCard
  , resources :: [CoreCard]
  }
  deriving (Show, Eq, Generic)

$(deriveJSON cardpgJsonDef ''ActionStack)

data NarrativeStack = NarrativeStack
  { cards :: [CoreCard]
  , color :: ResourceType
  }
  deriving (Show, Eq, Generic)
$(deriveJSON cardpgJsonDef ''NarrativeStack)

data PlannedAction
  = PStandard ActionStack
  | PNarrative NarrativeStack
  | PPass
  deriving (Show, Eq, Generic)
$(deriveJSON cardpgJsonDef ''PlannedAction)

-- | Mirrors Core.CoreCardState but uses Frontend CoreCard
data CoreCardState = CoreCardState
  { deck :: [CoreCard]
  , hand :: [CoreCard]
  , discard :: [CoreCard]
  , planned :: Maybe PlannedAction
  , defending :: [CoreCard]
  , inPlay :: Map.Map CardInstanceId (CoreCard, CorePlayState)
  , revealed :: Maybe RevealedEffect
  }
  deriving (Show, Eq, Generic)

$(deriveJSON cardpgJsonDef ''CoreCardState)

-- | Mirrors Core.TableState but uses Frontend TableCard/ConsequenceCard
data TableState = TableState
  { assets :: Map.Map CardInstanceId (TableCard, AssetState)
  , consequences :: [ConsequenceCard]
  }
  deriving (Show, Eq, Generic)

$(deriveJSON cardpgJsonDef ''TableState)

toPlannedAction :: Core.PlannedAction -> PlannedAction
toPlannedAction (Core.PStandard (Core.ActionStack ac res)) =
  PStandard $ ActionStack (toCoreCard ac) (map toCoreCard res)
toPlannedAction (Core.PNarrative (Core.NarrativeStack cs col)) =
  PNarrative $ NarrativeStack (map toCoreCard (toList cs)) col
toPlannedAction Core.PPass = PPass

data DefenseDetails = DefenseDetails
  { values :: Stats Int
  , impact :: Int
  , consequencesFromDefense :: Int
  , nextSeverity :: Int
  }
  deriving (Show, Eq, Generic)

$(deriveJSON cardpgJsonDef ''DefenseDetails)

data ActorState = ActorState
  { name :: Text
  , actorType :: Text
  , coreState :: CoreCardState
  , tableState :: TableState
  , spatial :: SpatialState
  , plannedMove :: Maybe (Int, Int)
  , -- Computed fields
    defense :: Int
  , resilience :: Int
  , defenseDetails :: DefenseDetails
  }
  deriving (Show, Eq, Generic)

$(deriveJSON cardpgJsonDef ''ActorState)

toActorState :: Core.ActorState -> ActorState
toActorState Core.ActorState{..} =
  let
    frontendCoreState =
      CoreCardState
        { deck = map toCoreCard coreState.deck
        , hand = map toCoreCard coreState.hand
        , discard = map toCoreCard coreState.discard
        , planned = fmap toPlannedAction coreState.planned
        , defending = map toCoreCard coreState.defending
        , inPlay = Map.map (Data.Bifunctor.first toCoreCard) coreState.inPlay
        , revealed = coreState.revealed
        }

    frontendTableState =
      TableState
        { assets = Map.map (Data.Bifunctor.first toTableCard) tableState.assets
        , consequences = map toConsequenceCard tableState.consequences
        }

    -- Calculation logic stays the same
    defStat = computeDefense tableState
    resStat = computeResilience tableState
    defendingCards = coreState.defending
    defRed = sum [c.content.stats.red | c <- defendingCards]
    defYellow = sum [c.content.stats.yellow | c <- defendingCards]
    defBlue = sum [c.content.stats.blue | c <- defendingCards]
    impactVal = length defendingCards
    consequencesVal = if defStat > 0 then impactVal `div` defStat else impactVal
    currentConsequences = length tableState.consequences
    nextSeverityVal =
      if resStat > 0
        then ((currentConsequences + consequencesVal) `div` resStat) + 1
        else currentConsequences + consequencesVal + 1

    details =
      DefenseDetails
        { values = Stats{red = defRed, yellow = defYellow, blue = defBlue}
        , impact = impactVal
        , consequencesFromDefense = consequencesVal
        , nextSeverity = nextSeverityVal
        }
   in
    ActorState
      { defense = defStat
      , resilience = resStat
      , defenseDetails = details
      , coreState = frontendCoreState
      , tableState = frontendTableState
      , ..
      }

data GameEvent
  = CardsCreated [CoreCard]
  | DeckShuffled
  | CardDrawn CoreCard
  | CardDefended CoreCard
  | MovePlanned (Int, Int)
  | ActorMoved (Int, Int)
  | ActionPlanned PlannedAction
  | PlanCanceled PlannedAction
  | ActionRevealed PlannedAction RevealedEffect
  | DefenseEnded [CoreCard]
  | IllegalAction PlannedAction (Maybe Text)
  | StatusAdded Text CardLocation
  | StatusRemoved Text Text
  | ConsequenceAdded ConsequenceCard
  | ConsequenceRemoved Text
  deriving (Show, Eq, Generic)

$(deriveJSON cardpgJsonDef ''GameEvent)

toGameEvent :: Core.GameEvent -> GameEvent
toGameEvent (Core.CardsCreated cs) = CardsCreated (map toCoreCard cs)
toGameEvent Core.DeckShuffled = DeckShuffled
toGameEvent (Core.CardDrawn c) = CardDrawn (toCoreCard c)
toGameEvent (Core.CardDefended c) = CardDefended (toCoreCard c)
toGameEvent (Core.MovePlanned p) = MovePlanned p
toGameEvent (Core.ActorMoved p) = ActorMoved p
toGameEvent (Core.ActionPlanned p) = ActionPlanned (toPlannedAction p)
toGameEvent (Core.PlanCanceled p) = PlanCanceled (toPlannedAction p)
toGameEvent (Core.ActionRevealed p r) = ActionRevealed (toPlannedAction p) r
toGameEvent (Core.DefenseEnded cs) = DefenseEnded (map toCoreCard cs)
toGameEvent (Core.IllegalAction p t) = IllegalAction (toPlannedAction p) t
toGameEvent (Core.StatusAdded t l) = StatusAdded t l
toGameEvent (Core.StatusRemoved t l) = StatusRemoved t l
toGameEvent (Core.ConsequenceAdded c) = ConsequenceAdded (toConsequenceCard c)
toGameEvent (Core.ConsequenceRemoved t) = ConsequenceRemoved t
