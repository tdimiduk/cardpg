{-# LANGUAGE DeriveAnyClass #-}
{-# LANGUAGE DeriveFunctor #-}
{-# LANGUAGE FlexibleInstances #-}
{-# LANGUAGE OverloadedRecordDot #-}
{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE TemplateHaskell #-}

module Core.Rules.General
  ( GeneralDef (..)
  , generalParser
  , layoutGeneralDef
  ) where

import Control.Applicative (optional, (<|>))
import Data.Aeson.TH (deriveJSON)
import GHC.Generics (Generic)
import Text.Megaparsec.Char (space, string')

import Core.DSL (Parser, hspace)
import Core.Json (cardpgJsonDef)
import Core.Language (cmdAction, cmdGeneral, sepArrow)
import Core.Layout (LayoutItem (..), layoutWrapper)
import Core.NonEmptyText (NonEmptyText, getRawText, takeWhilePNonEmptyStripped)
import Core.RichText (RichText, richTextParser, richTextParserWith)
import Core.Rules.Common (betweenParens, effectArrow, layoutDifficulty)
import Core.Stats (Difficulty, difficultyParser)

-- | General/Utility Actions
-- | Addresses: "Fatigue: Action (Sleep 2 hours): Remove this"
data GeneralDef = GeneralDef
  { name :: NonEmptyText
  , cost :: Maybe RichText
  -- ^ Narrative Cost: "Sleep 2 hours"
  , difficulty :: Maybe Difficulty
  -- ^ Optional. Fatigue removal isn't a check.
  , effect :: RichText
  -- ^ Effect: "Remove this card"
  }
  deriving (Show, Eq, Generic)

$(deriveJSON cardpgJsonDef ''GeneralDef)

layoutGeneralDef :: GeneralDef -> [LayoutItem]
layoutGeneralDef def =
  [ Keyword cmdAction
  , Space
  , Literal (getRawText def.name)
  ]
    <> maybe [] (\c -> [Space, Group (layoutWrapper [RichContent c])]) def.cost
    <> maybe [] (\d -> [Space] <> layoutDifficulty d) def.difficulty
    <> [Space, Literal sepArrow, Space, RichContent def.effect]

-- General (Explicit Action)
generalParser :: Parser GeneralDef
generalParser = do
  _ <- string' cmdAction <|> string' cmdGeneral
  _ <- space
  name <-
    takeWhilePNonEmptyStripped (Just "Action name") (\c -> c /= '(' && c /= '{' && c /= '-' && c /= '→')

  -- Support "Action: Name (Spend {Color} X) -> Effect"
  -- We treat the parenthetical as the cost
  cost <- optional $ betweenParens $ richTextParserWith [')']
  _ <- space
  difficulty <- optional difficultyParser
  _ <- space
  _ <- effectArrow
  _ <- hspace
  GeneralDef name cost difficulty <$> richTextParser
