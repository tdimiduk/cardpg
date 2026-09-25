{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE TemplateHaskell #-}

-- |
-- Module: Frontend.Rules.Data
-- Description: Compile-time embedded rules, keyword glossary, and colors documentation.
module Frontend.Rules.Data
  ( RulesTab (..)
  , DocId
  , embeddedGlossary
  , embeddedRulesDoc
  , embeddedGlossaryDoc
  , embeddedColorsDoc
  , embeddedDocs
  , lookupDoc
  , rulesTabTitle
  , allRulesTabs
  ) where

import Data.Aeson (eitherDecodeStrict')
import Data.ByteString (ByteString)
import Data.FileEmbed (embedFile, makeRelativeToProject)
import Data.Map.Strict (Map)
import Data.Map.Strict qualified as Map
import Data.Text (Text)
import Text.Pandoc.Definition (Pandoc (..), nullMeta)

import Core.Glossary (Glossary, mkGlossary)

-- | Tab identifiers for in-app rules viewer.
data RulesTab = TabCoreRules | TabGlossary | TabColors
  deriving stock (Eq, Ord, Enum, Bounded, Show)

-- | Type alias for document identification matching the design brief.
type DocId = RulesTab

glossaryRaw :: ByteString
glossaryRaw = $(makeRelativeToProject "static/glossary.json" >>= embedFile)

rulesRaw :: ByteString
rulesRaw = $(makeRelativeToProject "static/rules.json" >>= embedFile)

glossaryAstRaw :: ByteString
glossaryAstRaw = $(makeRelativeToProject "static/glossary-ast.json" >>= embedFile)

colorsRaw :: ByteString
colorsRaw = $(makeRelativeToProject "static/colors.json" >>= embedFile)

-- | Canonical keyword glossary eagerly decoded at compile time.
embeddedGlossary :: Glossary
embeddedGlossary = case eitherDecodeStrict' glossaryRaw of
  Left _err -> mkGlossary mempty
  Right g -> g

-- | Core rules Pandoc AST eagerly decoded at compile time.
embeddedRulesDoc :: Pandoc
embeddedRulesDoc = case eitherDecodeStrict' rulesRaw of
  Left _err -> Pandoc nullMeta []
  Right p -> p

-- | Keyword glossary documentation Pandoc AST eagerly decoded at compile time.
embeddedGlossaryDoc :: Pandoc
embeddedGlossaryDoc = case eitherDecodeStrict' glossaryAstRaw of
  Left _err -> Pandoc nullMeta []
  Right p -> p

-- | Colors of Action Pandoc AST eagerly decoded at compile time.
embeddedColorsDoc :: Pandoc
embeddedColorsDoc = case eitherDecodeStrict' colorsRaw of
  Left _err -> Pandoc nullMeta []
  Right p -> p

-- | Pre-indexed mapping of documents by tab identifier.
embeddedDocs :: Map DocId Pandoc
embeddedDocs =
  Map.fromList
    [ (TabCoreRules, embeddedRulesDoc)
    , (TabGlossary, embeddedGlossaryDoc)
    , (TabColors, embeddedColorsDoc)
    ]

-- | Lookup document AST by tab, with empty Pandoc fallback.
lookupDoc :: DocId -> Pandoc
lookupDoc docId = Map.findWithDefault (Pandoc nullMeta []) docId embeddedDocs

-- | Human-readable title for each rules tab.
rulesTabTitle :: RulesTab -> Text
rulesTabTitle = \case
  TabCoreRules -> "Core Rules"
  TabGlossary -> "Keyword Glossary"
  TabColors -> "Colors of Action"

-- | List of all rules tabs in canonical order.
allRulesTabs :: [RulesTab]
allRulesTabs = [minBound .. maxBound]
