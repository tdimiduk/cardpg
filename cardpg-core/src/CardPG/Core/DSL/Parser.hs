{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE RecordWildCards #-}
{-# LANGUAGE TupleSections #-}

module CardPG.Core.DSL.Parser where

import Control.Applicative ((<|>), optional, many, some)
import Control.Monad (void)
import Data.Maybe (fromMaybe)
import Data.Text (Text)
import qualified Data.Text as T
import Data.Void (Void)
import Text.Megaparsec (Parsec, parse, errorBundlePretty, try, takeWhile1P, takeWhileP, label, sepBy1, eof, choice, between)
import Text.Megaparsec.Char (char, string, string', space1, space)
import qualified Text.Megaparsec.Char.Lexer as L
import Data.List.NonEmpty (NonEmpty(..))
import qualified Data.List.NonEmpty as NE

import CardPG.Core.Card (Rule(..), AttackDef(..), DefendDef(..))
import CardPG.Core.RichText (simpleString, StackPower(..), RichString, Inline(..), TextRunDef(..), TextStyle(..))
import CardPG.Core.Types (ResourceType(..))

type MParser = Parsec Void Text

parseRule :: Text -> Either String Rule
parseRule t = case parse ruleParser "" t of
  Left err -> Left $ errorBundlePretty err
  Right r -> Right r

ruleParser :: MParser Rule
ruleParser = try (attackParser <* eof) <|> try (defendParser <* eof) <|> (generalParser <* eof)

orSep :: MParser ()
orSep = void $ choice
  [ try (space1 >> string' "or" >> space1)
  , try (space >> char ',' >> space)
  ]

-- Attack
attackParser :: MParser Rule
attackParser = do
  _ <- string' "attack"
  _ <- space1
  resistedBy <- resourceSymbol
  _ <- space
  _ <- optional (char ':')
  _ <- space1
  power <- stackPowerParser
  _ <- separatorParser
  extra <- richTextParser
  let extraOpt = if null extra then Nothing else Just extra
  pure $ RuleAttack $ AttackDef power resistedBy extraOpt

-- Defend
defendParser :: MParser Rule
defendParser = do
  _ <- string' "defend"
  _ <- space1
  resists <- sepBy1 resourceSymbol orSep
  _ <- optional (char ':')
  power <- optional (space1 >> stackPowerParser)
  _ <- separatorParser
  extra <- richTextParser
  let extraOpt = if null extra then Nothing else Just extra
  let p = fromMaybe (StackPower Red 0 Nothing) power 
  pure $ RuleDefend $ DefendDef p (NE.fromList resists) extraOpt

-- General
generalParser :: MParser Rule
generalParser = do
  rt <- richTextParser
  pure $ RuleNarrative rt

-- Separator Parser
-- Handles the transition between stats and effect.
-- Canonical: "->"
-- Legacy: ";" or "," or just space
separatorParser :: MParser ()
separatorParser = void $ choice
  [ try (space >> string "->" >> hspace)
  , try (space >> string ";" >> hspace)
  , try (space >> char ',' >> hspace)
  , hspace
  ]

hspace :: MParser ()
hspace = void $ takeWhileP Nothing (\c -> c == ' ' || c == '\t')

-- Rich Text Parser
richTextParser :: MParser RichString
richTextParser = many inlineParser

inlineParser :: MParser Inline
inlineParser = choice
  [ try boldParser
  , try italicParser
  , try keywordParser
  , breakParser
  , textParser
  ]

breakParser :: MParser Inline
breakParser = do
  _ <- char ';' <|> char '\n'
  pure Break

boldParser :: MParser Inline
boldParser = do
  _ <- string "**"
  content <- takeWhile1P Nothing (/= '*')
  _ <- string "**"
  pure $ TextRun $ TextRunDef (Just Bold) content

italicParser :: MParser Inline
italicParser = do
  _ <- char '*'
  content <- takeWhile1P Nothing (/= '*')
  _ <- char '*'
  pure $ TextRun $ TextRunDef (Just Italic) content

keywordParser :: MParser Inline
keywordParser = do
  _ <- char '`'
  content <- takeWhile1P Nothing (/= '`')
  _ <- char '`'
  pure $ TextRun $ TextRunDef (Just GameKeyword) content

textParser :: MParser Inline
textParser = do
  content <- takeWhile1P Nothing (\c -> c /= '*' && c /= '`' && c /= ';' && c /= '\n')
  pure $ TextRun $ TextRunDef Nothing content

-- Helpers
resourceSymbol :: MParser ResourceType
resourceSymbol = choice
  [ try canonicalResource
  , try shorthandResource
  , legacyResource
  ]

canonicalResource :: MParser ResourceType
canonicalResource = between (char '{') (char '}') $ choice
  [ Red <$ string' "Red"
  , Yellow <$ string' "Yellow"
  , Blue <$ string' "Blue"
  ]

shorthandResource :: MParser ResourceType
shorthandResource = choice
  [ Red <$ string' "R"
  , Yellow <$ string' "Y"
  , Blue <$ string' "B"
  ]

legacyResource :: MParser ResourceType
legacyResource = between (char '|') (char '|') $ choice
  [ Red <$ char 'x'
  , Yellow <$ char 'y'
  , Blue <$ char 'z'
  ]

stackPowerParser :: MParser StackPower
stackPowerParser = do
  _ <- optional $ try $ do
    _ <- string' "strength" <|> string' "str"
    _ <- space
    _ <- optional (char '=')
    space
  base <- resourceSymbol
  _ <- space
  modVal <- optional $ do
    sign <- (id <$ char '+') <|> (negate <$ char '-')
    _ <- space
    n <- L.decimal
    pure (sign n)
  _ <- space
  conditional <- optional $ do
    _ <- char '('
    content <- takeWhileP Nothing (/= ')')
    _ <- char ')'
    pure $ "(" <> content <> ")"
  pure $ StackPower base (fromMaybe 0 modVal) conditional
