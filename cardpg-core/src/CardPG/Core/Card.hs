{-# LANGUAGE ScopedTypeVariables #-}
{-# LANGUAGE TemplateHaskell #-}

module CardPG.Core.Card
  ( module CardPG.Core.RuleDefs
  , Stats (..)
  , SpecialDefend (..)
  , CoreCardT (..)
  , CoreCard
  , CoreCardMachine
  , ItemCardT (..)
  , ItemCard
  , NatureCardT (..)
  , NatureCard
  , TalentCardT (..)
  , TalentCard
  , GeneralActionDef (..)
  , EncounterMechanics (..)
  , EncounterCardT (..)
  , EncounterCard
  , ConsequenceCardT (..)
  , ConsequenceCard
  , ConsequenceCardMachine
  , ActorT (..)
  , Actor
  , ActorMachine
  , ItemCardMachine
  , NatureCardMachine
  , TalentCardMachine
  , EncounterCardMachine
  ) where

import Data.Aeson.TH (deriveJSON)
import Data.List.NonEmpty (NonEmpty)
import Data.Text (Text)
import GHC.Generics (Generic)

import CardPG.Core.Json
import CardPG.Core.NonEmptyText (NonEmptyText)
import CardPG.Core.RichText
import CardPG.Core.RuleDefs
import CardPG.Core.RuleInstances ()
import CardPG.Core.Types (ResourceType (..))

data Stats = Stats {_red :: Int, _yellow :: Int, _blue :: Int}
  deriving stock (Eq, Show, Generic)

$(deriveJSON cardpgJsonDef ''Stats)

data SpecialDefend = SpecialDefend
  { _red :: ResourceType
  , _yellow :: ResourceType
  , _blue :: ResourceType
  }
  deriving stock (Eq, Show, Generic)

$(deriveJSON cardpgJsonDef ''SpecialDefend)

data CoreCardT id rule rt = CoreCard
  { _id :: id
  , _name :: NonEmptyText
  , _tags :: Maybe (NonEmpty Text)
  , _stats :: Stats
  , _cost :: Maybe Int
  -- ^ Play Cost (Cards to discard to initiate stack).
  --   | Nothing = Status/Resource (cannot be played).
  , _rules :: Maybe (NonEmpty rule)
  -- ^ The Source of Truth.
  --   | VTT Renderer: Iterates this list to draw the text box.
  --   | VTT Engine: Filters for 'Active' rules to generate buttons.
  --   | Supports multiple actions (Fatigue) via list length > 1.
  , _flavor :: Maybe rt
  }
  deriving stock (Eq, Show, Generic)

type CoreCard = CoreCardT (Maybe Text) DSLRule RichString
type CoreCardMachine = CoreCardT Text Rule RichText

$(deriveJSON (cardpgTaggedOptions "") ''CoreCardT)

-- | Represents Items/Equipment that stay in play (Table Cards).
data ItemCardT id rt = ItemCard
  { _id :: id
  , _name :: NonEmptyText
  , _tags :: Maybe (NonEmpty Text)
  , _flavor :: Maybe rt
  , _weight :: Maybe Int
  , _value :: Maybe Int
  , _traits :: Maybe (NonEmpty Text)
  , _passive :: Maybe Text
  , _defense :: Maybe Int
  , _resilience :: Maybe Int
  , _burden :: Maybe Int
  }
  deriving stock (Eq, Show, Generic)

type ItemCard = ItemCardT (Maybe Text) RichString
type ItemCardMachine = ItemCardT Text RichText

$(deriveJSON (cardpgTaggedOptions "") ''ItemCardT)

-- | Represents Innate Characteristics (Species, Natural Resilience).
data NatureCardT id rt = NatureCard
  { _id :: id
  , _name :: NonEmptyText
  , _tags :: Maybe (NonEmpty Text)
  , _flavor :: Maybe rt
  , _traits :: Maybe (NonEmpty Text)
  , _passive :: Maybe Text
  , _defense :: Maybe Int
  , _resilience :: Maybe Int
  , _specialDefend :: Maybe SpecialDefend
  }
  deriving stock (Eq, Show, Generic)

type NatureCard = NatureCardT (Maybe Text) RichString
type NatureCardMachine = NatureCardT Text RichText

$(deriveJSON (cardpgTaggedOptions "") ''NatureCardT)

-- | Represents Learned Skills/Training (Proficiencies, Feats).
data TalentCardT id rt = TalentCard
  { _id :: id
  , _name :: NonEmptyText
  , _tags :: Maybe (NonEmpty Text)
  , _flavor :: Maybe rt
  , _traits :: Maybe (NonEmpty Text)
  , _passive :: Maybe Text
  , _defense :: Maybe Int
  }
  deriving stock (Eq, Show, Generic)

type TalentCard = TalentCardT (Maybe Text) RichString
type TalentCardMachine = TalentCardT Text RichText

$(deriveJSON (cardpgTaggedOptions "") ''TalentCardT)

-- | Represents a General Action / Skill Check.
data GeneralActionDef = GeneralActionDef
  { _name :: Text
  , _description :: Text
  , _attribute :: ResourceType
  -- ^ The Color (Red/Yellow/Blue)
  , _difficulty :: Int
  -- ^ The Strength required
  }
  deriving stock (Eq, Show, Generic)

$(deriveJSON cardpgJsonDef ''GeneralActionDef)

-- | Structured Mechanics for Encounters.
data EncounterMechanics = EncounterMechanics
  { _combat :: Maybe (NonEmpty Text)
  -- ^ List of Enemy IDs
  , _challenges :: Maybe (NonEmpty GeneralActionDef)
  -- ^ List of General Actions/Checks
  , _effects :: Maybe (NonEmpty Text)
  -- ^ Narrative effects
  }
  deriving stock (Eq, Show, Generic)

$(deriveJSON cardpgJsonDef ''EncounterMechanics)

-- | Represents Narrative Encounters/Events.
data EncounterCardT id rt = EncounterCard
  { _id :: id
  , _name :: NonEmptyText
  , _tags :: Maybe (NonEmpty Text)
  , _narrative :: rt
  , _options :: Maybe (NonEmpty Text)
  , _mechanics :: Maybe EncounterMechanics
  }
  deriving stock (Eq, Show, Generic)

type EncounterCard = EncounterCardT (Maybe Text) RichString
type EncounterCardMachine = EncounterCardT Text RichText

$(deriveJSON cardpgJsonDef ''EncounterCardT)

-- | Represents Status Effects / Consequences.
data ConsequenceCardT id rule = ConsequenceCard
  { _id :: id
  , _name :: NonEmptyText
  , _tags :: Maybe (NonEmpty Text)
  , _passive :: Maybe Text
  , _effects :: Maybe (NonEmpty Text)
  , _severity :: Int
  , _notes :: Maybe Text
  , _rules :: Maybe (NonEmpty rule)
  }
  deriving stock (Eq, Show, Generic)

type ConsequenceCard = ConsequenceCardT (Maybe Text) DSLRule
type ConsequenceCardMachine = ConsequenceCardT Text Rule

$(deriveJSON (cardpgTaggedOptions "") ''ConsequenceCardT)

-- | Represents an Actor (Character/Monster/NPC).
data ActorT id rule rt = Actor
  { _id :: id
  , _name :: Text
  , _tags :: Maybe (NonEmpty Text)
  , _items :: [ItemCardT id rt]
  , _nature :: [NatureCardT id rt]
  , _deck :: [CoreCardT id rule rt]
  }
  deriving stock (Eq, Show, Generic)

type Actor = ActorT (Maybe Text) DSLRule RichString
type ActorMachine = ActorT Text Rule RichText

$(deriveJSON cardpgJsonDef ''ActorT)
