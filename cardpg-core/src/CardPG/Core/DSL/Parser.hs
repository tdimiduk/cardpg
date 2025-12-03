{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE RecordWildCards #-}
{-# LANGUAGE TupleSections #-}

module CardPG.Core.DSL.Parser (parseRule) where

import Control.Applicative ((<|>), optional, some)
import Control.Monad (void)
import Data.Maybe (fromMaybe)
import Data.Text (Text)

import Data.Void (Void)
import Text.Megaparsec (Parsec, parse, errorBundlePretty, try, takeWhile1P, takeWhileP, sepBy1, eof, choice, between, lookAhead, notFollowedBy)
import Text.Megaparsec.Char (char, string, string', space1, space)
import qualified Text.Megaparsec.Char.Lexer as L
import qualified Data.List.NonEmpty as NE

import CardPG.Core.RuleDefs (Rule(..), AttackDef(..), DefendDef(..), GeneralDef(..), StanceDef(..), ChannelDef(..), PrimeDef(..), PassiveDef(..))
import CardPG.Core.RichText (StackPower(..), RichString, mkRichString, Inline(..), TextStyle(..))
import CardPG.Core.Types (ResourceType(..))
import CardPG.Core.NonEmptyText (takeWhilePNonEmpty, takeWhilePNonEmptyStripped, mkNonEmptyText, unsafeNonEmptyText)

type Parser = Parsec Void Text

parseRule :: Text -> Either String Rule
parseRule t = case parse ruleParser "" t of
  Left err -> Left $ errorBundlePretty err
  Right r -> Right r

ruleParser :: Parser Rule
ruleParser = choice
  [ try (attackParser <* eof)
  , try (defendParser <* eof)
  , try (stanceParser <* eof)
  , try (channelParser <* eof)
  , try (primeParser <* eof)
  , try (passiveParser <* eof)
  , try (generalParser <* eof)
  , (narrativeParser <* eof)
  ]

orSep :: Parser ()
orSep = void $ choice
  [ try (space1 >> string' "or" >> space1)
  , try (space >> char ',' >> space)
  ]

-- Attack
attackParser :: Parser Rule
attackParser = do
  _ <- string' "attack"
  _ <- space1
  resistedBy <- resourceSymbol
  _ <- space
  _ <- optional (char ':')
  _ <- space1
  power <- stackPowerParser
  _ <- separatorParser
  extra <- optional richTextParser
  pure $ RuleAttack $ AttackDef power resistedBy extra

-- Defend
defendParser :: Parser Rule
defendParser = do
  _ <- string' "defend"
  _ <- space1
  resists <- sepBy1 resourceSymbol orSep
  _ <- optional (char ':')
  power <- optional (space1 >> stackPowerParser)
  _ <- separatorParser
  extra <- optional richTextParser
  let p = fromMaybe (StackPower Red 0 Nothing) power 
  pure $ RuleDefend $ DefendDef p (NE.fromList resists) extra

-- Stance
stanceParser :: Parser Rule
stanceParser = do
  _ <- string' "stance"
  _ <- space
  _ <- char '('
  duration <- takeWhilePNonEmpty Nothing (/= ')')
  _ <- char ')'
  _ <- separatorParser
  effect <- richTextParser
  pure $ RuleStance $ StanceDef duration effect

-- The parser p must not consume ')'
betweenParens :: Parser a -> Parser a
betweenParens p = do
  _ <- char '('
  r <- p
  _ <- char ')'
  pure $ r

effectArrow :: Parser Text
effectArrow = string "->"

-- Channel
channelParser :: Parser Rule
channelParser = do
  _ <- string' "channel"
  _ <- space
  duration <- betweenParens $ takeWhilePNonEmpty Nothing (/= ')')
  _ <- separatorParser
  effect <- richTextParser
  pure $ RuleChannel $ ChannelDef duration effect

-- Prime
primeParser :: Parser Rule
primeParser = do
  _ <- string' "prime"
  _ <- space
  trigger <- betweenParens $ takeWhilePNonEmpty Nothing (/= ')')
  _ <- hspace
  _ <- char ':'
  _ <- hspace
  reaction <- ruleParser -- Recursive parse for the reaction
  pure $ RulePrime $ PrimeDef trigger reaction

-- Passive
passiveParser :: Parser Rule
passiveParser = do
  _ <- string' "passive"
  _ <- space
  _ <- char ':'
  _ <- space
  bonus <- stackPowerParser
  condStr <- takeWhileP Nothing (const True)
  let condition = mkNonEmptyText condStr
  pure $ RulePassive $ PassiveDef bonus condition

-- General (Explicit)
generalParser :: Parser Rule
generalParser = do
  _ <- string' "Action:" <|> string' "General:"
  _ <- space
  name <- takeWhilePNonEmptyStripped (Just "Action name") (\c -> c /= '(' && c /= '{' && c /= '-') 

  cost <- optional $ betweenParens $ richTextParserWith [')']
  _ <- space
  power <- optional stackPowerParser
  _ <- space
  _ <- effectArrow
  _ <- hspace

  effect <- richTextParser
  
  pure $ RuleGeneral $ GeneralDef name cost power effect

-- Narrative (Fallback for General)
narrativeParser :: Parser Rule
narrativeParser = do
  rt <- richTextParser
  pure $ RuleNarrative rt

-- Separator Parser
separatorParser :: Parser ()
separatorParser = void $ choice
  [ try (space >> effectArrow >> hspace)
  , try (space >> string ";" >> hspace)
  , try (space >> char ',' >> hspace)
  , hspace
  ]

hspace :: Parser ()
hspace = void $ takeWhileP Nothing (\c -> c == ' ' || c == '\t')

-- Rich Text Parser
richTextParser :: Parser RichString
richTextParser = richTextParserWith []

richTextParserWith :: [Char] -> Parser RichString
richTextParserWith stopChars = do
  inlines <- some (inlineParserStopAt stopChars)
  case mkRichString inlines of
    Just rs -> pure rs
    Nothing -> fail "Empty rich string"

inlineParserStopAt :: [Char] -> Parser Inline
inlineParserStopAt stopChars = choice
  [ try boldParser
  , try italicParser
  , try keywordParser
  , try colorValueParser
  , breakParser
  , textParserStopAt stopChars
  ]

breakParser :: Parser Inline
breakParser = do
  _ <- char ';' <|> char '\n'
  pure Break

boldParser :: Parser Inline
boldParser = do
  _ <- string "**"
  content <- takeWhilePNonEmpty Nothing (/= '*')
  _ <- string "**"
  pure $ TextRun (Just Bold) content

italicParser :: Parser Inline
italicParser = do
  _ <- char '*'
  content <- takeWhilePNonEmpty Nothing (/= '*')
  _ <- char '*'
  pure $ TextRun (Just Italic) content

keywordParser :: Parser Inline
keywordParser = do
  _ <- char '`'
  content <- takeWhilePNonEmpty Nothing (/= '`')
  _ <- char '`'
  pure $ TextRun (Just GameKeyword) content

colorValueParser :: Parser Inline
colorValueParser = do
  -- Lookahead to ensure we are parsing something that looks like a resource symbol
  -- to avoid consuming normal text that starts with '{' but isn't a resource.
  _ <- lookAhead (char '{')
  sp <- stackPowerParser
  pure $ ColorValue sp

textParserStopAt :: [Char] -> Parser Inline
textParserStopAt stopChars = do
  -- Ensure we don't consume characters that start other parsers or stop chars
  content <- takeWhilePNonEmpty Nothing (\c -> c /= '*' && c /= '`' && c /= ';' && c /= '\n' && c /= '{' && notElem c stopChars)
  pure $ TextRun Nothing content
  <|> do
    -- Fallback for '{' if it wasn't a dynamic val
    _ <- char '{'
    let content = unsafeNonEmptyText "{" -- Safe because we know it's "{"
    pure $ TextRun Nothing content

-- Helpers
resourceSymbol :: Parser ResourceType
resourceSymbol = choice
  [ try canonicalResource
  , try shorthandResource
  , legacyResource
  ]

canonicalResource :: Parser ResourceType
canonicalResource = between (char '{') (char '}') $ choice
  [ Red <$ string' "Red"
  , Yellow <$ string' "Yellow"
  , Blue <$ string' "Blue"
  ]

shorthandResource :: Parser ResourceType
shorthandResource = choice
  [ Red <$ string' "R"
  , Yellow <$ string' "Y"
  , Blue <$ string' "B"
  ]

legacyResource :: Parser ResourceType
legacyResource = between (char '|') (char '|') $ choice
  [ Red <$ char 'x'
  , Yellow <$ char 'y'
  , Blue <$ char 'z'
  ]

hspace1 :: Parser ()
hspace1 = void $ takeWhile1P Nothing (\c -> c == ' ' || c == '\t')

stackPowerParser :: Parser StackPower
stackPowerParser = do
  _ <- optional $ try $ do
    _ <- string' "strength" <|> string' "str"
    _ <- hspace1
    _ <- optional (char '=')
    hspace
  base <- resourceSymbol
  _ <- hspace
  modVal <- optional $ try $ do
    sign <- (id <$ char '+') <|> (negate <$ char '-')
    _ <- hspace
    n <- L.decimal
    pure (sign n)
  _ <- hspace
  conditional <- optional $ try $ do
    _ <- char '('
    notFollowedBy (string "Cost:")
    content <- takeWhileP Nothing (/= ')')
    _ <- char ')'
    pure $ "(" <> content <> ")"
  _ <- hspace -- Consume trailing hspace
  pure $ StackPower base (fromMaybe 0 modVal) conditional
