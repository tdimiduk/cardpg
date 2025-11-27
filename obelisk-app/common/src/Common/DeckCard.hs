{-# LANGUAGE DeriveGeneric #-}
{-# LANGUAGE DuplicateRecordFields #-}
{-# LANGUAGE OverloadedStrings #-}

module Common.DeckCard where

import Data.Aeson (ToJSON(..), FromJSON(..), genericToJSON, genericToEncoding, genericParseJSON)
import Data.Text (Text)
import Data.List.NonEmpty (NonEmpty)
import GHC.Generics (Generic)

import Common.Card.Common (ResourceType(..))
import Common.RichText 
import Common.Json

-- | A static modifier.
-- | Addresses: "+2 to resource values when used in a defense stack"
data PassiveDef = PassiveDef
  { _bonus     :: StackPower   -- ^ e.g. "Red +2"
  , _condition :: Maybe Text   -- ^ e.g. "when used in a defense stack"
  }
  deriving stock (Eq, Show, Generic)

instance ToJSON PassiveDef where
  toJSON = genericToJSON cardpgJsonDef
  toEncoding = genericToEncoding cardpgJsonDef

instance FromJSON PassiveDef where
  parseJSON = genericParseJSON cardpgJsonDef

-- | Standard Attack Logic
data AttackDef = AttackDef
  { _power      :: StackPower
  , _resistedBy :: ResourceType
  , _effect     :: Maybe RichString
  }
  deriving stock (Eq, Show, Generic)

instance ToJSON AttackDef where
  toJSON = genericToJSON cardpgJsonDef
  toEncoding = genericToEncoding cardpgJsonDef

instance FromJSON AttackDef where
  parseJSON = genericParseJSON cardpgJsonDef

-- | Defense Logic
data DefendDef = DefendDef
  { _power   :: StackPower
  , _resists :: NonEmpty ResourceType
  , _effect  :: Maybe RichString
  }
  deriving stock (Eq, Show, Generic)

instance ToJSON DefendDef where
  toJSON = genericToJSON cardpgJsonDef
  toEncoding = genericToEncoding cardpgJsonDef

instance FromJSON DefendDef where
  parseJSON = genericParseJSON cardpgJsonDef

-- | General/Utility Actions
-- | Addresses: "Fatigue: Action (Sleep 2 hours): Remove this"
data GeneralDef = GeneralDef
  { _power  :: Maybe StackPower -- ^ Optional. Fatigue removal isn't a check.
  , _cost   :: Maybe RichString -- ^ Narrative Cost: "Sleep 2 hours"
  , _effect :: RichString       -- ^ Effect: "Remove this card"
  }
  deriving stock (Eq, Show, Generic)

instance ToJSON GeneralDef where
  toJSON = genericToJSON cardpgJsonDef
  toEncoding = genericToEncoding cardpgJsonDef

instance FromJSON GeneralDef where
  parseJSON = genericParseJSON cardpgJsonDef

-- | Persistent Effects
data InstallDef = InstallDef
  { _duration :: Text
  , _trigger  :: Maybe Text
  , _reaction :: Maybe Action
  }
  deriving stock (Eq, Show, Generic)

instance ToJSON InstallDef where
  toJSON = genericToJSON cardpgJsonDef
  toEncoding = genericToEncoding cardpgJsonDef

instance FromJSON InstallDef where
  parseJSON = genericParseJSON cardpgJsonDef


-- | The "Do Something" Sum Type
data Action
  = DoAttack  AttackDef
  | DoDefend  DefendDef
  | DoGeneral GeneralDef
  | DoInstall InstallDef
  | DoNarrative RichString
  deriving stock (Eq, Show, Generic)

instance ToJSON Action where
  toJSON = genericToJSON (cardpgJsonOptions "Do")
  toEncoding = genericToEncoding cardpgJsonDef

instance FromJSON Action where
  parseJSON = genericParseJSON (cardpgJsonOptions "Do")

-- | The Top-Level Rule Container.
-- | A card's text box is a list of these Rules.
data Rule
  = Active  Action      -- ^ An actionable button on the VTT.
  | Passive PassiveDef  -- ^ A static effect the engine tracks.
  deriving stock (Eq, Show, Generic)

instance ToJSON Rule where
  toJSON = genericToJSON cardpgJsonDef
  toEncoding = genericToEncoding cardpgJsonDef

instance FromJSON Rule where
  parseJSON = genericParseJSON cardpgJsonDef

-- 3. The Card Record
-------------------------------------------------------------------------------

data Stats = Stats { _red :: Int, _yellow :: Int, _blue :: Int }
  deriving stock (Eq, Show, Generic)

instance ToJSON Stats where
  toJSON = genericToJSON cardpgJsonDef
  toEncoding = genericToEncoding cardpgJsonDef

instance FromJSON Stats where
  parseJSON = genericParseJSON cardpgJsonDef

data DeckCard = DeckCard
  { _id     :: Text
  , _name   :: Text
  , _tags   :: [Text]
  , _stats  :: Stats
  
  -- | Play Cost (Cards to discard to initiate stack).
  -- | Nothing = Status/Resource (cannot be played).
  , _cost   :: Maybe Int
  
  -- | The Source of Truth.
  -- | VTT Renderer: Iterates this list to draw the text box.
  -- | VTT Engine: Filters for 'Active' rules to generate buttons.
  -- | Supports multiple actions (Fatigue) via list length > 1.
  , _rules  :: [Rule]
  
  , _flavor :: Maybe RichString
  }
  deriving stock (Show, Generic)

instance ToJSON DeckCard where
  toJSON = genericToJSON cardpgJsonDef
  toEncoding = genericToEncoding cardpgJsonDef

instance FromJSON DeckCard where
  parseJSON = genericParseJSON cardpgJsonDef
