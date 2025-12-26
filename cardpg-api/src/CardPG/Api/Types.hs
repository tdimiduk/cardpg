{-# LANGUAGE DeriveAnyClass #-}

module CardPG.Api.Types
  ( -- * Game State Types
    Phase (..)
  , StateUpdate (..)
  , ActorGameEvent (..)

    -- * Logging
  , LogEntry (..)
  , LogPayload (..)

    -- * Messages (Protocol)
  , ClientMessage (..)
  , ServerMessage (..)

    -- * Commands
  , Command (..)
  , AdminCommand (..)

    -- * Misc
  , Token (..)
  ) where

import Data.Aeson.TH (deriveJSON)
import Data.Aeson.TypeScript.TH (TypeScript (..))
import Data.Text (Text)
import Data.UUID (UUID)
import GHC.Generics (Generic)

import CardPG.Api.Frontend qualified as Frontend
import CardPG.Core.Json (cardpgJsonDef, cardpgTaggedOptions)
import CardPG.Core.Primitives (ActorId, CardInstanceId, CardLocation, ResourceType)
import CardPG.Core.State (ActiveChallenge)

-- | The authoritative state for a game session
data Phase = Planning | Resolution
  deriving (Show, Eq, Generic)

$(deriveJSON cardpgJsonDef ''Phase)

data LogPayload
  = LogInfo {content :: Text}
  | LogChat {content :: Text}
  | LogChallenge
      { challenge :: ActiveChallenge
      , plannedAction :: Frontend.PlannedAction
      }
  | LogDefense
      { defenseActorId :: ActorId
      , ended :: Bool
      , snapshot :: Maybe [Text]
      }
  deriving (Show, Eq, Generic)

$(deriveJSON cardpgJsonDef ''LogPayload)

data LogEntry = LogEntry
  { id :: Text
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
  , event :: Frontend.GameEvent
  }
  deriving (Show, Eq, Generic)

$(deriveJSON cardpgJsonDef ''ActorGameEvent)

-- | Commands for game actions (Intents)
data Command
  = DrawIntent {actorId :: ActorId}
  | DefendIntent {actorId :: ActorId}
  | PlanMove {actorId :: ActorId, x :: Int, y :: Int}
  | PlanAction {actorId :: ActorId, actionCardId :: CardInstanceId, resourceCardIds :: [CardInstanceId]}
  | PlanNarrative {actorId :: ActorId, cardIds :: [CardInstanceId], color :: ResourceType}
  | CancelPlanIntent {actorId :: ActorId}
  | StartResolutionIntent {actorId :: ActorId}
  | EndDefenseIntent {actorId :: ActorId}
  | ReshuffleIntent {actorId :: ActorId}
  | AddStatusIntent {actorId :: ActorId, statusType :: Text, destination :: CardLocation}
  | DestroyStatusIntent {actorId :: ActorId, statusType :: Text, targetCardId :: Maybe CardInstanceId}
  | AddConsequenceIntent {actorId :: ActorId, severity :: Maybe Int}
  | DestroyConsequenceIntent {actorId :: ActorId, cardId :: CardInstanceId}
  | DiscardCardsIntent {actorId :: ActorId, cardIds :: [CardInstanceId]}
  | ReturnToDeckIntent {actorId :: ActorId, cardIds :: [CardInstanceId]}
  | EndRoundIntent {actorId :: ActorId}
  | PassIntent {actorId :: ActorId}
  | ChatIntent {chatSenderId :: Maybe ActorId, content :: Text}
  deriving (Show, Eq, Generic)

$(deriveJSON cardpgJsonDef ''Command)

data AdminCommand
  = ResetGame
  deriving (Show, Eq, Generic)

$(deriveJSON (cardpgTaggedOptions "") ''AdminCommand)

-- | Messages sent from Client to Server.
data ClientMessage
  = Join {name :: Text, id :: Maybe UUID}
  | GameCommand {command :: Command}
  | Admin {adminCommand :: AdminCommand}
  deriving (Show, Generic)

$(deriveJSON cardpgJsonDef ''ClientMessage)

-- | Updates to the authoritative state
data StateUpdate = StateUpdate
  { updateActorId :: ActorId
  , updateActorState :: Frontend.ActorState
  }
  deriving (Show, Eq, Generic)

$(deriveJSON cardpgJsonDef ''StateUpdate)

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
