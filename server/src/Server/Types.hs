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
  , clientExists
  , addClient
  , removeClient
  , StorageBackend (..)
  , InMemoryStorage (..)
  , appendHistoryEntry
  ) where

import Data.Aeson
  ( FromJSON (..)
  , ToJSON (..)
  , genericParseJSON
  , genericToJSON
  , withObject
  , (.!=)
  , (.:)
  , (.:?)
  )
import Data.Aeson.TH (deriveJSON, deriveToJSON)

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
  , ClientRole (..)
  , LogEntry (..)
  , LogId (..)
  , LogPayload (..)
  , LogSender (..)
  , Phase (..)
  , PlayMode (..)
  , StateUpdate (..)
  )

import Core.Card
  ( ActorDefinition
  , ConsequenceCard
  , CoreCard (..)
  , ItemCard
  , MasterCard
  , NatureCard
  )
import Core.Json (cardpgJsonDef)
import Core.Primitives (ActorId)
import Core.State (ActorState, GameEnv, MapMode, WorldState)
import Server.Config (Config (..))
import Server.DB.Schema (Game, GameEventRecord)

-- | GameState depends on Phase and LogEntry from Api.Types
data GameState = GameState
  { env :: GameEnv
  , actors :: Map ActorId ActorState
  , phase :: Phase
  , history :: [LogEntry]
  , mapMode :: Maybe MapMode
  , roundNumber :: Int
  , playMode :: PlayMode
  , worldState :: Maybe WorldState
  }
  deriving (Show, Generic)

$(deriveToJSON cardpgJsonDef ''GameState)

instance FromJSON GameState where
  parseJSON = withObject "GameState" $ \o -> do
    env <- o .: "env"
    actors <- o .: "actors"
    phase <- o .: "phase"
    history <- o .:? "history" .!= []
    mapMode <- o .:? "mapMode"
    roundNumber <- o .:? "roundNumber" .!= 1
    playMode <- o .:? "playMode" .!= ModeCrisis
    worldState <- o .:? "worldState"
    pure
      GameState
        { env = env
        , actors = actors
        , phase = phase
        , history = history
        , mapMode = mapMode
        , roundNumber = roundNumber
        , playMode = playMode
        , worldState = worldState
        }

appendHistoryEntry :: LogEntry -> GameState -> GameState
appendHistoryEntry entry gs = gs{history = gs.history ++ [entry]}

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
  , clientRole :: ClientRole
  , clientConns :: [ConnectedSocket]
  }

-- | The library of all known cards/actors loaded from disk.
data CardLibrary = CardLibrary
  { actors :: [ActorDefinition]
  , statuses :: [CoreCard]
  , consequences :: [ConsequenceCard]
  , items :: [ItemCard]
  , nature :: [NatureCard]
  , masterCatalog :: Map Text MasterCard
  }
  deriving (Show, Eq, Generic)

instance FromJSON CardLibrary where
  parseJSON = withObject "CardLibrary" $ \o ->
    CardLibrary
      <$> o .: "actors"
      <*> o .: "statuses"
      <*> o .: "consequences"
      <*> o .: "items"
      <*> o .: "nature"
      <*> (o .:? "masterCatalog" .!= Map.empty)

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
  , gameId :: Text
  , checkpoints :: [GameState]
  }

data InMemoryStorage = InMemoryStorage
  { inMemoryGames :: Map Text (GameState, Game)
  , inMemoryEvents :: Map Text [GameEventRecord]
  , inMemorySnapshots :: Map Text [GameState]
  }

data StorageBackend
  = PostgresBackend (Pool Pg.Connection)
  | InMemoryBackend (IORef InMemoryStorage)

newServerState :: StorageBackend -> GameState -> StdGen -> Config -> [GameState] -> ServerState
newServerState backend gs rng cfg cps =
  ServerState
    { clients = Map.empty
    , library = CardLibrary [] [] [] [] [] Map.empty
    , gameState = gs
    , dbPool = backend
    , rng = rng
    , config = cfg
    , gameId = cfg.gameId
    , checkpoints = cps
    }

-- | Helpers for managing server state
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
                existing
                  { clientName = client.clientName
                  , clientRole = client.clientRole
                  , clientConns = existing.clientConns ++ client.clientConns
                  }
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
