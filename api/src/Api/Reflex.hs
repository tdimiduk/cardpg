module Api.Reflex where

import Data.Aeson (FromJSON, ToJSON)
import Data.Map (Map)
import Data.Text (Text)
import Data.UUID.Types (UUID)
import GHC.Generics (Generic)
import Reflex.Dom.GadtApi.WebSocket (TaggedResponse)

import Api.Types (LogEntry, Phase)
import Core.Primitives (ActorId)
import Core.State (ActorState, MapMode)

data GameView = GameView
  { actors :: Map ActorId ActorState
  , mapMode :: Maybe MapMode
  }
  deriving (Show, Eq, Generic)

instance FromJSON GameView
instance ToJSON GameView

data ServerPush
  = PushWelcome
      { clientId :: UUID
      , game :: GameView
      , history :: [LogEntry]
      , phase :: Phase
      }
  | PushUpdate
      { game :: GameView
      , newPhase :: Maybe Phase
      }
  | PushNewLogs {logs :: [LogEntry]}
  | PushError ErrorMessage
  deriving (Show, Eq, Generic)

data ErrorType = ErrorValidation | ErrorSystem | ErrorCustom
  deriving (Show, Eq, Generic, Enum)

instance FromJSON ErrorType
instance ToJSON ErrorType

data ErrorMessage = ErrorMessage
  { content :: Text
  , errorType :: ErrorType
  }
  deriving (Show, Eq, Generic)

instance FromJSON ErrorMessage
instance ToJSON ErrorMessage

instance FromJSON ServerPush
instance ToJSON ServerPush

data WsMessage
  = WsMsgPush ServerPush
  | WsMsgResponse TaggedResponse
  deriving (Generic)

instance FromJSON WsMessage
instance ToJSON WsMessage

instance Show WsMessage where
  show (WsMsgPush p) = "WsMsgPush " <> show p
  show (WsMsgResponse _) = "WsMsgResponse <tagged>"

instance Eq WsMessage where
  (WsMsgPush a) == (WsMsgPush b) = a == b
  (WsMsgResponse _) == (WsMsgResponse _) = False
  _ == _ = False
