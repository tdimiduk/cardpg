{-# LANGUAGE TemplateHaskell #-}
{-# LANGUAGE ScopedTypeVariables #-}
module CardPG.Core.Types
  ( ResourceType(..)
  , StackPower(..)
  , Difficulty(..)
  )
where

import Data.Aeson.TH (deriveJSON)
import Data.Text (Text)
import GHC.Generics (Generic)

import CardPG.Core.Json (cardpgJsonDef)

data ResourceType = Red | Yellow | Blue
  deriving stock (Eq,Show, Generic)

data StackPower = StackPower
  { _source      :: ResourceType
  , _modifier    :: Int
  , _conditional :: Maybe Text
  }
  deriving stock (Eq, Show, Generic)

data Difficulty = Difficulty
  { _attribute :: ResourceType
  , _value     :: Int
  }
  deriving stock (Eq, Show, Generic)

$(deriveJSON cardpgJsonDef ''ResourceType)
$(deriveJSON cardpgJsonDef ''StackPower)
$(deriveJSON cardpgJsonDef ''Difficulty)

