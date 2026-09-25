{-# LANGUAGE DuplicateRecordFields #-}
{-# LANGUAGE OverloadedRecordDot #-}
{-# LANGUAGE OverloadedStrings #-}

module Design.Types
  ( Track (..)
  , parseTrack
  , trackToText
  , validTracks
  , ConfidenceTier (..)
  , parseConfidence
  , confidenceToText
  , validConfidenceTiers
  , VettedByHuman (..)
  , EpistemicStatus (..)
  , Frontmatter (..)
  , IndexItem (..)
  , docTypeCompatibility
  , docTypeCanonicalTag
  , frontmatterRequiredDirs
  ) where

import Data.Aeson
import Data.Aeson.Key qualified as Key
import Data.Aeson.KeyMap qualified as KM
import Data.Map.Strict (Map)
import Data.Map.Strict qualified as Map
import Data.Set (Set)
import Data.Set qualified as Set
import Data.Text (Text)
import Data.Text qualified as T
import GHC.Generics (Generic)

-- | Epistemic tracks
data Track
  = Verisimilitude
  | Ludology
  deriving stock (Show, Eq, Ord, Enum, Bounded, Generic)

trackToText :: Track -> Text
trackToText Verisimilitude = "verisimilitude"
trackToText Ludology = "ludology"

parseTrack :: Text -> Either String Track
parseTrack "verisimilitude" = Right Verisimilitude
parseTrack "ludology" = Right Ludology
parseTrack other =
  Left $
    "Invalid 'track': '" ++ T.unpack other ++ "' (must be one of: [\"ludology\", \"verisimilitude\"])"

validTracks :: Set Text
validTracks = Set.fromList ["ludology", "verisimilitude"]

instance ToJSON Track where
  toJSON = String . trackToText

instance FromJSON Track where
  parseJSON = withText "Track" $ \t ->
    case parseTrack t of
      Left err -> fail err
      Right trk -> pure trk

-- | Epistemic confidence tiers
data ConfidenceTier
  = Speculative
  | MediumLow
  | Medium
  | High
  deriving stock (Show, Eq, Ord, Enum, Bounded, Generic)

confidenceToText :: ConfidenceTier -> Text
confidenceToText Speculative = "speculative"
confidenceToText MediumLow = "medium-low"
confidenceToText Medium = "medium"
confidenceToText High = "high"

parseConfidence :: Text -> Either String ConfidenceTier
parseConfidence "speculative" = Right Speculative
parseConfidence "medium-low" = Right MediumLow
parseConfidence "medium" = Right Medium
parseConfidence "high" = Right High
parseConfidence other =
  Left $
    "Invalid 'confidence': '"
      ++ T.unpack other
      ++ "' (must be one of: [\"high\", \"medium\", \"medium-low\", \"speculative\"])"

validConfidenceTiers :: Set Text
validConfidenceTiers = Set.fromList ["high", "medium", "medium-low", "speculative"]

instance ToJSON ConfidenceTier where
  toJSON = String . confidenceToText

instance FromJSON ConfidenceTier where
  parseJSON = withText "ConfidenceTier" $ \t ->
    case parseConfidence t of
      Left err -> fail err
      Right c -> pure c

-- | Vetted by human status: boolean or string identifier
data VettedByHuman
  = VettedBool Bool
  | VettedBy Text
  deriving stock (Show, Eq, Ord, Generic)

instance ToJSON VettedByHuman where
  toJSON (VettedBool b) = Bool b
  toJSON (VettedBy txt) = String txt

instance FromJSON VettedByHuman where
  parseJSON (Bool b) = pure (VettedBool b)
  parseJSON (String s)
    | not (T.null (T.strip s)) = pure (VettedBy (T.strip s))
    | otherwise = fail "'vetted_by_human' cannot be empty"
  parseJSON _ = fail "'vetted_by_human' must be a boolean or non-empty string identifier"

-- | Epistemic status object
data EpistemicStatus = EpistemicStatus
  { confidence :: ConfidenceTier
  , vettedByHuman :: VettedByHuman
  }
  deriving stock (Show, Eq, Generic)

instance ToJSON EpistemicStatus where
  toJSON es =
    object
      [ "confidence" .= es.confidence
      , "vetted_by_human" .= es.vettedByHuman
      ]

instance FromJSON EpistemicStatus where
  parseJSON = withObject "EpistemicStatus" $ \o -> do
    c <- o .: "confidence"
    v <- o .: "vetted_by_human"
    pure $ EpistemicStatus c v

-- | Frontmatter representation
data Frontmatter = Frontmatter
  { title :: Text
  , docType :: Text
  , track :: Maybe Track
  , origin :: Maybe Text
  , epistemicStatus :: Maybe EpistemicStatus
  , relatedFiles :: Maybe [FilePath]
  , purpose :: Maybe Text
  , description :: Maybe Text
  , tags :: [Text]
  , hasObsoleteStatus :: Bool
  , rawMap :: Map Text Value
  }
  deriving stock (Show, Eq, Generic)

instance ToJSON Frontmatter where
  toJSON fm =
    let base =
          [ "title" .= fm.title
          , "doc_type" .= fm.docType
          ]
            ++ maybe [] (\t -> ["track" .= t]) fm.track
            ++ maybe [] (\o -> ["origin" .= o]) fm.origin
            ++ maybe [] (\es -> ["epistemic_status" .= es]) fm.epistemicStatus
            ++ maybe [] (\rf -> ["related_files" .= rf]) fm.relatedFiles
            ++ maybe [] (\p -> ["purpose" .= p]) fm.purpose
            ++ maybe [] (\d -> ["description" .= d]) fm.description
            ++ ["tags" .= fm.tags | not (null fm.tags)]
     in object base

-- | Directory items in index.yaml
data IndexItem = IndexItem
  { path :: Maybe FilePath
  , name :: Maybe Text
  , purpose :: Maybe Text
  , tags :: [Text]
  , sourceType :: Maybe Text
  , itemType :: Maybe Text
  , aggregatedTags :: Maybe [Text]
  , components :: Maybe (Map Text FilePath)
  , sheets :: Maybe [Value]
  , rawFields :: Map Text Value
  }
  deriving stock (Show, Eq, Generic)

instance ToJSON IndexItem where
  toJSON item =
    let orderedKeys =
          maybe [] (\n -> [("name", toJSON n)]) item.name
            ++ maybe [] (\p -> [("path", toJSON p)]) item.path
            ++ maybe [] (\st -> [("source_type", toJSON st) | st /= "local_file"]) item.sourceType
            ++ maybe [] (\t -> [("type", toJSON t)]) item.itemType
            ++ maybe [] (\pur -> [("purpose", toJSON pur)]) item.purpose
            ++ [("tags", toJSON item.tags) | not (null item.tags)]
            ++ maybe [] (\at -> [("aggregated_tags", toJSON at)]) item.aggregatedTags
            ++ maybe [] (\c -> [("components", toJSON c)]) item.components
            ++ maybe [] (\s -> [("sheets", toJSON s)]) item.sheets
        extraKeys =
          [ (k, v)
          | (k, v) <- Map.toList item.rawFields
          , k
              `notElem` [ "name"
                        , "path"
                        , "source_type"
                        , "type"
                        , "purpose"
                        , "tags"
                        , "aggregated_tags"
                        , "components"
                        , "sheets"
                        ]
          ]
     in object [Key.fromText k .= v | (k, v) <- orderedKeys ++ extraKeys]

instance FromJSON IndexItem where
  parseJSON = withObject "IndexItem" $ \o -> do
    mPath <- o .:? "path"
    mName <- o .:? "name"
    mPurpose <- o .:? "purpose"
    tagsList <- o .:? "tags" .!= []
    mSourceType <- o .:? "source_type"
    mItemType <- o .:? "type"
    mAggregatedTags <- o .:? "aggregated_tags"
    mComponents <- o .:? "components"
    mSheets <- o .:? "sheets"
    let raw = Map.fromList [(Key.toText k, v) | (k, v) <- KM.toList o]
    pure
      IndexItem
        { path = mPath
        , name = mName
        , purpose = mPurpose
        , tags = tagsList
        , sourceType = mSourceType
        , itemType = mItemType
        , aggregatedTags = mAggregatedTags
        , components = mComponents
        , sheets = mSheets
        , rawFields = raw
        }

-- | Tag compatibility map between frontmatter doc_type and index entry tags
docTypeCompatibility :: Text -> Set Text
docTypeCompatibility dt =
  case T.toLower (T.strip dt) of
    "synthesis" ->
      Set.fromList
        ["research synthesis", "synthesis", "doc-type:research-synthesis", "doc-type:synthesis"]
    "literature-note" ->
      Set.fromList ["literature note", "literature-note", "doc-type:literature-note"]
    "report" ->
      Set.fromList ["research report", "report", "doc-type:research-report", "doc-type:report"]
    "card-database" ->
      Set.fromList ["card database", "cards", "doc-type:card-database", "doc-type:content-library"]
    "meta" ->
      Set.fromList ["meta document", "doc-type:meta"]
    "introductory-text" ->
      Set.fromList ["introductory text", "doc-type:introductory-text"]
    "rules" ->
      Set.fromList
        [ "game rules"
        , "game rules module"
        , "rules"
        , "module"
        , "doc-type:rules"
        , "doc-type:rules-framework"
        , "doc-type:rules-module"
        , "doc-type:module"
        ]
    "module" ->
      Set.fromList
        [ "game rules module"
        , "module"
        , "rules"
        , "doc-type:module"
        , "doc-type:rules-module"
        , "doc-type:rules"
        ]
    "iteration" ->
      Set.fromList
        [ "design constraints"
        , "design exploration"
        , "design exploration suite"
        , "ideation"
        , "doc-type:iteration"
        , "doc-type:ideation"
        ]
    other -> Set.singleton other

-- | Canonical tags for doc_type
docTypeCanonicalTag :: Text -> Text
docTypeCanonicalTag dt =
  case T.toLower (T.strip dt) of
    "synthesis" -> "doc-type:research-synthesis"
    "literature-note" -> "doc-type:literature-note"
    "report" -> "doc-type:research-report"
    "rules" -> "doc-type:rules"
    "module" -> "doc-type:module"
    "iteration" -> "doc-type:iteration"
    "ideation" -> "doc-type:ideation"
    "meta" -> "doc-type:meta"
    "introductory-text" -> "doc-type:introductory-text"
    other -> "doc-type:" <> other

frontmatterRequiredDirs :: [FilePath]
frontmatterRequiredDirs =
  [ "research/synthesis"
  , "research/theory/readings"
  ]
