{-# LANGUAGE DeriveAnyClass #-}

module CardPG.Server.Types
  ( Client (..)
  , ClientMessage (..)
  , ServerMessage (..)
  , ActorGameEvent (..)
  , Token (..)
  , CardLibrary (..)
  , ServerState (..)
  , Command (..)
  , StateUpdate (..)
  , GameState (..)
  , LogEntry (..)
  , LogPayload (..)
  , Phase (..)
  , newServerState
  ) where

import Data.Aeson
  ( FromJSON (..)
  , Options (..)
  , SumEncoding (..)
  , ToJSON (..)
  , Value (..)
  , defaultOptions
  , genericParseJSON
  , genericToJSON
  , withText
  )
import Data.Aeson.TH (deriveJSON)
import Data.Aeson.TypeScript.TH (TypeScript (..), deriveTypeScript)
import Data.Char (toUpper)
import Data.Map (Map)
import Data.Map qualified as Map
import Data.Pool (Pool)
import Data.Text (Text)
import Data.Text qualified as T
import Data.UUID (UUID)
import Database.PostgreSQL.Simple qualified as Pg
import GHC.Generics (Generic)
import Network.WebSockets qualified as WS
import System.Random (StdGen, mkStdGen)
import Text.Read (readMaybe)

import CardPG.Core.Card
  ( ActorDefinition
  , ConsequenceCard
  , CoreCard (..)
  , ItemCard
  )
import CardPG.Core.Json (cardpgJsonDef)
import CardPG.Core.Primitives (ActorId, CardInstanceId, CardLocation, ResourceType)
import CardPG.Core.State (ActorState, GameEnv, GameEvent, RealizedAttack)

-- | The authoritative state for a game session
data Phase = Planning | Resolution
  deriving (Show, Eq, Generic)

$(deriveJSON cardpgJsonDef ''Phase)

data LogPayload
  = LogInfo {content :: Text}
  | LogChat {content :: Text}
  | LogAttack
      { attack :: RealizedAttack
      , resourceCardIds :: Maybe [Text]
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

data GameState = GameState
  { env :: GameEnv
  , actors :: Map ActorId ActorState
  , phase :: Phase
  , history :: [LogEntry]
  }
  deriving (Show, Generic)

$(deriveJSON cardpgJsonDef ''GameState)

-- | A client connection with a unique ID and a name.
data Client = Client
  { clientId :: UUID
  , clientName :: Text
  , clientConn :: WS.Connection
  }

instance TypeScript UUID where
  getTypeScriptType _ = "string"

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
  | RemoveStatusIntent {actorId :: ActorId, statusType :: Text, targetCardId :: Maybe CardInstanceId}
  | AddConsequenceIntent {actorId :: ActorId, severity :: Maybe Int}
  | RemoveConsequenceIntent {actorId :: ActorId, cardId :: CardInstanceId}
  | DiscardCardsIntent {actorId :: ActorId, cardIds :: [CardInstanceId]}
  | ReturnToDeckIntent {actorId :: ActorId, cardIds :: [CardInstanceId]}
  | EndRoundIntent {actorId :: ActorId}
  | PassIntent {actorId :: ActorId}
  | ChatIntent {chatSenderId :: Maybe ActorId, content :: Text}
  deriving (Show, Eq, Generic)

$(deriveJSON cardpgJsonDef ''Command)

-- | Messages sent from Client to Server.
data ClientMessage
  = Join {name :: Text, id :: Maybe UUID}
  | GameCommand {command :: Command}
  deriving (Show, Generic)

$(deriveJSON cardpgJsonDef ''ClientMessage)

-- | Updates to the authoritative state
data StateUpdate = StateUpdate
  { updateActorId :: ActorId
  , updateActorState :: ActorState
  }
  deriving (Show, Eq, Generic)

$(deriveJSON cardpgJsonDef ''StateUpdate)

-- | Messages sent from Server to Client.
data ServerMessage
  = Welcome
      { yourClientId :: UUID
      , connectedClients :: [Text]
      , initialActors :: [StateUpdate]
      , phase :: Phase
      , history :: [LogEntry]
      }
  | BroadcastMessage {fromClientId :: UUID, payload :: [ActorGameEvent]}
  | ClientJoined {newClientName :: Text, newClientId :: UUID}
  | ClientLeft {leftClientId :: UUID}
  | ErrorMessage {error :: Text}
  | MultiMessage {messages :: [ServerMessage]}
  | GameStateUpdate {updates :: [StateUpdate], newPhase :: Maybe Phase}
  | NewLogs {logs :: [LogEntry]}
  deriving (Show, Generic)

$(deriveJSON cardpgJsonDef ''ServerMessage)

-- | The library of all known cards/actors loaded from disk.
data CardLibrary = CardLibrary
  { actors :: [ActorDefinition]
  , statuses :: [CoreCard]
  , consequences :: [ConsequenceCard]
  }
  deriving (Show, Eq, Generic)

instance FromJSON CardLibrary where
  parseJSON = genericParseJSON cardpgJsonDef

instance ToJSON CardLibrary where
  toJSON = genericToJSON cardpgJsonDef

-- | The state of the server, mapping client IDs to clients and storing action history.
data ServerState = ServerState
  { clients :: Map UUID Client
  , library :: CardLibrary
  , gameState :: GameState
  , dbPool :: Pool Pg.Connection
  , rng :: StdGen
  }

newServerState :: Pool Pg.Connection -> GameState -> StdGen -> ServerState
newServerState pool gs = ServerState Map.empty (CardLibrary [] [] []) gs pool
