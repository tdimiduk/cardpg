
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
  , ActorDefinitionT (..)
  , ActorDefinition
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
import CardPG.Core.Primitives (Difficulty, ResourceType (..), StackPower)
import CardPG.Core.RichText
import CardPG.Core.RuleDefs
import CardPG.Core.RuleInstances ()

data Stats = Stats {red :: Int, yellow :: Int, blue :: Int}
  deriving stock (Eq, Show, Generic)

$(deriveJSON cardpgJsonDef ''Stats)

data SpecialDefend = SpecialDefend
  { red :: ResourceType
  , yellow :: ResourceType
  , blue :: ResourceType
  }
  deriving stock (Eq, Show, Generic)

$(deriveJSON cardpgJsonDef ''SpecialDefend)

data CoreCardT id rule rt = CoreCard
  { id :: id
  , name :: NonEmptyText
  , tags :: Maybe (NonEmpty Text)
  , stats :: Stats
  , cost :: Maybe Int
  -- ^ Play Cost (Cards to discard to initiate stack).
  --   | Nothing = Status/Resource (cannot be played).
  , rules :: Maybe (NonEmpty rule)
  -- ^ The Source of Truth.
  --   | VTT Renderer: Iterates this list to draw the text box.
  --   | VTT Engine: Filters for 'Active' rules to generate buttons.
  --   | Supports multiple actions (Fatigue) via list length > 1.
  , flavor :: Maybe rt
  }
  deriving stock (Eq, Show, Generic)

type CoreCard = CoreCardT (Maybe Text) DSLRule RichString
type CoreCardMachine = CoreCardT Text Rule RichText

$(deriveJSON (cardpgTaggedOptions "") ''CoreCardT)

-- | Represents Items/Equipment that stay in play (Table Cards).
data ItemCardT id rt = ItemCard
  { id :: id
  , name :: NonEmptyText
  , tags :: Maybe (NonEmpty Text)
  , flavor :: Maybe rt
  , weight :: Maybe Int
  , value :: Maybe Int
  , traits :: Maybe (NonEmpty Text)
  , passive :: Maybe Text
  , defense :: Maybe Int
  , resilience :: Maybe Int
  , burden :: Maybe Int
  }
  deriving stock (Eq, Show, Generic)

type ItemCard = ItemCardT (Maybe Text) RichString
type ItemCardMachine = ItemCardT Text RichText

$(deriveJSON (cardpgTaggedOptions "") ''ItemCardT)

-- | Represents Innate Characteristics (Species, Natural Resilience).
data NatureCardT id rt = NatureCard
  { id :: id
  , name :: NonEmptyText
  , tags :: Maybe (NonEmpty Text)
  , flavor :: Maybe rt
  , traits :: Maybe (NonEmpty Text)
  , passive :: Maybe Text
  , defense :: Maybe Int
  , resilience :: Maybe Int
  , specialDefend :: Maybe SpecialDefend
  }
  deriving stock (Eq, Show, Generic)

type NatureCard = NatureCardT (Maybe Text) RichString
type NatureCardMachine = NatureCardT Text RichText

$(deriveJSON (cardpgTaggedOptions "") ''NatureCardT)

-- | Represents Learned Skills/Training (Proficiencies, Feats).
data TalentCardT id rt = TalentCard
  { id :: id
  , name :: NonEmptyText
  , tags :: Maybe (NonEmpty Text)
  , flavor :: Maybe rt
  , traits :: Maybe (NonEmpty Text)
  , passive :: Maybe Text
  , defense :: Maybe Int
  }
  deriving stock (Eq, Show, Generic)

type TalentCard = TalentCardT (Maybe Text) RichString
type TalentCardMachine = TalentCardT Text RichText

$(deriveJSON (cardpgTaggedOptions "") ''TalentCardT)

-- | Represents a General Action / Skill Check.
data GeneralActionDef = GeneralActionDef
  { name :: Text
  , description :: Text
  , attribute :: ResourceType
  -- ^ The Color (Red/Yellow/Blue)
  , difficulty :: Int
  -- ^ The Strength required
  }
  deriving stock (Eq, Show, Generic)

$(deriveJSON cardpgJsonDef ''GeneralActionDef)

-- | Structured Mechanics for Encounters.
data EncounterMechanics = EncounterMechanics
  { combat :: Maybe (NonEmpty Text)
  -- ^ List of Enemy IDs
  , challenges :: Maybe (NonEmpty GeneralActionDef)
  -- ^ List of General Actions/Checks
  , effects :: Maybe (NonEmpty Text)
  -- ^ Narrative effects
  }
  deriving stock (Eq, Show, Generic)

$(deriveJSON cardpgJsonDef ''EncounterMechanics)

-- | Represents Narrative Encounters/Events.
data EncounterCardT id rt = EncounterCard
  { id :: id
  , name :: NonEmptyText
  , tags :: Maybe (NonEmpty Text)
  , narrative :: rt
  , options :: Maybe (NonEmpty Text)
  , mechanics :: Maybe EncounterMechanics
  }
  deriving stock (Eq, Show, Generic)

type EncounterCard = EncounterCardT (Maybe Text) RichString
type EncounterCardMachine = EncounterCardT Text RichText

$(deriveJSON cardpgJsonDef ''EncounterCardT)

-- | Represents Status Effects / Consequences.
data ConsequenceCardT id rule = ConsequenceCard
  { id :: id
  , name :: NonEmptyText
  , tags :: Maybe (NonEmpty Text)
  , passive :: Maybe Text
  , effects :: Maybe (NonEmpty Text)
  , severity :: Int
  , notes :: Maybe Text
  , rules :: Maybe (NonEmpty rule)
  }
  deriving stock (Eq, Show, Generic)

type ConsequenceCard = ConsequenceCardT (Maybe Text) DSLRule
type ConsequenceCardMachine = ConsequenceCardT Text Rule

$(deriveJSON (cardpgTaggedOptions "") ''ConsequenceCardT)

-- | Represents the *Static Definition* or "Character Sheet" of an Actor.
-- This is used for initialization and templates, not for running game state.
data ActorDefinitionT id rule rt = ActorDefinition
  { id :: id
  , name :: Text
  , tags :: Maybe (NonEmpty Text)
  , items :: [ItemCardT id rt]
  , nature :: [NatureCardT id rt]
  , deck :: [CoreCardT id rule rt]
  }
  deriving stock (Eq, Show, Generic)

type ActorDefinition = ActorDefinitionT (Maybe Text) DSLRule RichString
type ActorMachine = ActorDefinitionT Text Rule RichText

$(deriveJSON cardpgJsonDef ''ActorDefinitionT)
