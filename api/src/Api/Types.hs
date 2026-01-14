{-# LANGUAGE DeriveAnyClass #-}

module Api.Types
  ( -- * Game State Types
    Phase (..)
  , StateUpdate (..)
  , ActorGameEvent (..)

    -- * Logging
  , LogId (..)
  , LogEntry (..)
  , LogPayload (..)
  , LogSender (..)

    -- * Misc
  ) where

import Data.Aeson (FromJSONKey, ToJSONKey)
import Data.Aeson.TH (deriveJSON)
import Data.Text (Text)
import Data.UUID (UUID)
import GHC.Generics (Generic)
import System.Random.Stateful (Uniform (..), uniformM)

import Core.Card (CardInstance, CoreCard)
import Core.Json (cardpgJsonDef)
import Core.Primitives (ActorId, ChallengeId)
import Core.State (ActiveChallenge, ActorState, DefenseDetails, GameEvent, PlannedAction)

-- | The authoritative state for a game session
data Phase = Planning | Resolution
  deriving (Show, Eq, Generic)

$(deriveJSON cardpgJsonDef ''Phase)

newtype LogId = LogId UUID
  deriving (Show, Eq, Ord, Generic)
  deriving newtype (FromJSONKey, ToJSONKey)

$(deriveJSON cardpgJsonDef ''LogId)

instance Uniform LogId where
  uniformM g = LogId <$> uniformM g

data LogPayload
  = LogInfo {content :: Text}
  | LogChat {content :: Text}
  | LogChallenge
      { challenge :: ActiveChallenge
      , plannedAction :: PlannedAction
      }
  | LogDefense
      { defenseActorId :: ActorId
      , challengeId :: ChallengeId
      , details :: Maybe DefenseDetails
      , cards :: Maybe [CardInstance CoreCard] -- Summary
      , ended :: Bool
      }
  | LogError {content :: Text}
  deriving (Show, Eq, Generic)

$(deriveJSON cardpgJsonDef ''LogPayload)

data LogSender
  = SenderSystem
  | SenderGame
  | SenderGM
  | SenderEnvironment
  | SenderActor ActorId Text
  deriving (Show, Eq, Generic)

$(deriveJSON cardpgJsonDef ''LogSender)

data LogEntry = LogEntry
  { id :: LogId
  , timestamp :: Int
  , sender :: LogSender
  , payload :: LogPayload
  }
  deriving (Show, Eq, Generic)

$(deriveJSON cardpgJsonDef ''LogEntry)

data ActorGameEvent = ActorGameEvent
  { actorId :: ActorId
  , event :: GameEvent
  }
  deriving (Show, Eq, Generic)

$(deriveJSON cardpgJsonDef ''ActorGameEvent)

-- | Updates to the authoritative state
data StateUpdate = StateUpdate
  { updateActorId :: ActorId
  , updateActorState :: ActorState
  }
  deriving (Show, Eq, Generic)

$(deriveJSON cardpgJsonDef ''StateUpdate)
