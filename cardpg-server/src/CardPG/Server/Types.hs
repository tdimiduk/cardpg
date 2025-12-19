{-# LANGUAGE DeriveAnyClass #-}

module CardPG.Server.Types
  ( Client (..)
  , ClientMessage (..)
  , ServerMessage (..)
  , AdminCommand (..)
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
  , ConnectedSocket (..)
  , newServerState
  , numClients
  , clientExists
  , addClient
  , removeClient
  , StorageBackend (..)
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
import Data.IORef (IORef)
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
import CardPG.Core.Json (cardpgJsonDef, cardpgTaggedOptions)
import CardPG.Core.Primitives (ActorId, CardInstanceId, CardLocation, ResourceType)
import CardPG.Core.State (ActorState, GameEnv, GameEvent, RealizedAttack)
import CardPG.Server.Config (Config)
import CardPG.Server.Types.Wire qualified as Wire

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

-- | A wrapper for a WebSocket connection with a unique ID for management
data ConnectedSocket = ConnectedSocket
  { socketId :: UUID
  , socketConn :: WS.Connection
  }

instance Show ConnectedSocket where
  show (ConnectedSocket sid _) = "ConnectedSocket(" <> show sid <> ")"

-- | A client connection with a unique ID and a name.
data Client = Client
  { clientId :: UUID
  , clientName :: Text
  , clientConns :: [ConnectedSocket]
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
  , updateActorState :: Wire.ActorState
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
  , dbPool :: StorageBackend
  , rng :: StdGen
  , config :: Config
  }

data StorageBackend
  = PostgresBackend (Pool Pg.Connection)
  | InMemoryBackend (IORef (Map Text GameState))

newServerState :: StorageBackend -> GameState -> StdGen -> Config -> ServerState
newServerState backend gs = ServerState Map.empty (CardLibrary [] [] []) gs backend

-- | Helpers for managing server state
numClients :: ServerState -> Int
numClients = Map.size . (.clients)

clientExists :: UUID -> ServerState -> Bool
clientExists cid state = Map.member cid (state.clients)

-- | Adds a client or merges a new connection into an existing client
addClient :: Client -> ServerState -> ServerState
addClient client state =
  let clientMap = state.clients
   in case Map.lookup (client.clientId) clientMap of
        Nothing -> state{clients = Map.insert (client.clientId) client clientMap}
        Just existing ->
          let merged =
                existing{clientName = client.clientName, clientConns = existing.clientConns ++ client.clientConns}
           in state{clients = Map.insert (client.clientId) merged clientMap}

-- | Removes a specific connection. If client has no more connections, removes the client.
removeClient :: UUID -> UUID -> ServerState -> ServerState
removeClient clientId socketId state =
  let clientMap = state.clients
   in case Map.lookup clientId clientMap of
        Nothing -> state
        Just existing ->
          let keptConns = filter (\s -> s.socketId /= socketId) (existing.clientConns)
           in if null keptConns
                then state{clients = Map.delete clientId clientMap}
                else
                  let updated = existing{clientConns = keptConns}
                   in state{clients = Map.insert clientId updated clientMap}
