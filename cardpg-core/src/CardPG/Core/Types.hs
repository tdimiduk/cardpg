module CardPG.Core.Types
  ( ResourceType(..)
  , StackPower(..)
  )
where

import Data.Aeson (ToJSON(..), FromJSON(..), genericToJSON, genericToEncoding, genericParseJSON)
import Data.Text (Text)
import GHC.Generics (Generic)

import CardPG.Core.Json (cardpgJsonDef)

data ResourceType = Red | Yellow | Blue
  deriving stock (Eq,Show, Generic)
  deriving anyclass (ToJSON, FromJSON)

data StackPower = StackPower
  { _source      :: ResourceType
  , _modifier    :: Int
  , _conditional :: Maybe Text
  }
  deriving stock (Eq, Show, Generic)

instance ToJSON StackPower where
  toJSON = genericToJSON cardpgJsonDef
  toEncoding = genericToEncoding cardpgJsonDef

instance FromJSON StackPower where
  parseJSON = genericParseJSON cardpgJsonDef
