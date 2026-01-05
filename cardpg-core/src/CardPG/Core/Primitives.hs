module CardPG.Core.Primitives
  ( CardInstanceId (..)
  , TargetId (..)
  , ActorId (..)
  , CardKind (..)
  , EquipSlot (..)
  , CardLocation (..)
  , ChallengeId (..)
  ) where

import Data.Aeson
  ( FromJSON (..)
  , FromJSONKey
  , ToJSON (..)
  , ToJSONKey
  , Value (..)
  , genericParseJSON
  , genericToJSON
  )
import Data.Aeson.TH (deriveJSON)
import Data.Text (Text)
import Data.UUID.Types (UUID)
import GHC.Generics (Generic)
import System.Random.Stateful (Uniform (..), uniformM)

import CardPG.Core.Json (cardpgJsonDef, cardpgJsonOptions)
import CardPG.Core.Util (tshow)

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

newtype ActorId = ActorId UUID
  deriving stock (Show, Eq, Ord)
  deriving newtype (FromJSONKey, ToJSONKey)

instance Uniform ActorId where
  uniformM g = ActorId <$> uniformM g

$(deriveJSON cardpgJsonDef ''ActorId)

-- | Discriminator for Logic
data CardKind = KindCore | KindTable
  deriving stock (Show, Eq, Generic)

$(deriveJSON cardpgJsonDef ''CardKind)

data EquipSlot = SlotMainHand | SlotOffHand | SlotBody | SlotAccessory | SlotUnspecified
  deriving stock (Show, Eq, Generic)

$(deriveJSON cardpgJsonDef ''EquipSlot)

data CardLocation = LocationHand | LocationDiscard | LocationDeck
  deriving stock (Show, Eq, Generic)

$(deriveJSON (cardpgJsonOptions "Location") ''CardLocation)

newtype ChallengeId = ChallengeId UUID
  deriving stock (Show, Eq, Ord)
  deriving newtype (FromJSONKey, ToJSONKey)

$(deriveJSON cardpgJsonDef ''ChallengeId)

instance Uniform ChallengeId where
  uniformM g = ChallengeId <$> uniformM g
