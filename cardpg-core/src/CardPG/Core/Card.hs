{-# LANGUAGE DeriveGeneric #-}
{-# LANGUAGE DuplicateRecordFields #-}
{-# LANGUAGE OverloadedStrings #-}

module CardPG.Core.Card where

import Data.Aeson (ToJSON(..), FromJSON(..), genericToJSON, genericToEncoding, genericParseJSON)
import Data.Text (Text)
import Data.List.NonEmpty (NonEmpty)
import GHC.Generics (Generic)

import CardPG.Core.Types (ResourceType(..))
import CardPG.Core.RichText 
import CardPG.Core.Json

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
-- | Persistent Effects: Stance
data StanceDef = StanceDef
  { _duration :: Text
  }
  deriving stock (Eq, Show, Generic)

instance ToJSON StanceDef where
  toJSON = genericToJSON cardpgJsonDef
  toEncoding = genericToEncoding cardpgJsonDef

instance FromJSON StanceDef where
  parseJSON = genericParseJSON cardpgJsonDef

-- | Persistent Effects: Channel
data ChannelDef = ChannelDef
  { _duration :: Text
  }
  deriving stock (Eq, Show, Generic)

instance ToJSON ChannelDef where
  toJSON = genericToJSON cardpgJsonDef
  toEncoding = genericToEncoding cardpgJsonDef

instance FromJSON ChannelDef where
  parseJSON = genericParseJSON cardpgJsonDef

-- | Persistent Effects: Prime
data PrimeDef = PrimeDef
  { _trigger  :: Text
  , _reaction :: Rule
  }
  deriving stock (Eq, Show, Generic)

instance ToJSON PrimeDef where
  toJSON = genericToJSON cardpgJsonDef
  toEncoding = genericToEncoding cardpgJsonDef

instance FromJSON PrimeDef where
  parseJSON = genericParseJSON cardpgJsonDef


-- | The "Do Something" Sum Type
-- | The Top-Level Rule Sum Type
data Rule
  = RuleAttack  AttackDef
  | RuleDefend  DefendDef
  | RuleGeneral GeneralDef
  | RuleStance  StanceDef
  | RuleChannel ChannelDef
  | RulePrime   PrimeDef
  | RuleNarrative RichString
  | RulePassive PassiveDef
  deriving stock (Eq, Show, Generic)

instance ToJSON Rule where
  toJSON = genericToJSON (cardpgJsonOptions "Rule")
  toEncoding = genericToEncoding (cardpgJsonOptions "Rule")

instance FromJSON Rule where
  parseJSON = genericParseJSON (cardpgJsonOptions "Rule")

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
  deriving stock (Eq, Show, Generic)

instance ToJSON DeckCard where
  toJSON = genericToJSON cardpgJsonDef
  toEncoding = genericToEncoding cardpgJsonDef

instance FromJSON DeckCard where
  parseJSON = genericParseJSON cardpgJsonDef
