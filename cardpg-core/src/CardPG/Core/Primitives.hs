
module CardPG.Core.Primitives
  ( CardInstanceId (..)
  , TargetId (..)
  , CardKind (..)
  , EquipSlot (..)
  , ResourceType (..)
  , StackPower (..)
  , Difficulty (..)
  ) where

import Data.Aeson (FromJSONKey, ToJSONKey)
import Data.Aeson.TH (deriveJSON)
import Data.Text (Text)
import Data.UUID (UUID)
import GHC.Generics (Generic)
import System.Random.Stateful (Uniform (..), uniformM)

import CardPG.Core.Json (cardpgJsonDef)

-- | Unique Identity for any card instance
newtype CardInstanceId = CardInstanceId UUID
  deriving stock (Show, Eq, Ord)
  deriving newtype (FromJSONKey, ToJSONKey)

instance Uniform CardInstanceId where
  uniformM g = CardInstanceId <$> uniformM g

$(deriveJSON cardpgJsonDef ''CardInstanceId)

-- | Identity for an Actor or Token on the board
newtype TargetId = TargetId UUID
  deriving stock (Show, Eq, Ord)
  deriving newtype (FromJSONKey, ToJSONKey)

instance Uniform TargetId where
  uniformM g = TargetId <$> uniformM g

$(deriveJSON cardpgJsonDef ''TargetId)

-- | Discriminator for Logic
data CardKind = KindCore | KindTable
  deriving stock (Show, Eq, Generic)

$(deriveJSON cardpgJsonDef ''CardKind)

data EquipSlot = SlotMainHand | SlotOffHand | SlotBody | SlotAccessory | SlotUnspecified
  deriving stock (Show, Eq, Generic)

$(deriveJSON cardpgJsonDef ''EquipSlot)

data ResourceType = Red | Yellow | Blue
  deriving stock (Eq, Show, Generic)

$(deriveJSON cardpgJsonDef ''ResourceType)

data StackPower = StackPower
  { source :: ResourceType
  , modifier :: Int
  , conditional :: Maybe Text
  }
  deriving stock (Eq, Show, Generic)

$(deriveJSON cardpgJsonDef ''StackPower)

data Difficulty = Difficulty
  { attribute :: ResourceType
  , value :: Int
  }
  deriving stock (Eq, Show, Generic)

$(deriveJSON cardpgJsonDef ''Difficulty)
