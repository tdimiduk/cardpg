{-# LANGUAGE DuplicateRecordFields #-}
{-# LANGUAGE RecordWildCards #-}

module CardPG.Api.Reflex where

import Data.Aeson.TH (deriveJSON)
import Data.Map (Map)
import Data.Text (Text)
import Data.UUID (UUID)
import GHC.Generics (Generic)

import CardPG.Core.Json (cardpgJsonDef)
import CardPG.Core.Primitives (ActorId)
import CardPG.Core.State (ActorState)

-- | Server message for Reflex frontend using Core types directly
data ReflexServerMessage
  = ReflexWelcome
      { yourClientId :: UUID
      , actors :: Map ActorId ActorState
      }
  | ReflexUpdate
      { actors :: Map ActorId ActorState
      }
  | ReflexError {error :: Text}
  deriving (Show, Generic)

$(deriveJSON cardpgJsonDef ''ReflexServerMessage)
