{-# LANGUAGE TemplateHaskell #-}
{-# LANGUAGE ScopedTypeVariables #-}
module CardPG.Core.Card 
  ( module CardPG.Core.RuleDefs
  , Stats(..)
  , CoreCardT(..)
  , CoreCard
  , CoreCardMachine
  , ItemCardT(..)
  , ItemCard
  , NatureCardT(..)
  , NatureCard
  , TalentCardT(..)
  , TalentCard
  , GeneralActionDef(..)
  , EncounterMechanics(..)
  , EncounterCardT(..)
  , EncounterCard
  , ConsequenceCardT(..)
  , ConsequenceCard
  , ConsequenceCardMachine
  , ActorT(..)
  , Actor
  , ActorMachine
  , ItemCardMachine
  , NatureCardMachine
  , TalentCardMachine
  , EncounterCardMachine
  ) where

import Data.Aeson (ToJSON, FromJSON)
import Data.Aeson.TH (deriveJSON)
import Data.Text (Text)
import Data.List.NonEmpty (NonEmpty)
import GHC.Generics (Generic)
import Data.Functor.Classes (Eq1, Show1)

import CardPG.Core.Types (ResourceType(..))
import CardPG.Core.RichText
import CardPG.Core.Json
import CardPG.Core.RuleDefs
import CardPG.Core.RuleInstances ()
import CardPG.Core.NonEmptyText (NonEmptyText)

data Stats = Stats { _red :: Int, _yellow :: Int, _blue :: Int }
  deriving stock (Eq, Show, Generic)

$(deriveJSON cardpgJsonDef ''Stats)

data CoreCardT rule rt = CoreCard
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
  , _rules  :: Maybe (NonEmpty rule)
  
  , _flavor :: Maybe rt
  }
  deriving stock (Eq, Show, Generic)

type CoreCard = CoreCardT DSLRule RichString
type CoreCardMachine = CoreCardT Rule RichText

$(deriveJSON (cardpgTaggedOptions "") ''CoreCardT)

-- | Represents Items/Equipment that stay in play (Table Cards).
data ItemCardT rt = ItemCard
  { _id         :: Maybe Text
  , _name       :: NonEmptyText
  , _tags       :: Maybe (NonEmpty Text)
  , _flavor     :: Maybe rt
  , _weight     :: Maybe Int
  , _value      :: Maybe Int
  , _traits     :: Maybe (NonEmpty Text)
  , _passive    :: Maybe Text
  , _defense    :: Maybe Int
  , _resilience :: Maybe Int
  }
  deriving stock (Eq, Show, Generic)

type ItemCard = ItemCardT RichString
type ItemCardMachine = ItemCardT RichText

$(deriveJSON (cardpgTaggedOptions "") ''ItemCardT)

-- | Represents Innate Characteristics (Species, Natural Resilience).
data NatureCardT rt = NatureCard
  { _id         :: Maybe Text
  , _name       :: NonEmptyText
  , _tags       :: Maybe (NonEmpty Text)
  , _flavor     :: Maybe rt
  , _traits     :: Maybe (NonEmpty Text)
  , _passive    :: Maybe Text
  , _defense    :: Maybe Int
  , _resilience :: Maybe Int
  }
  deriving stock (Eq, Show, Generic)

type NatureCard = NatureCardT RichString
type NatureCardMachine = NatureCardT RichText

$(deriveJSON cardpgJsonDef ''NatureCardT)

-- | Represents Learned Skills/Training (Proficiencies, Feats).
data TalentCardT rt = TalentCard
  { _id         :: Maybe Text
  , _name       :: NonEmptyText
  , _tags       :: Maybe (NonEmpty Text)
  , _flavor     :: Maybe rt
  , _traits     :: Maybe (NonEmpty Text)
  , _passive    :: Maybe Text
  , _defense    :: Maybe Int
  }
  deriving stock (Eq, Show, Generic)

type TalentCard = TalentCardT RichString
type TalentCardMachine = TalentCardT RichText

$(deriveJSON cardpgJsonDef ''TalentCardT)

-- | Represents a General Action / Skill Check.
data GeneralActionDef = GeneralActionDef
  { _name       :: Text
  , _description :: Text
  , _attribute  :: ResourceType -- ^ The Color (Red/Yellow/Blue)
  , _difficulty :: Int          -- ^ The Strength required
  }
  deriving stock (Eq, Show, Generic)

$(deriveJSON cardpgJsonDef ''GeneralActionDef)

-- | Structured Mechanics for Encounters.
data EncounterMechanics = EncounterMechanics
  { _combat     :: Maybe (NonEmpty Text) -- ^ List of Enemy IDs
  , _challenges :: Maybe (NonEmpty GeneralActionDef) -- ^ List of General Actions/Checks
  , _effects    :: Maybe (NonEmpty Text) -- ^ Narrative effects
  }
  deriving stock (Eq, Show, Generic)

$(deriveJSON cardpgJsonDef ''EncounterMechanics)

-- | Represents Narrative Encounters/Events.
data EncounterCardT rt = EncounterCard
  { _id        :: Maybe Text
  , _name      :: NonEmptyText
  , _tags      :: Maybe (NonEmpty Text)
  , _narrative :: rt
  , _options   :: Maybe (NonEmpty Text)
  , _mechanics :: Maybe EncounterMechanics
  }
  deriving stock (Eq, Show, Generic)

type EncounterCard = EncounterCardT RichString
type EncounterCardMachine = EncounterCardT RichText

$(deriveJSON cardpgJsonDef ''EncounterCardT)

-- | Represents Status Effects / Consequences.
data ConsequenceCardT rule = ConsequenceCard
  { _id      :: Maybe Text
  , _name    :: NonEmptyText
  , _tags    :: Maybe (NonEmpty Text)
  , _passive :: Maybe Text
  , _effects :: Maybe (NonEmpty Text)
  , _severity :: Int
  , _notes   :: Maybe Text
  , _rules   :: Maybe (NonEmpty rule)
  }
  deriving stock (Eq, Show, Generic)

type ConsequenceCard = ConsequenceCardT DSLRule
type ConsequenceCardMachine = ConsequenceCardT Rule

$(deriveJSON (cardpgTaggedOptions "") ''ConsequenceCardT)

-- | Represents an Actor (Character/Monster/NPC).
data ActorT rule rt = Actor
  { _name  :: Text
  , _tags  :: Maybe (NonEmpty Text)
  , _items :: [ItemCardT rt]
  , _deck  :: [CoreCardT rule rt]
  }
  deriving stock (Eq, Show, Generic)

type Actor = ActorT DSLRule RichString
type ActorMachine = ActorT Rule RichText

$(deriveJSON cardpgJsonDef ''ActorT)

