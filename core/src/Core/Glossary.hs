{-# LANGUAGE DeriveAnyClass #-}
{-# LANGUAGE DerivingStrategies #-}
{-# LANGUAGE DuplicateRecordFields #-}
{-# LANGUAGE OverloadedRecordDot #-}
{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE NoFieldSelectors #-}

module Core.Glossary
  ( GlossaryEntry (..)
  , Glossary (..)
  , mkGlossary
  , fromList
  , fromMap
  , toMap
  , lookupGlossary
  , canonicalSlug
  , toSlug
  , allEntries
  ) where

import Data.Aeson (FromJSON (..), ToJSON (..))
import Data.Char (isAlphaNum)
import Data.Map.Strict (Map)
import Data.Map.Strict qualified as Map
import Data.Text (Text)
import Data.Text qualified as T
import GHC.Generics (Generic)

-- | A single entry in the game rules keyword glossary.
data GlossaryEntry = GlossaryEntry
  { canonical :: Text
  , aliases :: [Text]
  , slug :: Text
  , category :: Text
  , summary :: Text
  , theme :: Maybe Text
  }
  deriving stock (Show, Eq, Generic)
  deriving anyclass (FromJSON, ToJSON)

-- | The complete keyword glossary, storing entries indexed by slug,
-- with a secondary reverse-index for looking up entries by canonical name,
-- alias, or slug (case-insensitively).
data Glossary = Glossary
  { entries :: Map Text GlossaryEntry
  , termIndex :: Map Text Text
  }
  deriving stock (Show, Eq, Generic)

-- | JSON serialization emits a flat object keyed by slug, matching export/glossary.json.
instance ToJSON Glossary where
  toJSON g = toJSON g.entries
  toEncoding g = toEncoding g.entries

-- | JSON deserialization parses the map of slug -> GlossaryEntry and builds the lookup index.
instance FromJSON Glossary where
  parseJSON v = do
    entryMap <- parseJSON v
    pure $ mkGlossary entryMap

-- | Construct a 'Glossary' from a map of slug to 'GlossaryEntry'.
mkGlossary :: Map Text GlossaryEntry -> Glossary
mkGlossary m =
  Glossary
    { entries = m
    , termIndex = buildIndex m
    }

-- | Build a case-insensitive index mapping canonical names, aliases, and slugs to their entry's slug.
buildIndex :: Map Text GlossaryEntry -> Map Text Text
buildIndex m =
  Map.fromList
    [ (normalizeKey key, entry.slug)
    | entry <- Map.elems m
    , key <- entry.slug : entry.canonical : entry.aliases
    ]

normalizeKey :: Text -> Text
normalizeKey = T.toLower . T.strip

-- | Construct a 'Glossary' from a list of entries.
fromList :: [GlossaryEntry] -> Glossary
fromList entriesList =
  mkGlossary $ Map.fromList [(e.slug, e) | e <- entriesList]

-- | Synonym for 'mkGlossary'.
fromMap :: Map Text GlossaryEntry -> Glossary
fromMap = mkGlossary

-- | Extract the underlying map of slug -> 'GlossaryEntry'.
toMap :: Glossary -> Map Text GlossaryEntry
toMap g = g.entries

-- | Return all entries in the glossary.
allEntries :: Glossary -> [GlossaryEntry]
allEntries g = Map.elems g.entries

-- | Lookup an entry by canonical name, alias, or slug (case-insensitive).
lookupGlossary :: Text -> Glossary -> Maybe GlossaryEntry
lookupGlossary term g = do
  slug' <- Map.lookup (normalizeKey term) g.termIndex
  Map.lookup slug' g.entries

-- | Return the canonical slug for a term or alias.
-- If the term is recognized in the glossary, returns its canonical slug.
-- Otherwise, returns the slugified version of the given term.
canonicalSlug :: Text -> Glossary -> Text
canonicalSlug term g =
  case Map.lookup (normalizeKey term) g.termIndex of
    Just s -> s
    Nothing -> toSlug term

-- | Convert arbitrary text into a URL/anchor-safe slug.
-- Lowercases and replaces non-alphanumeric characters with hyphens.
toSlug :: Text -> Text
toSlug =
  T.intercalate "-"
    . filter (not . T.null)
    . T.split (not . isAlphaNum)
    . T.toLower
