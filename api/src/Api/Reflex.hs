module Api.Reflex where

import Data.Aeson (FromJSON, ToJSON)
import Data.Map (Map)
import Data.Text (Text)
import Data.Time (UTCTime)
import Data.UUID (UUID)
import GHC.Generics (Generic)
import Reflex.Dom.GadtApi.WebSocket (TaggedResponse)

import Core.Primitives (ActorId)
import Core.RichText (RichText)
import Core.State (ActorState)

data GameView = GameView
  { actors :: Map ActorId ActorState
  }
  deriving (Show, Eq, Generic)

instance FromJSON GameView
instance ToJSON GameView

data ServerPush
  = PushWelcome
      { clientId :: UUID
      , game :: GameView
      }
  | PushUpdate
      { game :: GameView
      }
  | PushChat ChatMessage
  | PushLog LogMessage
  | PushError ErrorMessage
  deriving (Show, Eq, Generic)

data ChatMessage = ChatMessage
  { content :: RichText
  , sender :: Maybe Text
  , timestamp :: UTCTime
  }
  deriving (Show, Eq, Generic)

instance FromJSON ChatMessage
instance ToJSON ChatMessage

data LogLevel = LogInfo | LogWarn | LogError
  deriving (Show, Eq, Generic, Enum)

instance FromJSON LogLevel
instance ToJSON LogLevel

data LogMessage = LogMessage
  { content :: RichText
  , level :: LogLevel
  }
  deriving (Show, Eq, Generic)

instance FromJSON LogMessage
instance ToJSON LogMessage

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
