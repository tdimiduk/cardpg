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

    -- * Messages (Protocol)
  , ServerMessage (..)

    -- * Misc
  , Token (..)
  ) where

import Data.Aeson (FromJSONKey, ToJSONKey)
import Data.Aeson.TH (deriveJSON)
import Data.Aeson.TypeScript.TH (TypeScript (..))
import Data.Text (Text)
import Data.UUID (UUID)
import GHC.Generics (Generic)
import System.Random.Stateful (Uniform (..), uniformM)

import Core.Card (CardInstance, CoreCard)
import Core.Json (cardpgJsonDef)
import Core.Primitives (ActorId, CardInstanceId, ChallengeId)
import Core.State (ActiveChallenge, ActorState, DefenseDetails, GameEvent, PlannedAction)
import Core.Stats (ResourceType)

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

instance TypeScript LogId where
  getTypeScriptType _ = "string"

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

data LogEntry = LogEntry
  { id :: LogId
  , timestamp :: Int
  , sender :: Text
  , senderId :: Maybe ActorId
  , payload :: LogPayload
  }
  deriving (Show, Eq, Generic)

$(deriveJSON cardpgJsonDef ''LogEntry)

data Token = Token
  { id :: Text
  , actorId :: Text
  , x :: Int
  , y :: Int
  , size :: Int
  }
  deriving (Show, Eq, Generic)

$(deriveJSON cardpgJsonDef ''Token)

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

instance TypeScript ChallengeId where
  getTypeScriptType _ = "string"

-- Orphan instance for UUID if not defined elsewhere or imported
instance TypeScript UUID where
  getTypeScriptType _ = "string"

-- | Messages sent from Server to Client.
data ServerMessage
  = Welcome
      { yourClientId :: UUID
      , connectedClients :: [Text]
      , initialActors :: [StateUpdate]
      , phase :: Phase
      , history :: [LogEntry]
      , readyCount :: Int
      , totalCount :: Int
      }
  | BroadcastMessage {fromClientId :: UUID, payload :: [ActorGameEvent]}
  | ClientJoined {newClientName :: Text, newClientId :: UUID}
  | ClientLeft {leftClientId :: UUID}
  | ErrorMessage {error :: Text}
  | MultiMessage {messages :: [ServerMessage]}
  | GameStateUpdate
      { updates :: [StateUpdate]
      , newPhase :: Maybe Phase
      , readyCount :: Int
      , totalCount :: Int
      }
  | NewLogs {logs :: [LogEntry]}
  deriving (Show, Generic)

$(deriveJSON cardpgJsonDef ''ServerMessage)
