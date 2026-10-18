{-# LANGUAGE DeriveAnyClass #-}
{-# LANGUAGE DeriveFunctor #-}
{-# LANGUAGE FlexibleInstances #-}
{-# LANGUAGE OverloadedRecordDot #-}
{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE TemplateHaskell #-}
{-# LANGUAGE TupleSections #-}

module Core.Rules.Task
  ( Requirement (..)
  , TaskDef (..)
  , emptyTaskDef
  , recognizedRequirementKeywords
  , taskParser
  , layoutTaskDef
  ) where

import Control.Applicative (optional, (<|>))
import Control.Monad (void)
import Data.Aeson.TH (deriveJSON)
import Data.List (find)
import Data.Maybe (catMaybes, fromMaybe)
import Data.Text (Text)
import Data.Text qualified as T
import GHC.Generics (Generic)
import Text.Megaparsec (choice, eof, lookAhead, sepBy1, try)
import Text.Megaparsec.Char (char, space, string')

import Core.DSL (Parser, hspace, hspace1, toText)
import Core.Json (cardpgJsonDef)
import Core.Language (cmdTask, kwCheck, kwCost, kwRequires, kwTime, sepArrow, sepComma, sepSemi)
import Core.Layout (LayoutItem (..), intercalateLayout, layoutWrapper)
import Core.NonEmptyText (NonEmptyText, getRawText, takeWhilePNonEmptyStripped)
import Core.RichText (RichText, richTextParser, richTextParserWith)
import Core.Rules.Common (effectArrow, layoutDifficulty)
import Core.Stats (Difficulty, difficultyParser)
import Core.Time (Duration, durationParser)

-- | A prerequisite or condition for performing a task.
data Requirement
  = -- | A recognized mechanical tag (e.g. "Haven", "Campfire", "Shelter", "Unburdened")
    RequiredKeyword Text
  | -- | Narrative escape hatch for un-enumerated conditions
    RequiredCustom RichText
  deriving (Show, Eq, Generic)

$(deriveJSON cardpgJsonDef ''Requirement)

recognizedRequirementKeywords :: [Text]
recognizedRequirementKeywords =
  [ "Haven"
  , "Campfire"
  , "Shelter"
  , "Unburdened"
  ]

-- | Task Actions (Downtime/Narrative)
-- | Addresses: "Task: First Aid (Check {Blue} 3; Time 1 min): Remove this"
data TaskDef = TaskDef
  { name :: NonEmptyText
  , check :: Maybe Difficulty
  -- ^ The difficulty check: "Check {Blue} 3"
  , time :: Maybe Duration
  -- ^ Duration: "Time 1 min"
  , cost :: Maybe RichText
  -- ^ Narrative Cost: "Cost Bandage"
  , requirements :: [Requirement]
  -- ^ Environmental/situational preconditions: "Requires Haven, Campfire"
  , effect :: RichText
  -- ^ Effect: "Remove this card"
  }
  deriving (Show, Eq, Generic)

$(deriveJSON cardpgJsonDef ''TaskDef)

emptyTaskDef :: NonEmptyText -> RichText -> TaskDef
emptyTaskDef n eff =
  TaskDef
    { name = n
    , check = Nothing
    , time = Nothing
    , cost = Nothing
    , requirements = []
    , effect = eff
    }

layoutRequirement :: Requirement -> [LayoutItem]
layoutRequirement (RequiredKeyword kw) = [Literal kw]
layoutRequirement (RequiredCustom rt) = [RichContent rt]

layoutTaskDef :: TaskDef -> [LayoutItem]
layoutTaskDef def =
  [ Keyword cmdTask
  , Space
  , Literal (getRawText def.name)
  ]
    <> renderTaskParts
    <> [Space, Literal sepArrow, Space, RichContent def.effect]
  where
    renderTaskParts =
      let parts =
            catMaybes
              [ fmap (\c -> [Keyword kwCheck, Space] <> layoutDifficulty c) def.check
              , fmap (\t -> [Keyword kwTime, Space, Literal (toText t)]) def.time
              , fmap (\c -> [Keyword kwCost, Space, RichContent c]) def.cost
              , if null def.requirements
                  then Nothing
                  else
                    Just
                      ( [Keyword kwRequires, Space]
                          <> intercalateLayout [Literal sepComma, Space] (map layoutRequirement def.requirements)
                      )
              ]
       in if null parts
            then []
            else [Space, Group (layoutWrapper (intercalateLayout [Literal sepSemi, Space] parts))]

-- | Task clause parsers operate strictly within single-line DSL rules.
-- Separators use 'hspace' (not multiline 'space') and inline custom text
-- parsers include '\n' in stop characters so clauses do not greedily
-- consume newlines across rule boundaries.
requirementsParser :: Parser [Requirement]
requirementsParser = sepBy1 requirementItemParser (try $ hspace >> char ',' >> hspace)

requirementItemParser :: Parser Requirement
requirementItemParser = do
  _ <- hspace
  keywordP <|> customP
  where
    keywordP = try $ do
      kw <- choice [string' k | k <- recognizedRequirementKeywords]
      _ <- hspace
      lookAhead (void (char ',') <|> void (char ';') <|> void (char ')') <|> eof)
      let canonicalKw =
            fromMaybe kw $
              find (\k -> T.toLower k == T.toLower kw) recognizedRequirementKeywords
      pure (RequiredKeyword canonicalKw)
    customP = RequiredCustom <$> richTextParserWith ['\n', ',', ';', ')']

-- Task
-- Task: Name (Check {Color} X; Time ...; Requires ...) -> Effect
taskParser :: Parser TaskDef
taskParser = do
  _ <- string' cmdTask
  _ <- space
  name <-
    takeWhilePNonEmptyStripped (Just "Task name") (\c -> c /= '(' && c /= '{' && c /= '-' && c /= '→')

  _ <- space
  mClauses <-
    optional $ do
      _ <- char '('
      _ <- hspace
      let checkP = try $ do
            _ <- string' kwCheck
            _ <- hspace1
            difficultyParser

      let timeP = try $ do
            _ <- string' kwTime
            _ <- hspace1
            durationParser

      let costP = try $ do
            _ <- string' kwCost
            _ <- hspace1
            richTextParserWith ['\n', ';', ')']

      let requiresP = try $ do
            _ <- string' kwRequires <|> string' "Requirement" <|> string' "Requirements"
            _ <- hspace1
            requirementsParser

      let clause =
            choice
              [ (\c -> (Just c, Nothing, Nothing, [])) <$> checkP
              , (\t -> (Nothing, Just t, Nothing, [])) <$> timeP
              , (\c -> (Nothing, Nothing, Just c, [])) <$> costP
              , (Nothing,Nothing,Nothing,) <$> requiresP
              ]

      clauses <- sepBy1 clause (try $ hspace >> char ';' >> hspace)
      _ <- hspace
      _ <- char ')'
      let merge (c1, t1, co1, r1) (c2, t2, co2, r2) =
            (c1 <|> c2, t1 <|> t2, co1 <|> co2, r1 <> r2)
      pure $ foldl merge (Nothing, Nothing, Nothing, []) clauses

  let (check, time, cost, reqs) = fromMaybe (Nothing, Nothing, Nothing, []) mClauses

  _ <- space
  _ <- effectArrow
  _ <- hspace
  TaskDef name check time cost reqs <$> richTextParser
