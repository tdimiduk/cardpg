{-# LANGUAGE OverloadedStrings #-}

module Core.Rules.Common
  ( betweenParens
  , effectArrow
  , separatorParser
  , layoutStackPower
  , layoutDifficulty
  ) where

import Control.Applicative ((<|>))
import Control.Monad (void)
import Data.Text (Text)
import Text.Megaparsec (between)
import Text.Megaparsec.Char (space, string)

import Core.DSL (Parser, hspace, tryChoice)
import Core.Language (sepArrow, sepCloseParen, sepComma, sepOpenParen, sepSemi)
import Core.Layout (LayoutItem (..))
import Core.Stats (Difficulty (..), StackPower (..), prettyModifier)
import Core.Util (tshow)

-- The parser p must not consume ')'
betweenParens :: Parser a -> Parser a
betweenParens = between (string sepOpenParen) (string sepCloseParen)

effectArrow :: Parser Text
effectArrow = string sepArrow <|> string "->"

-- Separator Parser
separatorParser :: Parser ()
separatorParser =
  void $
    tryChoice
      [ space >> effectArrow >> hspace
      , space >> string sepSemi >> hspace
      , space >> string sepComma >> hspace
      , hspace
      ]

layoutStackPower :: StackPower -> [LayoutItem]
layoutStackPower (StackPower base 0 Nothing) = [Symbol base Nothing]
layoutStackPower (StackPower base modifier conditional) =
  [ Symbol base Nothing
  , Space
  , Literal (prettyModifier modifier)
  ]
    <> maybe [] (\c -> [Space, Literal c]) conditional

layoutDifficulty :: Difficulty -> [LayoutItem]
layoutDifficulty (Difficulty base val) = [Symbol base (Just $ tshow val)]
