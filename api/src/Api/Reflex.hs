module Api.Reflex where

import Core.Primitives (ActorId)
import Core.State (ActorState)
import Data.Aeson (FromJSON, ToJSON)
import Data.Map (Map)
import Data.Text (Text)
import Data.UUID (UUID)
import GHC.Generics (Generic)
import Reflex.Dom.GadtApi.WebSocket (TaggedResponse)

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
  | PushError
      { message :: Text
      }
  deriving (Show, Eq, Generic)

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
