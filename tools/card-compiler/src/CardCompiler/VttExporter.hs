{-# LANGUAGE DeriveGeneric #-}
{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE RecordWildCards #-}
{-# LANGUAGE DuplicateRecordFields #-}
{-# LANGUAGE ScopedTypeVariables #-}

module CardCompiler.VttExporter where

import Data.Aeson (ToJSON(..), genericToJSON, Value(..), object, (.=))
import qualified Data.Aeson as Aeson
import Data.Text (Text)
import qualified Data.Text as T
import qualified Data.ByteString.Lazy as LBS
import GHC.Generics (Generic)
import Data.Maybe (fromMaybe)
import Control.Monad (foldM)
import qualified Data.Yaml as Yaml
import Data.List.NonEmpty (NonEmpty)
import qualified Data.List.NonEmpty as NE
import qualified Data.Map as Map
import Data.List (mapAccumL)

import CardPG.Core.Card (CoreCard(..), ItemCard(..), Rule(..), Stats(..), Actor(..))
import CardPG.Core.Json (cardpgJsonOptions)
import CardPG.Core.RuleDefs (AttackDef(..), GeneralDef(..), TaskDef(..), TriggerDef(..), StanceDef(..), ChannelDef(..), PrimeDef(..), PassiveDef(..))
import CardPG.Core.NonEmptyText (getNonEmptyText)
import CardPG.Core.RichText (unRichString, RichString)

-- | Wrapper to force Array JSON output for RichString
newtype VttRichString = VttRichString RichString
  deriving (Show)

instance ToJSON VttRichString where
  toJSON (VttRichString rs) = toJSON (CardPG.Core.RichText.unRichString rs)

-- | Shadow Type for Rules to force structured JSON and VttRichString
newtype StructuredRule = StructuredRule { unStructuredRule :: Rule }
  deriving (Show, Generic)

instance ToJSON StructuredRule where
  toJSON (StructuredRule r) = case r of
    RuleAttack (AttackDef p res eff) -> object
      [ "type" .= ("attack" :: Text)
      , "data" .= object (filter (\(_, v) -> v /= Null)
          [ "power" .= p
          , "resistedBy" .= res
          , "effect" .= fmap VttRichString eff
          ])
      ]
    RuleGeneral (GeneralDef n c p eff) -> object
      [ "type" .= ("general" :: Text)
      , "data" .= object (filter (\(_, v) -> v /= Null)
          [ "name" .= n
          , "cost" .= fmap VttRichString c
          , "power" .= p
          , "effect" .= VttRichString eff
          ])
      ]
    RuleStance (StanceDef d eff) -> object
      [ "type" .= ("stance" :: Text)
      , "data" .= object (filter (\(_, v) -> v /= Null)
          [ "duration" .= d
          , "effect" .= VttRichString eff
          ])
      ]
    RuleChannel (ChannelDef d eff) -> object
      [ "type" .= ("channel" :: Text)
      , "data" .= object (filter (\(_, v) -> v /= Null)
          [ "duration" .= d
          , "effect" .= VttRichString eff
          ])
      ]
    RulePrime (PrimeDef t reac) -> object
      [ "type" .= ("prime" :: Text)
      , "data" .= object (filter (\(_, v) -> v /= Null)
          [ "trigger" .= t
          , "reaction" .= StructuredRule reac
          ])
      ]
    RuleNarrative rs -> object
      [ "type" .= ("narrative" :: Text)
      , "data" .= VttRichString rs
      ]
    RulePassive (PassiveDef b c) -> object
      [ "type" .= ("passive" :: Text)
      , "data" .= object (filter (\(_, v) -> v /= Null)
          [ "bonus" .= b
          , "condition" .= c
          ])
      ]
    RuleTask (TaskDef n ch t c eff) -> object
      [ "type" .= ("task" :: Text)
      , "data" .= object (filter (\(_, v) -> v /= Null)
          [ "name" .= n
          , "check" .= ch
          , "time" .= fmap VttRichString t
          , "cost" .= fmap VttRichString c
          , "effect" .= VttRichString eff
          ])
      ]
    RuleTrigger (TriggerDef t eff) -> object
      [ "type" .= ("trigger" :: Text)
      , "data" .= object (filter (\(_, v) -> v /= Null)
          [ "trigger" .= t
          , "effect" .= VttRichString eff
          ])
      ]

-- | Shadow Type for CoreCard to use StructuredRule
data VttCoreCard = VttCoreCard
  { _id     :: Maybe Text
  , _name   :: Text
  , _tags   :: Maybe (NonEmpty Text)
  , _stats  :: Stats
  , _cost   :: Maybe Int
  , _rules  :: Maybe (NonEmpty StructuredRule)
  , _flavor :: Maybe VttRichString
  }
  deriving (Show, Generic)

instance ToJSON VttCoreCard where
  toJSON VttCoreCard{..} = object $ filter (\(_, v) -> v /= Null)
    [ "type" .= ("coreCard" :: Text)
    , "id" .= _id
    , "name" .= _name
    , "tags" .= _tags
    , "stats" .= _stats
    , "cost" .= _cost
    , "rules" .= _rules
    , "flavor" .= _flavor
    ]

-- | VTT Actor Type
data VttActor = VttActor
  { _id    :: Text
  , _name  :: Text
  , _tags  :: [Text]
  , _items :: [ItemCard]
  , _deck  :: [VttCoreCard]
  }
  deriving (Show, Generic)

instance ToJSON VttActor where
  toJSON = genericToJSON (cardpgJsonOptions "Actor")

-- | VTT Export Data
data VttExport = VttExport
  { _actors   :: [VttActor]
  , _statuses :: [VttCoreCard]
  }
  deriving (Show, Generic)

instance ToJSON VttExport where
  toJSON = genericToJSON (cardpgJsonOptions "VttExport")

-- | Load and Export Function
loadAndExport :: [FilePath] -> FilePath -> IO ()
loadAndExport inputFiles outputFile = do
  (actors, statuses) <- foldM processFile ([], []) inputFiles

  let exportData = VttExport
        { _actors = actors
        , _statuses = statuses
        }

  LBS.writeFile outputFile (Aeson.encode exportData)
  putStrLn $ "Exported " ++ show (length actors) ++ " actors and " ++ show (length statuses) ++ " status cards to " ++ outputFile

  where
    processFile :: ([VttActor], [VttCoreCard]) -> FilePath -> IO ([VttActor], [VttCoreCard])
    processFile (accActors, accStatuses) file = do
      result <- Yaml.decodeFileEither file
      case result of
        Right (actor :: Actor) -> do
          return (convertActor actor : accActors, accStatuses)
        Left _ -> do
          -- Try parsing as list of CoreCards (Status Library)
          resultCards <- Yaml.decodeFileEither file
          case resultCards of
            Right (cards :: [CoreCard]) -> do
               -- For status cards, we don't need the complex ID logic of decks yet, 
               -- or maybe we do? Let's assume simple ID assignment for now or use existing IDs.
               -- The `processDeck` logic is useful for deduplication and ID assignment.
               -- Let's treat the file name or a generic "status" as the "actorId" for ID generation purposes if needed,
               -- but CoreCards usually have IDs.
               let vttCards = map (\c@CoreCard{_name=n, _id=i} -> toVttCoreCard c (fromMaybe (slugify (getNonEmptyText n)) i)) cards
               return (accActors, vttCards ++ accStatuses)
            Left err -> do
               putStrLn $ "Warning: Failed to parse " ++ file ++ " as Actor or Card List: " ++ show err
               return (accActors, accStatuses)

-- | Convert Actor to VttActor
convertActor :: Actor -> VttActor
convertActor Actor{..} = 
  let actorId = slugify _name
  in VttActor
  { _id = actorId
  , _name = _name
  , _tags = maybe [] NE.toList _tags
  , _items = map ensureItemId _items
  , _deck = processDeck actorId _deck
  }

-- | Process deck to ensure unique IDs for duplicates
processDeck :: Text -> [CoreCard] -> [VttCoreCard]
processDeck actorId cards =
  let
    -- 1. Calculate frequencies of card slugs (names)
    -- Use pattern matching to disambiguate _name
    getNameSlug CoreCard{_name=n} = slugify (getNonEmptyText n)
    cardSlugs = map getNameSlug cards
    freqMap = Map.fromListWith (+) $ zip cardSlugs (repeat 1 :: [Int])

    -- 2. Map over cards with state (counter map)
    (_, vttCards) = mapAccumL (assignId actorId freqMap) Map.empty cards
  in
    vttCards

-- | Assign ID based on frequency and current count
assignId :: Text -> Map.Map Text Int -> Map.Map Text Int -> CoreCard -> (Map.Map Text Int, VttCoreCard)
assignId actorId freqMap counters card@CoreCard{_name=n} =
  let
    cardSlug = slugify (getNonEmptyText n)
    count = Map.findWithDefault 0 cardSlug counters
    total = Map.findWithDefault 0 cardSlug freqMap

    -- Determine new ID: {actorId}-{cardSlug} or {actorId}-{cardSlug}_{count}
    baseId = actorId <> "-" <> cardSlug
    finalId = if total > 1
              then baseId <> "_" <> T.pack (show count)
              else baseId

    -- Update counter
    newCounters = Map.insert cardSlug (count + 1) counters
    
    -- Create VttCoreCard
    vttCard = toVttCoreCard card finalId
  in
    (newCounters, vttCard)

-- | Convert CoreCard to VttCoreCard with specific ID
toVttCoreCard :: CoreCard -> Text -> VttCoreCard
toVttCoreCard CoreCard{..} finalId = VttCoreCard
  { _id = Just finalId
  , _name = getNonEmptyText _name
  , _tags = _tags
  , _stats = _stats
  , _cost = _cost
  , _rules = fmap (fmap StructuredRule) _rules
  , _flavor = fmap VttRichString _flavor
  }

-- | Helper to ensure ItemCard has an ID
ensureItemId :: ItemCard -> ItemCard
ensureItemId item@ItemCard{..} = item { _id = Just $ fromMaybe (slugify (getNonEmptyText _name)) _id }

-- | Simple slugify
slugify :: Text -> Text
slugify = T.toLower . T.replace " " "-"
