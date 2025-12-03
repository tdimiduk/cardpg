{-# LANGUAGE TemplateHaskell #-}
{-# LANGUAGE ScopedTypeVariables #-}
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

import Data.Aeson.TH (deriveJSON)
import Data.Aeson.TypeScript.TH (deriveTypeScript)
import Data.Text (Text)
import Data.List.NonEmpty (NonEmpty)
import GHC.Generics (Generic)

import CardPG.Core.Types (ResourceType(..))
import CardPG.Core.RichText
import CardPG.Core.Json
import CardPG.Core.RuleDefs
import CardPG.Core.RuleInstances ()
import CardPG.Core.NonEmptyText (NonEmptyText)

data Stats = Stats { _red :: Int, _yellow :: Int, _blue :: Int }
  deriving stock (Eq, Show, Generic)

$(deriveJSON cardpgJsonDef ''Stats)
$(deriveTypeScript cardpgJsonDef ''Stats)

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

$(deriveJSON (cardpgTaggedOptions "") ''CoreCard)
$(deriveTypeScript (cardpgTaggedOptions "") ''CoreCard)

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

$(deriveJSON (cardpgTaggedOptions "") ''ItemCard)
$(deriveTypeScript (cardpgTaggedOptions "") ''ItemCard)

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

$(deriveJSON cardpgJsonDef ''NatureCard)
$(deriveTypeScript cardpgJsonDef ''NatureCard)

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

$(deriveJSON cardpgJsonDef ''TalentCard)
$(deriveTypeScript cardpgJsonDef ''TalentCard)

-- | Represents a General Action / Skill Check.
data GeneralActionDef = GeneralActionDef
  { _name       :: Text
  , _description :: Text
  , _attribute  :: ResourceType -- ^ The Color (Red/Yellow/Blue)
  , _difficulty :: Int          -- ^ The Strength required
  }
  deriving stock (Eq, Show, Generic)

$(deriveJSON cardpgJsonDef ''GeneralActionDef)
$(deriveTypeScript cardpgJsonDef ''GeneralActionDef)

-- | Structured Mechanics for Encounters.
data EncounterMechanics = EncounterMechanics
  { _combat     :: Maybe (NonEmpty Text) -- ^ List of Enemy IDs
  , _challenges :: Maybe (NonEmpty GeneralActionDef) -- ^ List of General Actions/Checks
  , _effects    :: Maybe (NonEmpty Text) -- ^ Narrative effects
  }
  deriving stock (Eq, Show, Generic)

$(deriveJSON cardpgJsonDef ''EncounterMechanics)
$(deriveTypeScript cardpgJsonDef ''EncounterMechanics)

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

$(deriveJSON cardpgJsonDef ''EncounterCard)
$(deriveTypeScript cardpgJsonDef ''EncounterCard)

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

$(deriveJSON cardpgJsonDef ''ConsequenceCard)
$(deriveTypeScript cardpgJsonDef ''ConsequenceCard)

-- | Represents an Actor (Character/Monster/NPC).
data Actor = Actor
  { _name  :: Text
  , _tags  :: Maybe (NonEmpty Text)
  , _items :: [ItemCard]
  , _deck  :: [CoreCard]
  }
  deriving stock (Eq, Show, Generic)

$(deriveJSON cardpgJsonDef ''Actor)
$(deriveTypeScript cardpgJsonDef ''Actor)

