{-# LANGUAGE DuplicateRecordFields #-}
{-# LANGUAGE RecordWildCards #-}

-- | Frontend types shared with the react client, do not use this from reflex code.
-- These types are explicit DTOs (Data Transfer Objects) that decouple
-- the internal Core representation from the external API contract.
--
-- Key features:
-- 1. Flattened IDs: 'id' is a field on the record, not a wrapper.
-- 2. Explicit JSON: We use standard Generic deriving without complex custom options.
-- 3. Stability: Changes to Core don't automatically break Frontend.
module CardPG.Api.Frontend
  ( -- * Actors
    ActorState (..)
  , ActiveDefense (..)
  , ActiveChallenge (..)
  , ChallengeSource (..)
  , DefenseDetails (..)

    -- * Cards
  , CoreCard (..)
  , TableCard (..)
  , ItemCard (..)
  , NatureCard (..)
  , TalentCard (..)
  , ConsequenceCard (..)
  , LogCard (..)
  , Rule (..)

    -- * State Containers
  , CoreCardState (..)
  , TableState (..)

    -- * Events & Actions
  , GameEvent (..)
  , IllegalActionDetails (..)
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
  , toDefenseDetails
  ) where

import Data.Aeson.TH (deriveJSON)
import Data.Bifunctor qualified
import Data.List.NonEmpty (NonEmpty, toList)
import Data.Map.Strict qualified as Map
import Data.Text (Text)
import GHC.Generics (Generic)

import CardPG.Core.Card qualified as Core
import CardPG.Core.Json (cardpgJsonDef, cardpgJsonOptions, cardpgTaggedOptions)
import CardPG.Core.Logic.Combat (computeDefense, computeDefenseDetails, computeResilience)
import CardPG.Core.NonEmptyText (NonEmptyText)
import CardPG.Core.Primitives (CardInstanceId, CardLocation, ChallengeId)
import CardPG.Core.RichText (RichText)
import CardPG.Core.RuleDefs
  ( AttackDef
  , GeneralDef
  , OngoingDef
  , PassiveDef
  , TaskDef
  , TriggerDef
  )
import CardPG.Core.RuleDefs qualified as Core
import CardPG.Core.State
  ( AssetState
  , CorePlayState
  , RevealedEffect
  , SpatialState
  )
import CardPG.Core.State qualified as Core
import CardPG.Core.Stats (ResourceType, Stats (..))

-- * Cards (Explicit DTOs)

-- | Frontend version of 'Core.Rule' (Explicit DTO, forces Object encoding)
data Rule
  = RuleAttack AttackDef
  | RuleGeneral GeneralDef
  | RuleTask TaskDef
  | RuleTrigger TriggerDef
  | RuleOngoing OngoingDef
  | RuleNarrative RichText
  | RulePassive PassiveDef
  deriving (Show, Eq, Generic)

$(deriveJSON (cardpgJsonOptions "Rule") ''Rule)

-- | Frontend version of 'Core.DefenseDetails'
data DefenseDetails = DefenseDetails
  { values :: Stats Int
  , impact :: Int
  , consequencesFromDefense :: Int
  , nextSeverity :: Int
  }
  deriving (Show, Eq, Generic)

$(deriveJSON cardpgJsonDef ''DefenseDetails)

toDefenseDetails :: Core.DefenseDetails -> DefenseDetails
toDefenseDetails Core.DefenseDetails{..} = DefenseDetails{..}

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
toCoreCard (Core.Identified id Core.CoreCard{..}) =
  CoreCard
    { rules = fmap (fmap toRule) rules
    , ..
    }

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
toConsequenceCard (Core.Identified id Core.ConsequenceCard{..}) =
  ConsequenceCard
    { rules = fmap (fmap toRule) rules
    , ..
    }

toRule :: Core.Rule -> Rule
toRule (Core.RuleAttack d) = RuleAttack d
toRule (Core.RuleGeneral d) = RuleGeneral d
toRule (Core.RuleTask d) = RuleTask d
toRule (Core.RuleTrigger d) = RuleTrigger d
toRule (Core.RuleOngoing d) = RuleOngoing d
toRule (Core.RuleNarrative d) = RuleNarrative d
toRule (Core.RulePassive d) = RulePassive d

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

data ChallengeSource
  = CSAdHoc {name :: Text, description :: Maybe Text}
  | CSCard CardInstanceId
  deriving (Show, Eq, Generic)

$(deriveJSON cardpgJsonDef ''ChallengeSource)

data ActiveChallenge = ActiveChallenge
  { id :: ChallengeId
  , source :: ChallengeSource
  , challengeStrength :: Int
  , challengeColor :: ResourceType
  }
  deriving (Show, Eq, Generic)

$(deriveJSON cardpgJsonDef ''ActiveChallenge)

data ActiveDefense = ActiveDefense
  { activeChallenge :: ActiveChallenge
  , cards :: [CoreCard]
  }
  deriving (Show, Eq, Generic)

$(deriveJSON cardpgJsonDef ''ActiveDefense)

data LogCard = LogCard
  { name :: Text
  , color :: ResourceType
  , power :: Int
  }
  deriving (Show, Eq, Generic)

$(deriveJSON cardpgJsonDef ''LogCard)

-- | Mirrors Core.CoreCardState but uses Frontend CoreCard
data CoreCardState = CoreCardState
  { deck :: [CoreCard]
  , hand :: [CoreCard]
  , discard :: [CoreCard]
  , planned :: Maybe PlannedAction
  , defending :: Maybe ActiveDefense
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

toActiveChallenge :: Core.ActiveChallenge -> ActiveChallenge
toActiveChallenge Core.ActiveChallenge{..} =
  ActiveChallenge
    { source = toChallengeSource source
    , ..
    }

toChallengeSource :: Core.ChallengeSource -> ChallengeSource
toChallengeSource (Core.CSAdHoc n d) = CSAdHoc n d
toChallengeSource (Core.CSCard c) = CSCard c

toActorState :: Core.ActorState -> ActorState
toActorState Core.ActorState{..} =
  let
    frontendCoreState =
      CoreCardState
        { deck = map toCoreCard coreState.deck
        , hand = map toCoreCard coreState.hand
        , discard = map toCoreCard coreState.discard
        , planned = fmap toPlannedAction coreState.planned
        , defending = case coreState.defending of
            Nothing -> Nothing
            Just (Core.ActiveDefense coreChallenge cards) ->
              Just (ActiveDefense (toActiveChallenge coreChallenge) (map toCoreCard cards))
        , inPlay = Map.map (Data.Bifunctor.first toCoreCard) coreState.inPlay
        , revealed = coreState.revealed
        }

    frontendTableState =
      TableState
        { assets = Map.map (Data.Bifunctor.first toTableCard) tableState.assets
        , consequences = map toConsequenceCard tableState.consequences
        }

    details = toDefenseDetails $ computeDefenseDetails Core.ActorState{..}
    defStat = computeDefense tableState
    resStat = computeResilience tableState
   in
    ActorState
      { defense = defStat
      , resilience = resStat
      , defenseDetails = details
      , coreState = frontendCoreState
      , tableState = frontendTableState
      , ..
      }

data IllegalActionDetails = IllegalActionDetails
  { planned :: Maybe PlannedAction
  , reason :: Maybe Text
  }
  deriving (Show, Eq, Generic)

$(deriveJSON cardpgJsonDef ''IllegalActionDetails)

data GameEvent
  = CardsCreated [CoreCard]
  | DeckShuffled
  | CardDrawn CoreCard
  | CardDefended ActiveChallenge CoreCard
  | MovePlanned (Int, Int)
  | ActorMoved (Int, Int)
  | ActionPlanned PlannedAction
  | PlanCanceled PlannedAction
  | ActionRevealed PlannedAction RevealedEffect
  | DefenseEnded ActiveDefense DefenseDetails
  | IllegalAction IllegalActionDetails
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
toGameEvent (Core.CardDefended chal c) = CardDefended (toActiveChallenge chal) (toCoreCard c)
toGameEvent (Core.MovePlanned p) = MovePlanned p
toGameEvent (Core.ActorMoved p) = ActorMoved p
toGameEvent (Core.ActionPlanned p) = ActionPlanned (toPlannedAction p)
toGameEvent (Core.PlanCanceled p) = PlanCanceled (toPlannedAction p)
toGameEvent (Core.ActionRevealed p r) = ActionRevealed (toPlannedAction p) r
toGameEvent (Core.DefenseEnded (Core.ActiveDefense chal cards) details) =
  DefenseEnded
    (ActiveDefense (toActiveChallenge chal) (map toCoreCard cards))
    (toDefenseDetails details)
toGameEvent (Core.IllegalAction Core.IllegalActionDetails{..}) =
  IllegalAction (IllegalActionDetails (fmap toPlannedAction planned) reason)
toGameEvent (Core.StatusAdded t l) = StatusAdded t l
toGameEvent (Core.StatusRemoved t l) = StatusRemoved t l
toGameEvent (Core.ConsequenceAdded c) = ConsequenceAdded (toConsequenceCard c)
toGameEvent (Core.ConsequenceRemoved t) = ConsequenceRemoved t
