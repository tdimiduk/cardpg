module CardPG.Core.Card 
  ( module CardPG.Core.RuleDefs
  , Stats(..)
  , CoreCard(..)
  , ItemCard(..)
  , NatureCard(..)
  , TalentCard(..)
  , GeneralActionDef(..)
  , EncounterMechanics(..)
  , EncounterCard(..)
  , ConsequenceCard(..)
  , Actor(..)
  ) where

import Data.Aeson (ToJSON(..), FromJSON(..), genericToJSON, genericToEncoding, genericParseJSON, withObject, (.:), (.:?), (.!=))
import Data.Text (Text)
import Data.List.NonEmpty (NonEmpty)
import qualified Data.List.NonEmpty as NE
import GHC.Generics (Generic)

import CardPG.Core.Types (ResourceType(..))
import CardPG.Core.RichText
import CardPG.Core.Json
import CardPG.Core.RuleDefs
import CardPG.Core.RuleInstances ()
import CardPG.Core.NonEmptyText (NonEmptyText)

data Stats = Stats { _red :: Int, _yellow :: Int, _blue :: Int }
  deriving stock (Eq, Show, Generic)

instance ToJSON Stats where
  toJSON = genericToJSON cardpgJsonDef
  toEncoding = genericToEncoding cardpgJsonDef

instance FromJSON Stats where
  parseJSON = genericParseJSON cardpgJsonDef

data CoreCard = CoreCard
  { _id     :: Maybe Text
  , _name   :: NonEmptyText
  , _tags   :: Maybe (NonEmpty Text)
  , _stats  :: Stats
  
  -- | Play Cost (Cards to discard to initiate stack).
  -- | Nothing = Status/Resource (cannot be played).
  , _cost   :: Maybe Int
  
  -- | The Source of Truth.
  -- | VTT Renderer: Iterates this list to draw the text box.
  -- | VTT Engine: Filters for 'Active' rules to generate buttons.
  -- | Supports multiple actions (Fatigue) via list length > 1.
  , _rules  :: Maybe (NonEmpty Rule)
  
  , _flavor :: Maybe RichString
  }
  deriving stock (Eq, Show, Generic)

instance ToJSON CoreCard where
  toJSON = genericToJSON cardpgJsonDef
  toEncoding = genericToEncoding cardpgJsonDef

instance FromJSON CoreCard where
  parseJSON = withObject "CoreCard" $ \v -> do
    _id <- v .:? "id"
    _name <- v .: "name"
    tags <- v .:? "tags"
    _stats <- v .: "stats"
    _cost <- v .:? "cost"
    rules <- v .:? "rules"
    _flavor <- v .:? "flavor"
    pure CoreCard
      { _id = _id
      , _name = _name
      , _tags = tags
      , _stats = _stats
      , _cost = _cost
      , _rules = rules
      , _flavor = _flavor
      }

-- | Represents Items/Equipment that stay in play (Table Cards).
data ItemCard = ItemCard
  { _id         :: Maybe Text
  , _name       :: NonEmptyText
  , _tags       :: Maybe (NonEmpty Text)
  , _flavor     :: Maybe RichString
  , _weight     :: Maybe Int
  , _value      :: Maybe Int
  , _traits     :: Maybe (NonEmpty Text)
  , _passive    :: Maybe Text
  , _defense    :: Maybe Int
  , _resilience :: Maybe Int
  }
  deriving stock (Eq, Show, Generic)

instance ToJSON ItemCard where
  toJSON = genericToJSON cardpgJsonDef
  toEncoding = genericToEncoding cardpgJsonDef

instance FromJSON ItemCard where
  parseJSON = withObject "ItemCard" $ \v -> do
    _id <- v .:? "id"
    _name <- v .: "name"
    tags <- v .:? "tags"
    _flavor <- v .:? "flavor"
    _weight <- v .:? "weight"
    _value <- v .:? "value"
    traits <- v .:? "traits"
    _passive <- v .:? "passive"
    _defense <- v .:? "defense"
    _resilience <- v .:? "resilience"
    pure ItemCard
      { _id = _id
      , _name = _name
      , _tags = tags
      , _flavor = _flavor
      , _weight = _weight
      , _value = _value
      , _traits = traits
      , _passive = _passive
      , _defense = _defense
      , _resilience = _resilience
      }

-- | Represents Innate Characteristics (Species, Natural Resilience).
data NatureCard = NatureCard
  { _id         :: Maybe Text
  , _name       :: NonEmptyText
  , _tags       :: Maybe (NonEmpty Text)
  , _flavor     :: Maybe RichString
  , _traits     :: Maybe (NonEmpty Text)
  , _passive    :: Maybe Text
  , _defense    :: Maybe Int
  , _resilience :: Maybe Int
  }
  deriving stock (Eq, Show, Generic)

instance ToJSON NatureCard where
  toJSON = genericToJSON cardpgJsonDef
  toEncoding = genericToEncoding cardpgJsonDef

instance FromJSON NatureCard where
  parseJSON = withObject "NatureCard" $ \v -> do
    _id <- v .:? "id"
    _name <- v .: "name"
    tags <- v .:? "tags"
    _flavor <- v .:? "flavor"
    traits <- v .:? "traits"
    _passive <- v .:? "passive"
    _defense <- v .:? "defense"
    _resilience <- v .:? "resilience"
    pure NatureCard
      { _id = _id
      , _name = _name
      , _tags = tags
      , _flavor = _flavor
      , _traits = traits
      , _passive = _passive
      , _defense = _defense
      , _resilience = _resilience
      }

-- | Represents Learned Skills/Training (Proficiencies, Feats).
data TalentCard = TalentCard
  { _id         :: Maybe Text
  , _name       :: NonEmptyText
  , _tags       :: Maybe (NonEmpty Text)
  , _flavor     :: Maybe RichString
  , _traits     :: Maybe (NonEmpty Text)
  , _passive    :: Maybe Text
  , _defense    :: Maybe Int
  }
  deriving stock (Eq, Show, Generic)

instance ToJSON TalentCard where
  toJSON = genericToJSON cardpgJsonDef
  toEncoding = genericToEncoding cardpgJsonDef

instance FromJSON TalentCard where
  parseJSON = withObject "TalentCard" $ \v -> do
    _id <- v .:? "id"
    _name <- v .: "name"
    tags <- v .:? "tags"
    _flavor <- v .:? "flavor"
    traits <- v .:? "traits"
    _passive <- v .:? "passive"
    _defense <- v .:? "defense"
    pure TalentCard
      { _id = _id
      , _name = _name
      , _tags = tags
      , _flavor = _flavor
      , _traits = traits
      , _passive = _passive
      , _defense = _defense
      }

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
  { _combat     :: Maybe (NonEmpty Text) -- ^ List of Enemy IDs
  , _challenges :: Maybe (NonEmpty GeneralActionDef) -- ^ List of General Actions/Checks
  , _effects    :: Maybe (NonEmpty Text) -- ^ Narrative effects
  }
  deriving stock (Eq, Show, Generic)

instance ToJSON EncounterMechanics where
  toJSON = genericToJSON cardpgJsonDef
  toEncoding = genericToEncoding cardpgJsonDef

instance FromJSON EncounterMechanics where
  parseJSON = withObject "EncounterMechanics" $ \v -> do
    combat <- v .:? "combat" .!= []
    challenges <- v .:? "challenges" .!= []
    effects <- v .:? "effects" .!= []
    pure EncounterMechanics
      { _combat = NE.nonEmpty combat
      , _challenges = NE.nonEmpty challenges
      , _effects = NE.nonEmpty effects
      }

-- | Represents Narrative Encounters/Events.
data EncounterCard = EncounterCard
  { _id        :: Maybe Text
  , _name      :: NonEmptyText
  , _tags      :: Maybe (NonEmpty Text)
  , _narrative :: RichString
  , _options   :: Maybe (NonEmpty Text)
  , _mechanics :: Maybe EncounterMechanics
  }
  deriving stock (Eq, Show, Generic)

instance ToJSON EncounterCard where
  toJSON = genericToJSON cardpgJsonDef
  toEncoding = genericToEncoding cardpgJsonDef

instance FromJSON EncounterCard where
  parseJSON = withObject "EncounterCard" $ \v -> do
    _id <- v .:? "id"
    _name <- v .: "name"
    tags <- v .:? "tags"
    _narrative <- v .: "narrative"
    options <- v .:? "options"
    _mechanics <- v .:? "mechanics"
    pure EncounterCard
      { _id = _id
      , _name = _name
      , _tags = tags
      , _narrative = _narrative
      , _options = options
      , _mechanics = _mechanics
      }

-- | Represents Status Effects / Consequences.
data ConsequenceCard = ConsequenceCard
  { _id      :: Maybe Text
  , _name    :: NonEmptyText
  , _tags    :: Maybe (NonEmpty Text)
  , _passive :: Maybe Text
  , _effects :: Maybe (NonEmpty Text)
  , _notes   :: Maybe Text
  , _rules   :: Maybe (NonEmpty Rule)
  }
  deriving stock (Eq, Show, Generic)

instance ToJSON ConsequenceCard where
  toJSON = genericToJSON cardpgJsonDef
  toEncoding = genericToEncoding cardpgJsonDef

instance FromJSON ConsequenceCard where
  parseJSON = withObject "ConsequenceCard" $ \v -> do
    _id <- v .:? "id"
    _name <- v .: "name"
    tags <- v .:? "tags"
    _passive <- v .:? "passive"
    effects <- v .:? "effects"
    _notes <- v .:? "notes"
    rules <- v .:? "rules"
    pure ConsequenceCard
      { _id = _id
      , _name = _name
      , _tags = tags
      , _passive = _passive
      , _effects = effects
      , _notes = _notes
      , _rules = rules
      }

-- | Represents an Actor (Character/Monster/NPC).
data Actor = Actor
  { _name  :: Text
  , _tags  :: Maybe (NonEmpty Text)
  , _items :: [ItemCard]
  , _deck  :: [CoreCard]
  }
  deriving stock (Eq, Show, Generic)

instance ToJSON Actor where
  toJSON = genericToJSON cardpgJsonDef
  toEncoding = genericToEncoding cardpgJsonDef

instance FromJSON Actor where
  parseJSON = genericParseJSON cardpgJsonDef

