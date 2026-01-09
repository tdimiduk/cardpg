module Core.Primitives
  ( CardInstanceId (..)
  , TargetId (..)
  , ActorId (..)
  , CardKind (..)
  , EquipSlot (..)
  , CardLocation (..)
  , ChallengeId (..)
  , Identified (..)
  ) where

import Data.Aeson
  ( FromJSON (..)
  , FromJSONKey
  , ToJSON (..)
  , ToJSONKey
  , genericToJSON
  , withObject
  , (.:)
  )
import Data.Aeson.TH (deriveJSON)
import Data.UUID.Types (UUID)
import GHC.Generics (Generic)
import System.Random.Stateful (Uniform (..), uniformM)

import Core.Json (cardpgJsonDef, cardpgJsonOptions)

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
  deriving stock (Show, Eq, Ord, Generic)

$(deriveJSON cardpgJsonDef ''CardKind)

data EquipSlot = SlotMainHand | SlotOffHand | SlotBody | SlotAccessory | SlotUnspecified
  deriving stock (Show, Eq, Ord, Generic)

$(deriveJSON cardpgJsonDef ''EquipSlot)

data CardLocation = LocationHand | LocationDiscard | LocationDeck
  deriving stock (Show, Eq, Ord, Generic)

$(deriveJSON (cardpgJsonOptions "Location") ''CardLocation)

newtype ChallengeId = ChallengeId UUID
  deriving stock (Show, Eq, Ord)
  deriving newtype (FromJSONKey, ToJSONKey)

$(deriveJSON cardpgJsonDef ''ChallengeId)

instance Uniform ChallengeId where
  uniformM g = ChallengeId <$> uniformM g

data Identified id a = Identified
  { id :: id
  , content :: a
  }
  deriving stock (Eq, Show, Generic)

instance (ToJSON id, ToJSON a) => ToJSON (Identified id a) where
  toJSON = genericToJSON cardpgJsonDef

instance (FromJSON id, FromJSON a) => FromJSON (Identified id a) where
  parseJSON = withObject "Identified" $ \o -> do
    i <- o .: "id"
    c <- o .: "content"
    return $ Identified i c
