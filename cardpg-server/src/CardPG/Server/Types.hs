{-# LANGUAGE DeriveGeneric #-}
{-# LANGUAGE TemplateHaskell #-}
{-# LANGUAGE ScopedTypeVariables #-}
{-# LANGUAGE DuplicateRecordFields #-}
{-# LANGUAGE DeriveAnyClass #-}
{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE RecordWildCards #-}

module CardPG.Server.Types
  ( Client(..)
  , ClientMessage(..)
  , ServerMessage(..)
  ) where

import Data.Aeson (FromJSON(..), ToJSON(..), Value, SumEncoding(..))
import Data.Aeson.TH (deriveJSON)
import Data.Aeson.TypeScript.TH (deriveTypeScript, TypeScript(..))
import Data.Text (Text)
import Data.UUID (UUID)
import GHC.Generics (Generic)
import Network.WebSockets (Connection)
import CardPG.Server.Json (customOptions)

-- | A client connection with a unique ID and a name.
data Client = Client
  { clientId :: UUID
  , clientName :: Text
  , clientConn :: Connection
  }

instance TypeScript UUID where
  getTypeScriptType _ = "string"

-- | Messages sent from Client to Server.
data ClientMessage
  = Join { name :: Text }
  | Broadcast { payload :: Value }
  deriving (Show, Generic)

$(deriveJSON customOptions ''ClientMessage)
$(deriveTypeScript customOptions ''ClientMessage)

-- | Messages sent from Server to Client.
data ServerMessage
  = Welcome { yourClientId :: UUID, connectedClients :: [Text], history :: [Value] }
  | BroadcastMessage { fromClientId :: UUID, payload :: Value }
  | ClientJoined { newClientName :: Text, newClientId :: UUID }
  | ClientLeft { leftClientId :: UUID }
  | ErrorMessage { error :: Text }
  deriving (Show, Generic)

$(deriveJSON customOptions ''ServerMessage)
$(deriveTypeScript customOptions ''ServerMessage)
