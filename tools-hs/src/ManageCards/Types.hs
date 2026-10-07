{-# LANGUAGE DerivingStrategies #-}

module ManageCards.Types
  ( CardCategory (..)
  , categoryFilePath
  , CardOccurrence (..)
  , CardGroup (..)
  , RewriteResult (..)
  ) where

import Core.Card (CoreCard, RulesStatus)
import Data.Text (Text)

data CardCategory
  = CategoryCore
  | CategoryMartial
  | CategoryArcane
  | CategoryBeasts
  | CategoryHumanoids
  deriving stock (Eq, Show, Ord, Enum, Bounded)

categoryFilePath :: CardCategory -> FilePath
categoryFilePath CategoryCore = "core.yaml"
categoryFilePath CategoryMartial = "martial.yaml"
categoryFilePath CategoryArcane = "arcane.yaml"
categoryFilePath CategoryBeasts = "monsters/beasts.yaml"
categoryFilePath CategoryHumanoids = "monsters/humanoids.yaml"

data CardOccurrence = CardOccurrence
  { sourceFile :: FilePath
  , card :: CoreCard
  }
  deriving stock (Eq, Show)

data CardGroup = CardGroup
  { canonicalSlug :: Text
  , baseCard :: CoreCard
  , occurrences :: [CardOccurrence]
  , category :: CardCategory
  , rulesStatus :: RulesStatus
  , legacyNotes :: Maybe Text
  }
  deriving stock (Eq, Show)

data RewriteResult = RewriteResult
  { totalEntries :: Int
  , replacedEntries :: Int
  , preservedRefEntries :: Int
  , retainedInlineEntries :: Int
  , modified :: Bool
  }
  deriving stock (Eq, Show)
