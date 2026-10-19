{-# LANGUAGE DataKinds #-}
{-# LANGUAGE LambdaCase #-}

module Core.Card
  ( module Core.Rules
  , module Core.Keyword
  , Stats (..)
  , DefenseProfile (..)
  , emptyDefenseProfile
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
  , emptyItemCard
  , emptyCoreCard
  , withCost
  ) where

import Control.Applicative ((<|>))
import Data.Aeson
  ( FromJSON (..)
  , ToJSON (..)
  , Value (..)
  , withObject
  , (.:)
  , (.:?)
  )
import Data.Aeson.KeyMap qualified as KM
import Data.Aeson.TH (deriveJSON)
import Data.Char (isAlphaNum, ord, toLower)
import Data.List (nub)
import Data.List.NonEmpty (NonEmpty)
import Data.List.NonEmpty qualified as NE
import Data.Map.Strict (Map)
import Data.Map.Strict qualified as Map
import Data.Maybe (catMaybes, fromMaybe)
import Data.Text (Text)
import Data.Text qualified as T
import GHC.Generics (Generic)
import GHC.Records qualified

import Core.Json
import Core.Keyword
import Core.NonEmptyText (NonEmptyText, getRawText)
import Core.Primitives (CardInstanceId, Identified (..))
import Core.RichText (RichText)
import Core.Rules

import Core.Stats (ResourceType (..), Stats (..))

type CardInstance a = Identified CardInstanceId a

data DefenseProfile = DefenseProfile
  { defense :: Maybe Int
  , resilience :: Maybe Int
  , burden :: Maybe Int
  }
  deriving stock (Eq, Show, Generic)

$(deriveJSON cardpgJsonDef ''DefenseProfile)

emptyDefenseProfile :: DefenseProfile
emptyDefenseProfile = DefenseProfile Nothing Nothing Nothing

mergeTags :: Maybe (NonEmpty Keyword) -> Maybe (NonEmpty Keyword) -> Maybe (NonEmpty Keyword)
mergeTags Nothing Nothing = Nothing
mergeTags (Just ts) Nothing = Just ts
mergeTags Nothing (Just trs) = Just trs
mergeTags (Just ts) (Just trs) =
  let combined = NE.toList ts ++ NE.toList trs
      deduped = nub combined
   in NE.nonEmpty deduped

data CoreCard = CoreCard
  { name :: NonEmptyText
  , tags :: Maybe (NonEmpty Keyword)
  , stats :: Stats Int
  , cost :: Maybe Int
  -- ^ Play Cost (Additional cards required from hand to form an Action Stack; total stack is Cost + 1).
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
  , tags :: Maybe (NonEmpty Keyword)
  , defenses :: DefenseProfile
  , portions :: Maybe Int
  , passive :: Maybe Text
  , rules :: Maybe (NonEmpty Rule)
  , flavor :: Maybe RichText
  }
  deriving stock (Eq, Show, Generic)

instance ToJSON ItemCard where
  toJSON item =
    let defObj = case toJSON item.defenses of
          Object o -> o
          _ -> KM.empty
        base =
          KM.fromList $
            catMaybes
              [ Just ("name", toJSON item.name)
              , ("tags",) . toJSON <$> item.tags
              , ("portions",) . toJSON <$> item.portions
              , ("passive",) . toJSON <$> item.passive
              , ("rules",) . toJSON <$> item.rules
              , ("flavor",) . toJSON <$> item.flavor
              ]
     in Object (KM.union base defObj)

instance FromJSON ItemCard where
  parseJSON = withObject "ItemCard" $ \o -> do
    name <- o .: "name"
    mTags <- o .:? "tags"
    mTraits <- o .:? "traits"
    let tags = mergeTags mTags mTraits
    defenses <- parseJSON (Object o)
    portions <- o .:? "portions"
    passive <- o .:? "passive"
    rules <- o .:? "rules"
    flavor <- o .:? "flavor"
    pure $ ItemCard name tags defenses portions passive rules flavor

emptyItemCard :: NonEmptyText -> ItemCard
emptyItemCard n =
  ItemCard
    { name = n
    , tags = Nothing
    , defenses = emptyDefenseProfile
    , portions = Nothing
    , passive = Nothing
    , rules = Nothing
    , flavor = Nothing
    }

emptyCoreCard :: NonEmptyText -> Stats Int -> CoreCard
emptyCoreCard n s =
  CoreCard
    { name = n
    , tags = Nothing
    , stats = s
    , cost = Nothing
    , attack = Nothing
    , rules = Nothing
    , flavor = Nothing
    }

withCost :: Int -> CoreCard -> CoreCard
withCost c card = card{cost = Just c}

-- | Represents Innate Characteristics (Species, Natural Resilience).
data NatureCard = NatureCard
  { name :: NonEmptyText
  , tags :: Maybe (NonEmpty Keyword)
  , defenses :: DefenseProfile
  , passive :: Maybe Text
  , flavor :: Maybe RichText
  }
  deriving stock (Eq, Show, Generic)

instance ToJSON NatureCard where
  toJSON nature =
    let defObj = case toJSON nature.defenses of
          Object o -> o
          _ -> KM.empty
        base =
          KM.fromList $
            catMaybes
              [ Just ("name", toJSON nature.name)
              , ("tags",) . toJSON <$> nature.tags
              , ("passive",) . toJSON <$> nature.passive
              , ("flavor",) . toJSON <$> nature.flavor
              ]
     in Object (KM.union base defObj)

instance FromJSON NatureCard where
  parseJSON = withObject "NatureCard" $ \o -> do
    name <- o .: "name"
    mTags <- o .:? "tags"
    mTraits <- o .:? "traits"
    let tags = mergeTags mTags mTraits
    defenses <- parseJSON (Object o)
    passive <- o .:? "passive"
    flavor <- o .:? "flavor"
    pure $ NatureCard name tags defenses passive flavor

-- | Represents Learned Skills/Training (Proficiencies, Feats).
data TalentCard = TalentCard
  { name :: NonEmptyText
  , tags :: Maybe (NonEmpty Keyword)
  , defenses :: DefenseProfile
  , passive :: Maybe Text
  , flavor :: Maybe RichText
  }
  deriving stock (Eq, Show, Generic)

instance ToJSON TalentCard where
  toJSON talent =
    let defObj = case toJSON talent.defenses of
          Object o -> o
          _ -> KM.empty
        base =
          KM.fromList $
            catMaybes
              [ Just ("name", toJSON talent.name)
              , ("tags",) . toJSON <$> talent.tags
              , ("passive",) . toJSON <$> talent.passive
              , ("flavor",) . toJSON <$> talent.flavor
              ]
     in Object (KM.union base defObj)

instance FromJSON TalentCard where
  parseJSON = withObject "TalentCard" $ \o -> do
    name <- o .: "name"
    mTags <- o .:? "tags"
    mTraits <- o .:? "traits"
    let tags = mergeTags mTags mTraits
    defenses <- parseJSON (Object o)
    passive <- o .:? "passive"
    flavor <- o .:? "flavor"
    pure $ TalentCard name tags defenses passive flavor

instance GHC.Records.HasField "defense" ItemCard (Maybe Int) where
  getField (ItemCard _ _ d _ _ _ _) = d.defense

instance GHC.Records.HasField "resilience" ItemCard (Maybe Int) where
  getField (ItemCard _ _ d _ _ _ _) = d.resilience

instance GHC.Records.HasField "burden" ItemCard (Maybe Int) where
  getField (ItemCard _ _ d _ _ _ _) = d.burden

instance GHC.Records.HasField "defense" NatureCard (Maybe Int) where
  getField (NatureCard _ _ d _ _) = d.defense

instance GHC.Records.HasField "resilience" NatureCard (Maybe Int) where
  getField (NatureCard _ _ d _ _) = d.resilience

instance GHC.Records.HasField "burden" NatureCard (Maybe Int) where
  getField (NatureCard _ _ d _ _) = d.burden

instance GHC.Records.HasField "defense" TalentCard (Maybe Int) where
  getField (TalentCard _ _ d _ _) = d.defense

instance GHC.Records.HasField "resilience" TalentCard (Maybe Int) where
  getField (TalentCard _ _ d _ _) = d.resilience

instance GHC.Records.HasField "burden" TalentCard (Maybe Int) where
  getField (TalentCard _ _ d _ _) = d.burden

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
  , tags :: Maybe (NonEmpty Keyword)
  , narrative :: RichText
  , options :: Maybe (NonEmpty Text)
  , mechanics :: Maybe EncounterMechanics
  }
  deriving stock (Eq, Show, Generic)

$(deriveJSON cardpgJsonDef ''EncounterCard)

-- | Represents Status Effects / Consequences.
data ConsequenceCard = ConsequenceCard
  { name :: NonEmptyText
  , tags :: Maybe (NonEmpty Keyword)
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
  { id :: Text
  , card :: CoreCard
  , rulesStatus :: Maybe RulesStatus
  , legacyNotes :: Maybe Text
  , milestones :: Maybe (Map Text CardMilestone)
  }
  deriving stock (Eq, Show, Generic)

instance ToJSON MasterCard where
  toJSON mc =
    let cardObj = case toJSON mc.card of
          Object o -> o
          _ -> KM.empty
        masterFields =
          KM.fromList $
            catMaybes
              [ Just ("id", toJSON mc.id)
              , ("rules_status",) . toJSON <$> mc.rulesStatus
              , ("legacy_notes",) . toJSON <$> mc.legacyNotes
              , ("milestones",) . toJSON <$> mc.milestones
              ]
     in Object (KM.union masterFields cardObj)

instance FromJSON MasterCard where
  parseJSON = withObject "MasterCard" $ \o -> do
    cardId <- o .: "id"
    card <- parseJSON (Object o)
    mRulesStatus <- o .:? "rules_status" <|> o .:? "rulesStatus"
    mLegacyNotes <- o .:? "legacy_notes" <|> o .:? "legacyNotes"
    mMilestones <- o .:? "milestones"
    pure $ MasterCard cardId card mRulesStatus mLegacyNotes mMilestones

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
  , tags :: Maybe (NonEmpty Keyword)
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
        Just ms | Just s <- ms.stats -> applyPartialStats s master.card.stats
        _ -> master.card.stats

      statsAfterRef = case ref.stats of
        Just s -> applyPartialStats s baseStats
        Nothing -> baseStats

      finalStats = case ref.upgrades of
        Just u -> applyDeltas u statsAfterRef
        Nothing -> statsAfterRef

      finalCost = case mMilestone of
        Just ms | Just c <- ms.cost -> Just c
        _ -> master.card.cost

      finalAttack = case mMilestone of
        Just ms | Just a <- ms.attack -> Just a
        _ -> master.card.attack

      finalRules = case mMilestone of
        Just ms | Just r <- ms.rules -> Just r
        _ -> master.card.rules
   in CoreCard
        { name = master.card.name
        , tags = master.card.tags
        , stats = finalStats
        , cost = finalCost
        , attack = finalAttack
        , rules = finalRules
        , flavor = master.card.flavor
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
masterCardToCoreCard m = m.card

-- | Convert a CoreCard to a canonical MasterCard.
coreCardToMasterCard :: Text -> CoreCard -> MasterCard
coreCardToMasterCard cardId c =
  MasterCard
    { id = cardId
    , card = c
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
