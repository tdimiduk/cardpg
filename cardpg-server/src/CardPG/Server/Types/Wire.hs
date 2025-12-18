{-# LANGUAGE DeriveAnyClass #-}
{-# LANGUAGE RecordWildCards #-}

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
  , toActorState
  ) where

import Data.Text (Text)
import GHC.Generics (Generic)
import Data.Aeson.TH (deriveJSON)

import CardPG.Core.Json (cardpgJsonDef)
import CardPG.Core.Logic.Combat (computeDefense, computeResilience)
import CardPG.Core.State qualified as Core
import CardPG.Core.State
  ( CoreCardState
  , SpatialState
  , TableState
  )

-- | Wire format for ActorState with computed stats baked in.
-- Internal Core.ActorState stays clean; this adds presentation-layer fields.
data ActorState = ActorState
  { name :: Text
  , actorType :: Text
  , coreState :: CoreCardState
  , tableState :: TableState
  , spatial :: SpatialState
  , plannedMove :: Maybe (Int, Int)
  -- Computed fields (derived from tableState):
  , defense :: Int
  , resilience :: Int
  }
  deriving (Show, Eq, Generic)

$(deriveJSON cardpgJsonDef ''ActorState)

-- | Enrich Core.ActorState for wire transmission
toActorState :: Core.ActorState -> ActorState
toActorState Core.ActorState{..} = ActorState
  { defense = computeDefense tableState
  , resilience = computeResilience tableState
  , ..
  }
