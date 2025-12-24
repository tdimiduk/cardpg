-- | Wire types for client communication.
-- These types are enriched versions of core types, with computed fields baked in.
-- Import qualified as @Wire@ when both core and wire types are needed:
--
-- @
-- import CardPG.Core.State qualified as Core
-- import CardPG.Server.Types.Wire qualified as Wire
-- @
module CardPG.Server.Types.Wire
  ( ActorState (..)
  , DefenseDetails (..)
  , CoreCardInstance (..)
  , TableCardInstance (..)
  , ConsequenceCardInstance (..)
  , CoreCardState (..)
  , TableState (..)
  , GameEvent (..)
  , ActionStack (..)
  , NarrativeStack (..)
  , PlannedAction (..)
  , toActorState
  , toGameEvent
  , toPlannedAction
  ) where

import Data.Aeson.TH (deriveJSON)
import Data.List.NonEmpty (toList)
import Data.Map.Strict qualified as Map
import Data.Text (Text)
import GHC.Generics (Generic)

import CardPG.Core.Card (ConsequenceCard, CoreCard, CoreCardT (..), Identified (..), Stats (..))
import CardPG.Core.Json (cardpgJsonDef)
import CardPG.Core.Logic.Combat (computeDefense, computeResilience)
import CardPG.Core.Primitives (CardInstanceId, CardLocation, ResourceType)
import CardPG.Core.State
  ( AssetState
  , CorePlayState
  , RevealedEffect
  , SpatialState
  , TableCard (..)
  )
import CardPG.Core.State qualified as Core

-- | Detailed breakdown of defense calculation.
data DefenseDetails = DefenseDetails
  { values :: Stats Int
  , impact :: Int
  , consequencesFromDefense :: Int
  , nextSeverity :: Int
  }
  deriving (Show, Eq, Generic)

$(deriveJSON cardpgJsonDef ''DefenseDetails)

-- | Wire Instances (Concrete Types)
data CoreCardInstance = CoreCardInstance {id :: CardInstanceId, content :: CoreCard}
  deriving (Show, Eq, Generic)

$(deriveJSON cardpgJsonDef ''CoreCardInstance)

data TableCardInstance = TableCardInstance {id :: CardInstanceId, content :: TableCard}
  deriving (Show, Eq, Generic)
$(deriveJSON cardpgJsonDef ''TableCardInstance)

data ConsequenceCardInstance = ConsequenceCardInstance {id :: CardInstanceId, content :: ConsequenceCard}
  deriving (Show, Eq, Generic)
$(deriveJSON cardpgJsonDef ''ConsequenceCardInstance)

toCoreInst :: Identified CardInstanceId CoreCard -> CoreCardInstance
toCoreInst (Identified i c) = CoreCardInstance i c

toTableInst :: Identified CardInstanceId TableCard -> TableCardInstance
toTableInst (Identified i c) = TableCardInstance i c

toConsInst :: Identified CardInstanceId ConsequenceCard -> ConsequenceCardInstance
toConsInst (Identified i c) = ConsequenceCardInstance i c

-- | Wire ActionStack/PlannedAction
-- Needed because ActionStack contains CardInstance which we want to be CoreCardInstance
-- | Wire ActionStack/PlannedAction
data ActionStack = ActionStack
  { actionCard :: CoreCardInstance
  , resources :: [CoreCardInstance]
  }
  deriving (Show, Eq, Generic)

$(deriveJSON cardpgJsonDef ''ActionStack)

data NarrativeStack = NarrativeStack
  { cards :: [CoreCardInstance]
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

toPlannedAction :: Core.PlannedAction -> PlannedAction
toPlannedAction (Core.PStandard (Core.ActionStack ac res)) =
  PStandard $ ActionStack (toCoreInst ac) (map toCoreInst res)
toPlannedAction (Core.PNarrative (Core.NarrativeStack cs col)) =
  PNarrative $ NarrativeStack (map toCoreInst (toList cs)) col
toPlannedAction Core.PPass = PPass

-- | Wire States
-- | Wire States
data CoreCardState = CoreCardState
  { deck :: [CoreCardInstance]
  , hand :: [CoreCardInstance]
  , discard :: [CoreCardInstance]
  , planned :: Maybe PlannedAction
  , defending :: [CoreCardInstance]
  , inPlay :: Map.Map CardInstanceId (CoreCardInstance, CorePlayState)
  , revealed :: Maybe RevealedEffect
  }
  deriving (Show, Eq, Generic)

$(deriveJSON cardpgJsonDef ''CoreCardState)

data TableState = TableState
  { assets :: Map.Map CardInstanceId (TableCardInstance, AssetState)
  , consequences :: [ConsequenceCardInstance]
  }
  deriving (Show, Eq, Generic)
$(deriveJSON cardpgJsonDef ''TableState)

-- | Wire GameEvent
-- | Wire GameEvent
data GameEvent
  = CardsCreated [CoreCardInstance]
  | DeckShuffled
  | CardDrawn CoreCardInstance
  | CardDefended CoreCardInstance
  | MovePlanned (Int, Int)
  | ActorMoved (Int, Int)
  | ActionPlanned PlannedAction
  | PlanCanceled PlannedAction
  | ActionRevealed PlannedAction RevealedEffect
  | DefenseEnded [CoreCardInstance]
  | IllegalAction PlannedAction (Maybe Text)
  | StatusAdded Text CardLocation
  | StatusRemoved Text Text
  | ConsequenceAdded ConsequenceCardInstance
  | ConsequenceRemoved Text
  deriving (Show, Eq, Generic)

$(deriveJSON cardpgJsonDef ''GameEvent)

toGameEvent :: Core.GameEvent -> GameEvent
toGameEvent (Core.CardsCreated cs) = CardsCreated (map toCoreInst cs)
toGameEvent Core.DeckShuffled = DeckShuffled
toGameEvent (Core.CardDrawn c) = CardDrawn (toCoreInst c)
toGameEvent (Core.CardDefended c) = CardDefended (toCoreInst c)
toGameEvent (Core.MovePlanned p) = MovePlanned p
toGameEvent (Core.ActorMoved p) = ActorMoved p
toGameEvent (Core.ActionPlanned p) = ActionPlanned (toPlannedAction p)
toGameEvent (Core.PlanCanceled p) = PlanCanceled (toPlannedAction p)
toGameEvent (Core.ActionRevealed p r) = ActionRevealed (toPlannedAction p) r
toGameEvent (Core.DefenseEnded cs) = DefenseEnded (map toCoreInst cs)
toGameEvent (Core.IllegalAction p t) = IllegalAction (toPlannedAction p) t
toGameEvent (Core.StatusAdded t l) = StatusAdded t l
toGameEvent (Core.StatusRemoved t l) = StatusRemoved t l
toGameEvent (Core.ConsequenceAdded c) = ConsequenceAdded (toConsInst c)
toGameEvent (Core.ConsequenceRemoved t) = ConsequenceRemoved t

-- | Wire format for ActorState with computed stats baked in.
-- Internal Core.ActorState stays clean; this adds presentation-layer fields.
data ActorState = ActorState
  { name :: Text
  , actorType :: Text
  , coreState :: CoreCardState
  , tableState :: TableState
  , spatial :: SpatialState
  , plannedMove :: Maybe (Int, Int)
  , -- Computed fields (derived from tableState):
    defense :: Int
  , resilience :: Int
  , defenseDetails :: DefenseDetails
  }
  deriving (Show, Eq, Generic)

$(deriveJSON cardpgJsonDef ''ActorState)

-- | Enrich Core.ActorState for wire transmission
toActorState :: Core.ActorState -> ActorState

-- | Enrich Core.ActorState for wire transmission
toActorState Core.ActorState{..} =
  let
    -- Wire Conversions
    wireCoreState =
      CoreCardState
        { deck = map toCoreInst coreState.deck
        , hand = map toCoreInst coreState.hand
        , discard = map toCoreInst coreState.discard
        , planned = fmap toPlannedAction coreState.planned
        , defending = map toCoreInst coreState.defending
        , inPlay = Map.map (\(c, s) -> (toCoreInst c, s)) coreState.inPlay
        , revealed = coreState.revealed
        }

    wireTableState =
      TableState
        { assets = Map.map (\(c, s) -> (toTableInst c, s)) tableState.assets
        , consequences = map toConsInst tableState.consequences
        }

    defStat = computeDefense tableState
    resStat = computeResilience tableState

    -- Resolve defending cards
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
        { values =
            Stats
              { red = defRed
              , yellow = defYellow
              , blue = defBlue
              }
        , impact = impactVal
        , consequencesFromDefense = consequencesVal
        , nextSeverity = nextSeverityVal
        }
   in
    ActorState
      { defense = defStat
      , resilience = resStat
      , defenseDetails = details
      , coreState = wireCoreState
      , tableState = wireTableState
      , ..
      }
