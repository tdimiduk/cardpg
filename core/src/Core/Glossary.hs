-- |
-- Module: Core.Glossary
-- Description: Canonical game rules keyword glossary, types, and lookup helpers.
module Core.Glossary
  ( -- * Canonical Rules Glossary
    glossary
  , glossaryEntries

    -- * Types
  , Glossary (..)
  , GlossaryEntry (..)

    -- * Lookups and Slugs
  , lookupGlossary
  , canonicalSlug
  , toSlug
  , summaryText

    -- * Construction and Conversion
  , mkGlossary
  , fromList
  , fromMap
  , toMap
  , allEntries
  ) where

import Core.Glossary.Generated (glossary, glossaryEntries)
import Core.Glossary.Types
