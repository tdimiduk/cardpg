{-# LANGUAGE DeriveAnyClass #-}
{-# LANGUAGE DeriveGeneric #-}
{-# LANGUAGE DuplicateRecordFields #-}
{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE RecordWildCards #-}
{-# LANGUAGE ScopedTypeVariables #-}
{-# LANGUAGE TemplateHaskell #-}

module CardPG.Server.Types
  ( Client (..)
  , ClientMessage (..)
  , ServerMessage (..)
  , Token (..)
  , BroadcastAction (..)
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
import Data.Text (Text)
import qualified Data.Text as T
import Data.UUID (UUID)
import GHC.Generics (Generic)
import Network.WebSockets (Connection)

import CardPG.Core.Card (CoreCard)
import CardPG.Core.Json (cardpgJsonDef)
import CardPG.Core.Types (ResourceType)

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

-- | Messages sent from Client to Server.
data ClientMessage
  = Join {name :: Text}
  | Broadcast {payload :: BroadcastAction}
  deriving (Show, Generic)

$(deriveJSON cardpgJsonDef ''ClientMessage)

-- | Messages sent from Server to Client.
data ServerMessage
  = Welcome {yourClientId :: UUID, connectedClients :: [Text], history :: [BroadcastAction]}
  | BroadcastMessage {fromClientId :: UUID, payload :: BroadcastAction}
  | ClientJoined {newClientName :: Text, newClientId :: UUID}
  | ClientLeft {leftClientId :: UUID}
  | ErrorMessage {error :: Text}
  deriving (Show, Generic)

$(deriveJSON cardpgJsonDef ''ServerMessage)
