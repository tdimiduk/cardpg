{-# LANGUAGE DeriveAnyClass #-}

module CardPG.Server.Types
  ( Client (..)
  , ClientMessage (..)
  , ServerMessage (..)
  , Token (..)
  , BroadcastAction (..)
  , CardLibrary (..)
  , ServerState (..)
  , Command (..)
  , StateUpdate (..)
  , GameState (..)
  , newServerState
  ) where

import Data.Aeson
  ( FromJSON (..)
  , Options (..)
  , SumEncoding (..)
  , ToJSON (..)
  , Value
  , defaultOptions
  , genericParseJSON
  , genericToJSON
  )
import Data.Aeson.TH (deriveJSON)
import Data.Aeson.TypeScript.TH (TypeScript (..), deriveTypeScript)
import Data.Char (toUpper)
import Data.Map (Map)
import qualified Data.Map as Map
import Data.Text (Text)
import qualified Data.Text as T
import Data.UUID (UUID)
import GHC.Generics (Generic)
import Network.WebSockets (Connection)
import System.Random (StdGen)

import CardPG.Core.Card
  ( ActorMachine
  , ConsequenceCardMachine
  , CoreCard (..)
  , CoreCardMachine
  , ItemCardMachine
  )
import CardPG.Core.Json (cardpgJsonDef)
import CardPG.Core.Primitives (ResourceType, TargetId)
import CardPG.Core.State (ActorState, GameEnv)

-- | The authoritative state for a game session
data GameState = GameState
  { env :: GameEnv
  , rng :: StdGen
  , actors :: Map TargetId ActorState
  }
  deriving (Show, Generic)

-- | A client connection with a unique ID and a name.
data Client = Client
  { clientId :: UUID
  , clientName :: Text
  , clientConn :: Connection
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

data BroadcastAction
  = PlayStack
      { activeTokenId :: Text
      , selectedCards :: [CoreCard]
      , strengthColor :: ResourceType
      , modifier :: Int
      , targetDefense :: Maybe ResourceType
      , actionName :: Maybe Text
      , phase :: Text
      }
  | Pass {activeTokenId :: Text}
  | Reveal
  | EndRound
  | MoveToken {token :: Token}
  | DrawCards {activeTokenId :: Text, count :: Int}
  | Defend {activeTokenId :: Text}
  | ClearDefense {activeTokenId :: Text}
  | Reshuffle {activeTokenId :: Text}
  | AddConsequence {activeTokenId :: Text}
  | RemoveConsequence {activeTokenId :: Text, cardId :: Text}
  | AddStatus
      { activeTokenId :: Text
      , statusType :: Text
      , destination :: Text
      }
  | RemoveStatus
      { activeTokenId :: Text
      , statusType :: Text
      , destination :: Text
      }
  | DiscardCards
      { activeTokenId :: Text
      , cardIds :: [Text]
      }
  | CancelPlan {activeTokenId :: Text}
  | ReturnToDeck
      { activeTokenId :: Text
      , cardIds :: [Text]
      }
  deriving (Show, Eq, Generic)

instance ToJSON BroadcastAction where
  toJSON = genericToJSON cardpgJsonDef

instance FromJSON BroadcastAction where
  parseJSON = genericParseJSON cardpgJsonDef

-- | Commands for game actions (Intents)
data Command
  = DrawIntent { actorId :: TargetId }
  | DefendIntent { actorId :: TargetId }
  deriving (Show, Eq, Generic)

$(deriveJSON cardpgJsonDef ''Command)

-- | Messages sent from Client to Server.
data ClientMessage
  = Join {name :: Text}
  | Broadcast {payload :: BroadcastAction}
  | GameCommand {command :: Command}
  deriving (Show, Generic)

$(deriveJSON cardpgJsonDef ''ClientMessage)

-- | Updates to the authoritative state
data StateUpdate = StateUpdate
  { updateTargetId :: TargetId
  , updateActorState :: ActorState
  }
  deriving (Show, Eq, Generic)

$(deriveJSON cardpgJsonDef ''StateUpdate)

-- | Messages sent from Server to Client.
data ServerMessage
  = Welcome {yourClientId :: UUID, connectedClients :: [Text], history :: [BroadcastAction]}
  | BroadcastMessage {fromClientId :: UUID, payload :: BroadcastAction}
  | ClientJoined {newClientName :: Text, newClientId :: UUID}
  | ClientLeft {leftClientId :: UUID}
  | ErrorMessage {error :: Text}
  | GameStateUpdate {update :: StateUpdate}
  deriving (Show, Generic)

$(deriveJSON cardpgJsonDef ''ServerMessage)

-- | The library of all known cards/actors loaded from disk.
data CardLibrary = CardLibrary
  { actors :: [ActorMachine]
  , statuses :: [CoreCardMachine]
  , consequences :: [ConsequenceCardMachine]
  }
  deriving (Show, Eq, Generic)

instance FromJSON CardLibrary where
  parseJSON = genericParseJSON cardpgJsonDef

instance ToJSON CardLibrary where
  toJSON = genericToJSON cardpgJsonDef

-- | The state of the server, mapping client IDs to clients and storing action history.
data ServerState = ServerState
  { clients :: Map UUID Client
  , actionLog :: [BroadcastAction]
  , library :: CardLibrary
  , gameState :: GameState
  }

newServerState :: GameState -> ServerState
newServerState gs = ServerState Map.empty [] (CardLibrary [] [] []) gs


