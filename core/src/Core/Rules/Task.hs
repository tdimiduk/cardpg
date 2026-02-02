{-# LANGUAGE DeriveAnyClass #-}
{-# LANGUAGE DeriveFunctor #-}
{-# LANGUAGE FlexibleInstances #-}
{-# LANGUAGE OverloadedRecordDot #-}
{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE TemplateHaskell #-}

module Core.Rules.Task
  ( TaskDef (..)
  , taskParser
  , layoutTaskDef
  ) where

import Control.Applicative ((<|>))
import Data.Aeson.TH (deriveJSON)
import Data.Maybe (catMaybes)
import GHC.Generics (Generic)
import Text.Megaparsec (choice, sepBy1, try)
import Text.Megaparsec.Char (char, space, string')

import Core.DSL (Parser, hspace, hspace1)
import Core.Json (cardpgJsonDef)
import Core.Language (cmdTask, kwCheck, kwCost, kwTime, sepArrow, sepSemi)
import Core.Layout (LayoutItem (..), intercalateLayout, layoutWrapper)
import Core.NonEmptyText (NonEmptyText, getRawText, takeWhilePNonEmptyStripped)
import Core.RichText (RichText, richTextParser, richTextParserWith)
import Core.Rules.Common (effectArrow, layoutDifficulty)
import Core.Stats (Difficulty, difficultyParser)

-- | Task Actions (Downtime/Narrative)
-- | Addresses: "Task: First Aid ({Blue} 3, 1 min): Remove this"
data TaskDef = TaskDef
  { name :: NonEmptyText
  , check :: Maybe Difficulty
  -- ^ The difficulty check: "Check {Blue} 3"
  , time :: Maybe RichText
  -- ^ Duration: "Time 1 min"
  , cost :: Maybe RichText
  -- ^ Narrative Cost: "Cost Bandage"
  , effect :: RichText
  -- ^ Effect: "Remove this card"
  }
  deriving (Show, Eq, Generic)

$(deriveJSON cardpgJsonDef ''TaskDef)

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
              , fmap (\t -> [Keyword kwTime, Space, RichContent t]) def.time
              , fmap (\c -> [Keyword kwCost, Space, RichContent c]) def.cost
              ]
       in if null parts
            then []
            else [Space, Group (layoutWrapper (intercalateLayout [Literal sepSemi, Space] parts))]

-- Task
-- Task: Name ({Color} X, Time) -> Effect
taskParser :: Parser TaskDef
taskParser = do
  _ <- string' cmdTask
  _ <- space
  name <-
    takeWhilePNonEmptyStripped (Just "Task name") (\c -> c /= '(' && c /= '{' && c /= '-' && c /= '→')

  (check, time, cost) <-
    try
      ( do
          _ <- char '('

          let checkP = try $ do
                _ <- string' kwCheck
                _ <- hspace1
                difficultyParser

          let timeP = try $ do
                _ <- string' kwTime
                _ <- hspace1
                richTextParserWith [';', ')']

          let costP = try $ do
                _ <- string' kwCost
                _ <- hspace1
                richTextParserWith [';', ')']

          let clause =
                choice
                  [ (\c -> (Just c, Nothing, Nothing)) <$> checkP
                  , (\t -> (Nothing, Just t, Nothing)) <$> timeP
                  , (\c -> (Nothing, Nothing, Just c)) <$> costP
                  ]

          clauses <- sepBy1 clause (try $ space >> char ';' >> space)

          _ <- char ')'

          let merge (c1, t1, co1) (c2, t2, co2) = (c1 <|> c2, t1 <|> t2, co1 <|> co2)
          let (finalCheck, finalTime, finalCost) = foldl merge (Nothing, Nothing, Nothing) clauses

          pure (finalCheck, finalTime, finalCost)
      )
      <|> pure (Nothing, Nothing, Nothing)

  _ <- space
  _ <- effectArrow
  _ <- hspace
  TaskDef name check time cost <$> richTextParser
