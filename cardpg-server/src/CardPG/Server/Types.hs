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
  , Phase (..)
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
import Data.Map qualified as Map
import Data.Text (Text)
import Data.Text qualified as T
import Data.UUID (UUID)
import GHC.Generics (Generic)
import Network.WebSockets (Connection)
import System.Random (StdGen)

import CardPG.Core.Card
  ( ActorDefinition
  , ConsequenceCard
  , CoreCard (..)
  , ItemCard
  )
import CardPG.Core.Json (cardpgJsonDef)
import CardPG.Core.Primitives (ActorId, ResourceType)
import CardPG.Core.State (ActorState, GameEnv, RealizedAttack)

-- | The authoritative state for a game session
data GameState = GameState
  { env :: GameEnv
  , rng :: StdGen
  , actors :: Map ActorId ActorState
  , phase :: Phase
  }
  deriving (Show, Generic)

data Phase = Planning | Resolution
  deriving (Show, Eq, Generic)

$(deriveJSON cardpgJsonDef ''Phase)
$(deriveTypeScript cardpgJsonDef ''Phase)

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
  = AttackAction
      { actingActor :: ActorId
      , attack :: RealizedAttack
      }
  | Pass {actingActor :: ActorId}
  | Reveal
  | StartResolutionPhase
  | EndRound
  | MoveToken {actingActor :: ActorId, token :: Token}
  | DrawCards {actingActor :: ActorId, count :: Int}
  | Defend {actingActor :: ActorId}
  | ClearDefense {actingActor :: ActorId}
  | Reshuffle {actingActor :: ActorId}
  | AddConsequence {actingActor :: ActorId}
  | RemoveConsequence {actingActor :: ActorId, cardId :: Text}
  | AddStatus
      { actingActor :: ActorId
      , statusType :: Text
      , destination :: Text
      }
  | RemoveStatus
      { actingActor :: ActorId
      , statusType :: Text
      , destination :: Text
      }
  | DiscardCards
      { actingActor :: ActorId
      , cardIds :: [Text]
      }
  | CancelPlan {actingActor :: ActorId}
  | ReturnToDeck
      { actingActor :: ActorId
      , cardIds :: [Text]
      }
  | InvalidAction {actingActor :: ActorId, message :: Text}
  deriving (Show, Eq, Generic)

instance ToJSON BroadcastAction where
  toJSON = genericToJSON cardpgJsonDef

instance FromJSON BroadcastAction where
  parseJSON = genericParseJSON cardpgJsonDef

-- | Commands for game actions (Intents)
data Command
  = DrawIntent {actorId :: ActorId}
  | DefendIntent {actorId :: ActorId}
  | PlanMove {actorId :: ActorId, x :: Int, y :: Int}
  | PlanAction {actorId :: ActorId, actionCardId :: Text, resourceCardIds :: [Text]}
  | PlanNarrative {actorId :: ActorId, cardIds :: [Text], color :: ResourceType}
  | CancelPlanIntent {actorId :: ActorId}
  | StartResolutionIntent {actorId :: ActorId}
  | EndDefenseIntent {actorId :: ActorId}
  | ReshuffleIntent {actorId :: ActorId}
  | AddStatusIntent {actorId :: ActorId, statusType :: Text, destination :: Text}
  | RemoveStatusIntent {actorId :: ActorId, statusType :: Text, targetCardId :: Maybe Text}
  | AddConsequenceIntent {actorId :: ActorId, severity :: Int}
  | RemoveConsequenceIntent {actorId :: ActorId, cardId :: Text}
  | DiscardCardsIntent {actorId :: ActorId, cardIds :: [Text]}
  | ReturnToDeckIntent {actorId :: ActorId, cardIds :: [Text]}
  | EndRoundIntent {actorId :: ActorId}
  | PassIntent {actorId :: ActorId}
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
      , history :: [BroadcastAction]
      , initialActors :: [StateUpdate]
      , phase :: Phase
      }
  | BroadcastMessage {fromClientId :: UUID, payload :: [BroadcastAction]}
  | ClientJoined {newClientName :: Text, newClientId :: UUID}
  | ClientLeft {leftClientId :: UUID}
  | ErrorMessage {error :: Text}
  | MultiMessage {messages :: [ServerMessage]}
  | GameStateUpdate {updates :: [StateUpdate], newPhase :: Maybe Phase}
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
  , actionLog :: [BroadcastAction]
  , library :: CardLibrary
  , gameState :: GameState
  }

newServerState :: GameState -> ServerState
newServerState gs = ServerState Map.empty [] (CardLibrary [] [] []) gs
