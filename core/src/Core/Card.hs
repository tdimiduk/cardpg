{-# LANGUAGE LambdaCase #-}

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
  , RulesStatus (..)
  , MasterCard (..)
  , CardMilestone (..)
  , DeckEntry (..)
  , CardReference (..)
  , ActorDefinition (..)
  , ActorRawDefinition
  , actorDeckCards
  , resolveDeckEntry
  , resolveActorDeck
  , applyOverrides
  , masterCardToCoreCard
  , coreCardToMasterCard
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

import Data.Aeson
  ( FromJSON (..)
  , Options (..)
  , ToJSON (..)
  , Value (..)
  , genericParseJSON
  , genericToJSON
  , toJSON
  )
import Data.Aeson.KeyMap qualified as KM
import Data.Aeson.TH (deriveJSON)
import Data.Char (isAlphaNum, ord, toLower)
import Data.List.NonEmpty (NonEmpty)
import Data.Map.Strict (Map)
import Data.Map.Strict qualified as Map
import Data.Maybe (fromMaybe)
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

-- | Rules status indicating currency of the card's rules text.
data RulesStatus = RulesCurrent | RulesOutdated | RulesExperimental
  deriving stock (Eq, Show, Generic, Ord, Enum, Bounded)

$(deriveJSON (cardpgJsonOptions "Rules") ''RulesStatus)

-- | Represents milestone variants/upgrades of a card.
data CardMilestone = CardMilestone
  { stats :: Maybe (Stats (Maybe Int))
  , attack :: Maybe AttackDef
  , rules :: Maybe (NonEmpty Rule)
  , cost :: Maybe Int
  }
  deriving stock (Eq, Show, Generic)

$(deriveJSON cardpgJsonDef ''CardMilestone)

-- | Represents a canonical card definition in the database.
data MasterCard = MasterCard
  { id :: Text -- Flat unique ID/slug (e.g. "sunder-armor")
  , name :: NonEmptyText -- Display name (e.g. "Sunder Armor")
  , tags :: Maybe (NonEmpty Text)
  , stats :: Stats Int
  , cost :: Maybe Int
  , attack :: Maybe AttackDef
  , rules :: Maybe (NonEmpty Rule)
  , flavor :: Maybe RichText
  , rulesStatus :: Maybe RulesStatus
  , legacyNotes :: Maybe Text
  , milestones :: Maybe (Map Text CardMilestone)
  }
  deriving stock (Eq, Show, Generic)

masterCardJsonOptions :: Options
masterCardJsonOptions =
  cardpgJsonDef
    { fieldLabelModifier = \case
        "rulesStatus" -> "rules_status"
        "legacyNotes" -> "legacy_notes"
        f -> f
    }

instance ToJSON MasterCard where
  toJSON = genericToJSON masterCardJsonOptions

instance FromJSON MasterCard where
  parseJSON (Object o) =
    let o' = normalizeKey "rulesStatus" "rules_status" . normalizeKey "legacyNotes" "legacy_notes" $ o
     in genericParseJSON masterCardJsonOptions (Object o')
    where
      normalizeKey oldKey newKey km =
        case KM.lookup oldKey km of
          Just val | not (KM.member newKey km) -> KM.insert newKey val (KM.delete oldKey km)
          _ -> km
  parseJSON v = genericParseJSON masterCardJsonOptions v

-- | A card reference pointing to a master database entry with optional overrides.
data CardReference = CardReference
  { card :: Text -- e.g. "sunder-armor"
  , stats :: Maybe (Stats (Maybe Int)) -- optional stat overrides
  , upgrades :: Maybe (Stats (Maybe Int)) -- optional +1 deltas
  , milestone :: Maybe Text -- optional milestone key
  }
  deriving stock (Eq, Show, Generic)

$(deriveJSON cardpgJsonDef ''CardReference)

-- | An entry in an actor's deck list, either referencing a master card or inlining one directly.
data DeckEntry
  = EntryRef CardReference
  | EntryInline CoreCard
  deriving stock (Eq, Show, Generic)

instance ToJSON DeckEntry where
  toJSON (EntryRef ref) = toJSON ref
  toJSON (EntryInline c) = toJSON c

instance FromJSON DeckEntry where
  parseJSON v@(Object o)
    | KM.member "card" o = EntryRef <$> parseJSON v
    | otherwise = EntryInline <$> parseJSON v
  parseJSON v = EntryInline <$> parseJSON v

-- | Represents the *Static Definition* or "Character Sheet" of an Actor.
-- | This is used for initialization and templates, not for running game state.
data ActorDefinition = ActorDefinition
  { name :: Text
  , tags :: Maybe (NonEmpty Text)
  , items :: [ItemCard]
  , nature :: [NatureCard]
  , deck :: [DeckEntry]
  }
  deriving stock (Eq, Show, Generic)

type ActorRawDefinition = ActorDefinition

$(deriveJSON cardpgJsonDef ''ActorDefinition)

-- | Extract all inline CoreCards from an ActorDefinition.
actorDeckCards :: ActorDefinition -> [CoreCard]
actorDeckCards actor = [c | EntryInline c <- actor.deck]

-- | Resolve a single DeckEntry against a master card catalog.
resolveDeckEntry :: Map Text MasterCard -> DeckEntry -> Either String CoreCard
resolveDeckEntry _ (EntryInline c) = Right c
resolveDeckEntry catalog (EntryRef ref) = case Map.lookup ref.card catalog of
  Nothing -> Left $ "Unknown card ID in deck: " <> T.unpack ref.card
  Just master -> Right $ applyOverrides ref master

-- | Resolve all deck entries of an actor definition against a master catalog.
resolveActorDeck :: Map Text MasterCard -> ActorDefinition -> Either String [CoreCard]
resolveActorDeck catalog actor = traverse (resolveDeckEntry catalog) actor.deck

-- | Apply stat overrides, upgrade deltas, and milestone replacements to a master card.
applyOverrides :: CardReference -> MasterCard -> CoreCard
applyOverrides ref master =
  let mMilestone = do
        msKey <- ref.milestone
        msMap <- master.milestones
        Map.lookup msKey msMap

      baseStats = case mMilestone of
        Just ms | Just s <- ms.stats -> applyPartialStats s master.stats
        _ -> master.stats

      statsAfterRef = case ref.stats of
        Just s -> applyPartialStats s baseStats
        Nothing -> baseStats

      finalStats = case ref.upgrades of
        Just u -> applyDeltas u statsAfterRef
        Nothing -> statsAfterRef

      finalCost = case mMilestone of
        Just ms | Just c <- ms.cost -> Just c
        _ -> master.cost

      finalAttack = case mMilestone of
        Just ms | Just a <- ms.attack -> Just a
        _ -> master.attack

      finalRules = case mMilestone of
        Just ms | Just r <- ms.rules -> Just r
        _ -> master.rules
   in CoreCard
        { name = master.name
        , tags = master.tags
        , stats = finalStats
        , cost = finalCost
        , attack = finalAttack
        , rules = finalRules
        , flavor = master.flavor
        }

applyPartialStats :: Stats (Maybe Int) -> Stats Int -> Stats Int
applyPartialStats overrides base =
  Stats
    { red = fromMaybe base.red overrides.red
    , yellow = fromMaybe base.yellow overrides.yellow
    , blue = fromMaybe base.blue overrides.blue
    }

applyDeltas :: Stats (Maybe Int) -> Stats Int -> Stats Int
applyDeltas deltas base =
  Stats
    { red = base.red + fromMaybe 0 deltas.red
    , yellow = base.yellow + fromMaybe 0 deltas.yellow
    , blue = base.blue + fromMaybe 0 deltas.blue
    }

-- | Convert a MasterCard to a CoreCard with default values.
masterCardToCoreCard :: MasterCard -> CoreCard
masterCardToCoreCard m =
  CoreCard
    { name = m.name
    , tags = m.tags
    , stats = m.stats
    , cost = m.cost
    , attack = m.attack
    , rules = m.rules
    , flavor = m.flavor
    }

-- | Convert a CoreCard to a canonical MasterCard.
coreCardToMasterCard :: Text -> CoreCard -> MasterCard
coreCardToMasterCard cardId c =
  MasterCard
    { id = cardId
    , name = c.name
    , tags = c.tags
    , stats = c.stats
    , cost = c.cost
    , attack = c.attack
    , rules = c.rules
    , flavor = c.flavor
    , rulesStatus = Just RulesCurrent
    , legacyNotes = Nothing
    , milestones = Nothing
    }

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
