{-# LANGUAGE DeriveGeneric #-}
{-# LANGUAGE DuplicateRecordFields #-}
{-# LANGUAGE OverloadedStrings #-}

module CardPG.Core.Card where

import Data.Aeson (ToJSON(..), FromJSON(..), genericToJSON, genericToEncoding, genericParseJSON, Value)
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

data CoreCard = CoreCard
  { _id     :: Maybe Text
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

instance ToJSON CoreCard where
  toJSON = genericToJSON cardpgJsonDef
  toEncoding = genericToEncoding cardpgJsonDef

instance FromJSON CoreCard where
  parseJSON = genericParseJSON cardpgJsonDef

-- | Represents Items/Equipment that stay in play (Table Cards).
data ItemCard = ItemCard
  { _id         :: Maybe Text
  , _name       :: Text
  , _tags       :: [Text]
  , _flavor     :: Maybe RichString
  , _weight     :: Maybe Int
  , _value      :: Maybe Int
  , _traits     :: [Text]
  , _passive    :: Maybe Text
  , _defense    :: Maybe Int
  , _resilience :: Maybe Int
  }
  deriving stock (Eq, Show, Generic)

instance ToJSON ItemCard where
  toJSON = genericToJSON cardpgJsonDef
  toEncoding = genericToEncoding cardpgJsonDef

instance FromJSON ItemCard where
  parseJSON = genericParseJSON cardpgJsonDef

-- | Represents Innate Characteristics (Species, Natural Resilience).
data NatureCard = NatureCard
  { _id         :: Maybe Text
  , _name       :: Text
  , _tags       :: [Text]
  , _flavor     :: Maybe RichString
  , _traits     :: [Text]
  , _passive    :: Maybe Text
  , _defense    :: Maybe Int
  , _resilience :: Maybe Int
  }
  deriving stock (Eq, Show, Generic)

instance ToJSON NatureCard where
  toJSON = genericToJSON cardpgJsonDef
  toEncoding = genericToEncoding cardpgJsonDef

instance FromJSON NatureCard where
  parseJSON = genericParseJSON cardpgJsonDef

-- | Represents Learned Skills/Training (Proficiencies, Feats).
data TalentCard = TalentCard
  { _id         :: Maybe Text
  , _name       :: Text
  , _tags       :: [Text]
  , _flavor     :: Maybe RichString
  , _traits     :: [Text]
  , _passive    :: Maybe Text
  , _defense    :: Maybe Int
  }
  deriving stock (Eq, Show, Generic)

instance ToJSON TalentCard where
  toJSON = genericToJSON cardpgJsonDef
  toEncoding = genericToEncoding cardpgJsonDef

instance FromJSON TalentCard where
  parseJSON = genericParseJSON cardpgJsonDef

-- | Represents a General Action / Skill Check.
data GeneralActionDef = GeneralActionDef
  { _name       :: Text
  , _description :: Text
  , _attribute  :: ResourceType -- ^ The Color (Red/Yellow/Blue)
  , _difficulty :: Int          -- ^ The Strength required
  }
  deriving stock (Eq, Show, Generic)

instance ToJSON GeneralActionDef where
  toJSON = genericToJSON cardpgJsonDef
  toEncoding = genericToEncoding cardpgJsonDef

instance FromJSON GeneralActionDef where
  parseJSON = genericParseJSON cardpgJsonDef

-- | Structured Mechanics for Encounters.
data EncounterMechanics = EncounterMechanics
  { _combat     :: Maybe [Text] -- ^ List of Enemy IDs
  , _challenges :: Maybe [GeneralActionDef] -- ^ List of General Actions/Checks
  , _effects    :: Maybe [Text] -- ^ Narrative effects
  }
  deriving stock (Eq, Show, Generic)

instance ToJSON EncounterMechanics where
  toJSON = genericToJSON cardpgJsonDef
  toEncoding = genericToEncoding cardpgJsonDef

instance FromJSON EncounterMechanics where
  parseJSON = genericParseJSON cardpgJsonDef

-- | Represents Narrative Encounters/Events.
data EncounterCard = EncounterCard
  { _id        :: Maybe Text
  , _name      :: Text
  , _tags      :: [Text]
  , _narrative :: RichString
  , _options   :: Maybe [Text]
  , _mechanics :: Maybe EncounterMechanics
  }
  deriving stock (Eq, Show, Generic)

instance ToJSON EncounterCard where
  toJSON = genericToJSON cardpgJsonDef
  toEncoding = genericToEncoding cardpgJsonDef

instance FromJSON EncounterCard where
  parseJSON = genericParseJSON cardpgJsonDef

-- | Represents Status Effects / Consequences.
data ConsequenceCard = ConsequenceCard
  { _id      :: Maybe Text
  , _name    :: Text
  , _tags    :: [Text]
  , _passive :: Maybe Text
  , _effects :: Maybe [Text]
  , _notes   :: Maybe Text
  , _rules   :: [Rule]
  }
  deriving stock (Eq, Show, Generic)

instance ToJSON ConsequenceCard where
  toJSON = genericToJSON cardpgJsonDef
  toEncoding = genericToEncoding cardpgJsonDef

instance FromJSON ConsequenceCard where
  parseJSON = genericParseJSON cardpgJsonDef

