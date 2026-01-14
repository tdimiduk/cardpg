{-# LANGUAGE DeriveAnyClass #-}

module Server.Types
  ( Client (..)
  , ActorGameEvent (..)
  , CardLibrary (..)
  , ServerState (..)
  , StateUpdate (..)
  , GameState (..)
  , LogEntry (..)
  , LogId (..)
  , LogPayload (..)
  , LogSender (..)
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
  , ToJSON (..)
  , genericParseJSON
  , genericToJSON
  )
import Data.Aeson.TH (deriveJSON)

import Data.IORef (IORef)
import Data.Map (Map)
import Data.Map qualified as Map
import Data.Pool (Pool)
import Data.Text (Text)
import Data.UUID (UUID)
import Database.PostgreSQL.Simple qualified as Pg
import GHC.Generics (Generic)
import Network.WebSockets qualified as WS
import System.Random (StdGen)

import Api.Types
  ( ActorGameEvent (..)
  , LogEntry (..)
  , LogId (..)
  , LogPayload (..)
  , LogSender (..)
  , Phase (..)
  , StateUpdate (..)
  )

import Core.Card
  ( ActorDefinition
  , ConsequenceCard
  , CoreCard (..)
  , ItemCard
  , NatureCard
  )
import Core.Json (cardpgJsonDef)
import Core.Primitives (ActorId)
import Core.State (ActorState, GameEnv)
import Server.Config (Config)

-- | GameState depends on Phase and LogEntry from Api.Types
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

-- | The library of all known cards/actors loaded from disk.
data CardLibrary = CardLibrary
  { actors :: [ActorDefinition]
  , statuses :: [CoreCard]
  , consequences :: [ConsequenceCard]
  , items :: [ItemCard]
  , nature :: [NatureCard]
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
newServerState backend gs = ServerState Map.empty (CardLibrary [] [] [] [] []) gs backend

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
