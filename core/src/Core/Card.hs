module Core.Card
  ( module Core.Rules
  , Stats (..)
  , SpecialDefend
  , CoreCard (..)
  , ItemCard (..)
  , NatureCard (..)
  , TalentCard (..)
  , EncounterCard (..)
  , ConsequenceCard (..)
  , ActorDefinition (..)
  , CustomCard (..)
  , customCardNameText
  , customCardCategoryText
  , customCardIdText
  , customCardFingerprint
  , GeneralActionDef (..)
  , EncounterMechanics (..)
  , Identified (..)
  , CardInstance
  ) where

import Data.Aeson (toJSON)
import Data.Aeson.TH (deriveJSON)
import Data.Char (isAlphaNum, ord, toLower)
import Data.List.NonEmpty (NonEmpty)
import Data.Text (Text)
import Data.Text qualified as T
import GHC.Generics (Generic)

import Core.Json
import Core.NonEmptyText (NonEmptyText, getRawText)
import Core.Primitives (CardInstanceId, Identified (..))
import Core.RichText (RichText)
import Core.Rules

import Core.Stats (ResourceType (..), Stats (..))

type CardInstance a = Identified CardInstanceId a

type SpecialDefend = Stats ResourceType

data CoreCard = CoreCard
  { name :: NonEmptyText
  , tags :: Maybe (NonEmpty Text)
  , stats :: Stats Int
  , cost :: Maybe Int
  -- ^ Play Cost (Cards to discard to initiate stack).
  --   | Nothing = Status/Resource (cannot be played).
  , attack :: Maybe AttackDef
  , rules :: Maybe (NonEmpty Rule)
  -- ^ The Source of Truth.
  --   | VTT Renderer: Iterates this list to draw the text box.
  --   | VTT Engine: Filters for 'Active' rules to generate buttons.
  --   | Supports multiple actions (Fatigue) via list length > 1.
  , flavor :: Maybe RichText
  }
  deriving stock (Eq, Show, Generic)

$(deriveJSON cardpgJsonDef ''CoreCard)

-- | Represents Items/Equipment that stay in play (Table Cards).
data ItemCard = ItemCard
  { name :: NonEmptyText
  , tags :: Maybe (NonEmpty Text)
  , flavor :: Maybe RichText
  , weight :: Maybe Int
  , value :: Maybe Int
  , traits :: Maybe (NonEmpty Text)
  , passive :: Maybe Text
  , defense :: Maybe Int
  , resilience :: Maybe Int
  , burden :: Maybe Int
  }
  deriving stock (Eq, Show, Generic)

$(deriveJSON cardpgJsonDef ''ItemCard)

-- | Represents Innate Characteristics (Species, Natural Resilience).
data NatureCard = NatureCard
  { name :: NonEmptyText
  , tags :: Maybe (NonEmpty Text)
  , flavor :: Maybe RichText
  , traits :: Maybe (NonEmpty Text)
  , passive :: Maybe Text
  , defense :: Maybe Int
  , resilience :: Maybe Int
  , specialDefend :: Maybe SpecialDefend
  }
  deriving stock (Eq, Show, Generic)

$(deriveJSON cardpgJsonDef ''NatureCard)

-- | Represents Learned Skills/Training (Proficiencies, Feats).
data TalentCard = TalentCard
  { name :: NonEmptyText
  , tags :: Maybe (NonEmpty Text)
  , flavor :: Maybe RichText
  , traits :: Maybe (NonEmpty Text)
  , passive :: Maybe Text
  , defense :: Maybe Int
  , resilience :: Maybe Int
  }
  deriving stock (Eq, Show, Generic)

$(deriveJSON cardpgJsonDef ''TalentCard)

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
data EncounterCard = EncounterCard
  { name :: NonEmptyText
  , tags :: Maybe (NonEmpty Text)
  , narrative :: RichText
  , options :: Maybe (NonEmpty Text)
  , mechanics :: Maybe EncounterMechanics
  }
  deriving stock (Eq, Show, Generic)

$(deriveJSON cardpgJsonDef ''EncounterCard)

-- | Represents Status Effects / Consequences.
data ConsequenceCard = ConsequenceCard
  { name :: NonEmptyText
  , tags :: Maybe (NonEmpty Text)
  , passive :: Maybe Text
  , effects :: Maybe (NonEmpty Text)
  , severity :: Int
  , notes :: Maybe Text
  , rules :: Maybe (NonEmpty Rule)
  }
  deriving stock (Eq, Show, Generic)

$(deriveJSON cardpgJsonDef ''ConsequenceCard)

-- | Represents the *Static Definition* or "Character Sheet" of an Actor.
-- | This is used for initialization and templates, not for running game state.
data ActorDefinition = ActorDefinition
  { name :: Text
  , tags :: Maybe (NonEmpty Text)
  , items :: [ItemCard]
  , nature :: [NatureCard]
  , deck :: [CoreCard]
  }
  deriving stock (Eq, Show, Generic)

$(deriveJSON cardpgJsonDef ''ActorDefinition)

-- | A wrapper for any type of authored card.
data CustomCard
  = CustomCore CoreCard
  | CustomItem ItemCard
  | CustomNature NatureCard
  | CustomTalent TalentCard
  | CustomEncounter EncounterCard
  | CustomConsequence ConsequenceCard
  deriving stock (Eq, Show, Generic)

$(deriveJSON cardpgJsonDef ''CustomCard)

customCardNameText :: CustomCard -> Text
customCardNameText (CustomCore c) = getRawText c.name
customCardNameText (CustomItem c) = getRawText c.name
customCardNameText (CustomNature c) = getRawText c.name
customCardNameText (CustomTalent c) = getRawText c.name
customCardNameText (CustomEncounter c) = getRawText c.name
customCardNameText (CustomConsequence c) = getRawText c.name

customCardCategoryText :: CustomCard -> Text
customCardCategoryText (CustomCore _) = "core"
customCardCategoryText (CustomItem _) = "items"
customCardCategoryText (CustomNature _) = "nature"
customCardCategoryText (CustomTalent _) = "talent"
customCardCategoryText (CustomEncounter _) = "encounters"
customCardCategoryText (CustomConsequence _) = "consequences"

customCardFingerprint :: CustomCard -> Text
customCardFingerprint card =
  let jsonStr = show (toJSON card)
      h = foldl (\acc c -> acc * 33 + ord c) 5381 jsonStr
   in T.pack (show (abs h))

customCardIdText :: CustomCard -> Text
customCardIdText card =
  let nameText = customCardNameText card
      categoryText = customCardCategoryText card
      slug =
        T.map (\c -> if c == ' ' then '-' else toLower c) $
          T.filter (\c -> isAlphaNum c || c == ' ') nameText
      fp = customCardFingerprint card
   in if T.null fp
        then categoryText <> "-" <> slug
        else categoryText <> "-" <> slug <> "-" <> fp
