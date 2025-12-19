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
  , toActorState
  ) where

import Data.Aeson.TH (deriveJSON)
import Data.Map.Strict qualified as Map
import Data.Text (Text)
import GHC.Generics (Generic)

import CardPG.Core.Card (CoreCard, CoreCardT (..), Stats (..))
import CardPG.Core.Json (cardpgJsonDef)
import CardPG.Core.Logic.Combat (computeDefense, computeResilience)
import CardPG.Core.State
  ( CoreCardState
  , SpatialState
  , TableState
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
toActorState Core.ActorState{..} =
  let
    defStat = computeDefense tableState
    resStat = computeResilience tableState

    -- Resolve defending cards
    defendingIds = coreState.defending
    defendingCards =
      [ card
      | cid <- defendingIds
      , Just card <- [Map.lookup cid coreState.registry]
      ]

    defRed = sum [c.stats.red | c <- defendingCards]
    defYellow = sum [c.stats.yellow | c <- defendingCards]
    defBlue = sum [c.stats.blue | c <- defendingCards]

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
      , ..
      }
