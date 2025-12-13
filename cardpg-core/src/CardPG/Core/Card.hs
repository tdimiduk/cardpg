module CardPG.Core.Card
  ( module CardPG.Core.RuleDefs
  , Stats (..)
  , SpecialDefend (..)
  , CoreCardT (..)
  , CoreCard
  , CoreCardDSL
  , ItemCardT (..)
  , ItemCard
  , ItemCardDSL
  , NatureCardT (..)
  , NatureCard
  , NatureCardDSL
  , TalentCardT (..)
  , TalentCard
  , TalentCardDSL
  , GeneralActionDef (..)
  , EncounterMechanics (..)
  , EncounterCardT (..)
  , EncounterCard
  , EncounterCardDSL
  , ConsequenceCardT (..)
  , ConsequenceCard
  , ConsequenceCardDSL
  , ActorDefinitionT (..)
  , ActorDefinition
  , ActorDefinitionDSL
  , Identified (..)
  , CardInstance
  ) where

import Data.Aeson
  ( FromJSON (..)
  , ToJSON (..)
  , Value (Object)
  , genericParseJSON
  , genericToJSON
  , (.:)
  )
import Data.Aeson.TH (deriveJSON)
import Data.List.NonEmpty (NonEmpty)
import Data.Text (Text)
import GHC.Generics (Generic)

import CardPG.Core.Json
import CardPG.Core.NonEmptyText (NonEmptyText)
import CardPG.Core.Primitives (CardInstanceId, ResourceType (..))
import CardPG.Core.RichText
import CardPG.Core.RuleDefs
import CardPG.Core.RuleInstances ()

data Identified id a = Identified
  { id :: id
  , content :: a
  }
  deriving stock (Eq, Show, Generic)

instance (ToJSON id, ToJSON a) => ToJSON (Identified id a) where
  toJSON = genericToJSON cardpgJsonDef

instance (FromJSON id, FromJSON a) => FromJSON (Identified id a) where
  parseJSON v = case v of
    Object o -> do
      i <- o .: "id"
      c <- parseJSON v
      return $ Identified i c
    _ -> genericParseJSON cardpgJsonDef v -- Fallback (unlikely to work for generic but maybe for nested)

type CardInstance a = Identified CardInstanceId a

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

data CoreCardT rule rt = CoreCard
  { name :: NonEmptyText
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

type CoreCardDSL = CoreCardT DSLRule RichString
type CoreCard = CoreCardT Rule RichText

$(deriveJSON (cardpgTaggedOptions "") ''CoreCardT)

-- | Represents Items/Equipment that stay in play (Table Cards).
data ItemCardT rt = ItemCard
  { name :: NonEmptyText
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

type ItemCardDSL = ItemCardT RichString
type ItemCard = ItemCardT RichText

$(deriveJSON (cardpgTaggedOptions "") ''ItemCardT)

-- | Represents Innate Characteristics (Species, Natural Resilience).
data NatureCardT rt = NatureCard
  { name :: NonEmptyText
  , tags :: Maybe (NonEmpty Text)
  , flavor :: Maybe rt
  , traits :: Maybe (NonEmpty Text)
  , passive :: Maybe Text
  , defense :: Maybe Int
  , resilience :: Maybe Int
  , specialDefend :: Maybe SpecialDefend
  }
  deriving stock (Eq, Show, Generic)

type NatureCardDSL = NatureCardT RichString
type NatureCard = NatureCardT RichText

$(deriveJSON (cardpgTaggedOptions "") ''NatureCardT)

-- | Represents Learned Skills/Training (Proficiencies, Feats).
data TalentCardT rt = TalentCard
  { name :: NonEmptyText
  , tags :: Maybe (NonEmpty Text)
  , flavor :: Maybe rt
  , traits :: Maybe (NonEmpty Text)
  , passive :: Maybe Text
  , defense :: Maybe Int
  }
  deriving stock (Eq, Show, Generic)

type TalentCardDSL = TalentCardT RichString
type TalentCard = TalentCardT RichText

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
data EncounterCardT rt = EncounterCard
  { name :: NonEmptyText
  , tags :: Maybe (NonEmpty Text)
  , narrative :: rt
  , options :: Maybe (NonEmpty Text)
  , mechanics :: Maybe EncounterMechanics
  }
  deriving stock (Eq, Show, Generic)

type EncounterCardDSL = EncounterCardT RichString
type EncounterCard = EncounterCardT RichText

$(deriveJSON cardpgJsonDef ''EncounterCardT)

-- | Represents Status Effects / Consequences.
data ConsequenceCardT rule = ConsequenceCard
  { name :: NonEmptyText
  , tags :: Maybe (NonEmpty Text)
  , passive :: Maybe Text
  , effects :: Maybe (NonEmpty Text)
  , severity :: Int
  , notes :: Maybe Text
  , rules :: Maybe (NonEmpty rule)
  }
  deriving stock (Eq, Show, Generic)

type ConsequenceCardDSL = ConsequenceCardT DSLRule
type ConsequenceCard = ConsequenceCardT Rule

$(deriveJSON (cardpgTaggedOptions "") ''ConsequenceCardT)

-- | Represents the *Static Definition* or "Character Sheet" of an Actor.
-- This is used for initialization and templates, not for running game state.
data ActorDefinitionT rule rt = ActorDefinition
  { name :: Text
  , tags :: Maybe (NonEmpty Text)
  , items :: [ItemCardT rt]
  , nature :: [NatureCardT rt]
  , deck :: [CoreCardT rule rt]
  }
  deriving stock (Eq, Show, Generic)

type ActorDefinitionDSL = ActorDefinitionT DSLRule RichString
type ActorDefinition = ActorDefinitionT Rule RichText

$(deriveJSON cardpgJsonDef ''ActorDefinitionT)
