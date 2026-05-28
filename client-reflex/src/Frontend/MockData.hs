{-# LANGUAGE OverloadedStrings #-}

-- | Mock Data Module
-- Provides sample GameState, ActionStack, and LogEntry data for:
-- 1. Static HTML generation (StaticMain.hs)
-- 2. CSS generation (GenCss.hs)
--
-- This ensures we capture parameterized styles
-- by exercising all UI code paths during static/gen-css runs.
module Frontend.MockData
  ( -- * Helper
    mockUUID

    -- * Mock Actors
  , mockActorState
  , mockActorId
  , mockActorsMap

    -- * Mock Planning State
  , mockActionStack
  , mockPlannedAction

    -- * Mock Logs
  , mockLogs

    -- * Mock Cards
  , mockCoreCard
  , mockCardInstance
  , mockHandCards
  ) where

import Data.Map.Strict qualified as Map
import Data.Text (Text)
import Data.UUID.Types qualified as UUID

import Api.Types (LogEntry (..), LogId (..), LogPayload (..), LogSender (..))
import Core.Card (CardInstance, CoreCard (..))
import Core.NonEmptyText (unsafeNonEmptyText)
import Core.Primitives (ActorId (..), CardInstanceId (..), Identified (..))
import Core.State
  ( ActionStack (..)
  , ActorState (..)
  , CoreCardState (..)
  , PlannedAction (..)
  , SpatialState (..)
  , TableState (..)
  )
import Core.Stats (Stats (..))

-- | Sample UUID for mock data (deterministic for reproducibility)
mockUUID :: Int -> UUID.UUID
mockUUID n = UUID.fromWords (fromIntegral n) 0 0 0

-- | Sample ActorId
mockActorId :: ActorId
mockActorId = ActorId (mockUUID 1)

-- | Sample CoreCard template
mockCoreCard :: Text -> Int -> CoreCard
mockCoreCard name cost =
  CoreCard
    { name = unsafeNonEmptyText name
    , tags = Nothing
    , stats = Stats 2 1 1 -- Balanced stats
    , cost = Just cost
    , attack = Nothing
    , rules = Nothing
    , flavor = Nothing
    }

-- | Sample CardInstance
mockCardInstance :: Int -> Text -> Int -> CardInstance CoreCard
mockCardInstance n name cost =
  Identified (CardInstanceId (mockUUID n)) (mockCoreCard name cost)

-- | Sample action card (the main card in ActionStack)
mockActionCard :: CardInstance CoreCard
mockActionCard = mockCardInstance 10 "Strike" 2

-- | Sample resource cards
mockResourceCards :: [CardInstance CoreCard]
mockResourceCards =
  [ mockCardInstance 11 "Focus" 0
  , mockCardInstance 12 "Momentum" 0
  ]

-- | Sample ActionStack for staging widget
mockActionStack :: ActionStack
mockActionStack =
  ActionStack
    { actionCard = mockActionCard
    , resources = mockResourceCards
    }

-- | Sample PlannedAction (wrapping the ActionStack)
mockPlannedAction :: PlannedAction
mockPlannedAction = PStandard mockActionStack

-- | Sample hand cards containing both non-staged and staged cards
mockHandCards :: [CardInstance CoreCard]
mockHandCards =
  [ mockActionCard
  ]
    ++ mockResourceCards
    ++ [ mockCardInstance 20 "Defend" 1
       , mockCardInstance 21 "Dodge" 0
       , mockCardInstance 22 "Counter" 2
       ]

-- | Sample CoreCardState with populated hand and staged action
mockCoreCardState :: CoreCardState
mockCoreCardState =
  CoreCardState
    { deck = [] -- Empty for simplicity
    , hand = mockHandCards
    , discard = []
    , planned = Just mockPlannedAction
    , defending = Nothing
    , inPlay = Map.empty
    , revealed = Nothing
    }

-- | Sample TableState
mockTableState :: TableState
mockTableState =
  TableState
    { assets = Map.empty
    , consequences = []
    }

-- | Sample SpatialState
mockSpatialState :: SpatialState
mockSpatialState =
  SpatialState
    { posX = 0
    , posY = 0
    , size = 1
    , mapId = Nothing
    }

-- | Sample ActorState with staging data
mockActorState :: ActorState
mockActorState =
  ActorState
    { name = "Test Hero"
    , actorType = "PC"
    , coreState = mockCoreCardState
    , tableState = mockTableState
    , spatial = mockSpatialState
    , plannedMove = Nothing
    }

-- | Sample actors map
mockActorsMap :: Map.Map ActorId ActorState
mockActorsMap = Map.singleton mockActorId mockActorState

-- | Sample log entries for the log widget
mockLogs :: [LogEntry]
mockLogs =
  [ LogEntry
      { id = LogId (mockUUID 100)
      , sender = SenderSystem
      , payload = LogInfo "Game started"
      }
  , LogEntry
      { id = LogId (mockUUID 101)
      , sender = SenderActor mockActorId "Test Hero"
      , payload = LogChat "Ready to fight!"
      }
  , LogEntry
      { id = LogId (mockUUID 102)
      , sender = SenderGame
      , payload = LogInfo "Planning phase begun"
      }
  ]
