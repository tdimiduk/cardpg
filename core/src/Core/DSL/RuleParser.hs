module Core.DSL.RuleParser (parseRule, parseAttack, attackParser) where

import Control.Applicative (optional, some, (<|>))
import Control.Monad (void)
import Data.Maybe (fromMaybe)
import Data.Text (Text)
import Data.Text qualified as T

import Text.Megaparsec
  ( between
  , choice
  , eof
  , lookAhead
  , notFollowedBy
  , sepBy1
  , takeWhileP
  , try
  )
import Text.Megaparsec.Char (char, space, space1, string, string')
import Text.Megaparsec.Char.Lexer (decimal)

import Core.Language
  ( cmdAction
  , cmdAttack
  , cmdGeneral
  , cmdOngoing
  , cmdPassive
  , cmdTask
  , cmdWhen
  , kwCheck
  , kwCost
  , kwStrength
  , kwTime
  , sepArrow
  , sepCloseParen
  , sepColon
  , sepComma
  , sepOpenParen
  , sepSemi
  , styleDelimiter
  )
import Core.NonEmptyText
  ( mkNonEmptyText
  , takeWhilePNonEmpty
  , takeWhilePNonEmptyStripped
  , unsafeNonEmptyText
  )
import Core.Parser (Parser, basicParse, choiceEnum, hspace, hspace1, mkEnumParser, tryChoice)
import Core.RichText (Inline (..), RichText, StackPower (..), TextStyle (..), mkRichText)
import Core.RuleDefs
  ( AttackDef (..)
  , GeneralDef (..)
  , OngoingDef (..)
  , PassiveDef (..)
  , Rule (..)
  , TaskDef (..)
  , TriggerDef (..)
  )
import Core.Stats
  ( Difficulty (..)
  , ResourceType (..)
  , parseCanonicalResourceName
  , parseStatValue
  )
import Core.Util (tshow)

parseAttack :: Text -> Either String AttackDef
parseAttack = basicParse attackParser

parseRule :: Text -> Either String Rule
parseRule = basicParse ruleParser

ruleParser :: Parser Rule
ruleParser =
  tryChoice $
    (<* eof)
      <$> [ ongoingParser
          , passiveParser
          , taskParser
          , triggerParser
          , generalParser
          , narrativeParser
          ]

-- The parser p must not consume ')'
betweenParens :: Parser a -> Parser a
betweenParens = between (string sepOpenParen) (string sepCloseParen)

effectArrow :: Parser Text
effectArrow = string sepArrow <|> string "->"

-- Attack
attackParser :: Parser AttackDef
attackParser = do
  _ <- optional $ try $ do
    string' cmdAttack
    space1
  resistedBy <- resourceSymbol
  _ <- space
  _ <- optional (string sepColon)
  _ <- space1
  power <- stackPowerParser
  _ <- separatorParser
  extra <- optional richTextParser
  pure $ AttackDef power resistedBy extra

-- Ongoing (Life) -> Effect
ongoingParser :: Parser Rule
ongoingParser = do
  _ <- string' cmdOngoing
  _ <- space
  life <- betweenParens (richTextParserWith [')'])
  _ <- separatorParser
  RuleOngoing . OngoingDef life <$> richTextParser

-- Passive
passiveParser :: Parser Rule
passiveParser = do
  _ <- string' cmdPassive
  _ <- space
  bonus <- stackPowerParser
  condStr <- takeWhileP Nothing (const True)
  let condition = mkNonEmptyText condStr
  pure $ RulePassive $ PassiveDef bonus condition

-- Task
-- Task: Name ({Color} X, Time) -> Effect
taskParser :: Parser Rule
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

  RuleTask . TaskDef name check time cost <$> richTextParser

-- Trigger (When)
-- When [Trigger] -> [Effect]
triggerParser :: Parser Rule
triggerParser = do
  _ <- string' cmdWhen
  _ <- space1
  trigger <-
    takeWhilePNonEmptyStripped (Just "Trigger condition") (\c -> c /= '-' && c /= '>' && c /= '→')
  _ <- space
  _ <- effectArrow
  _ <- hspace
  RuleTrigger . TriggerDef trigger <$> richTextParser

-- General (Explicit Action)
generalParser :: Parser Rule
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
  RuleGeneral . GeneralDef name cost difficulty <$> richTextParser

-- Narrative (Fallback for General)
narrativeParser :: Parser Rule
narrativeParser = RuleNarrative <$> richTextParser

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

-- Rich Text Parser
richTextParser :: Parser RichText
richTextParser = richTextParserWith []

richTextParserWith :: [Char] -> Parser RichText
richTextParserWith stopChars = do
  inlines <- some (inlineParserStopAt stopChars)
  case mkRichText inlines of
    Just rs -> pure rs
    Nothing -> fail "Empty rich string"

inlineParserStopAt :: [Char] -> Parser Inline
inlineParserStopAt stopChars =
  tryChoice
    [ formattingParser
    , colorValueParser
    , breakParser stopChars
    , textParserStopAt stopChars
    ]

breakParser :: [Char] -> Parser Inline
breakParser stopChars = do
  c <- char ';' <|> char '\n'
  if c `elem` stopChars
    then fail "Stop char"
    else pure Break

between' :: Parser a -> Parser b -> Parser b
between' p = between p p

formattingParser :: Parser Inline
formattingParser = choiceEnum $ \style ->
  TextRun (Just style)
    <$> between'
      (string $ styleDelimiter style)
      (takeWhilePNonEmpty Nothing (`notElem` formattingStopChars style))

formattingStopChars :: TextStyle -> [Char]
formattingStopChars = T.unpack . T.take 1 . styleDelimiter

colorValueParser :: Parser Inline
colorValueParser = do
  -- Lookahead to ensure we are parsing something that looks like a resource symbol
  -- to avoid consuming normal text that starts with '{' but isn't a resource.
  _ <- lookAhead (char '{')
  (DifficultyValue <$> try difficultyParser) <|> (ColorValue <$> parseStatValue)

textParserStopAt :: [Char] -> Parser Inline
textParserStopAt stopChars =
  do
    -- Ensure we don't consume characters that start other parsers or stop chars
    content <-
      takeWhilePNonEmpty
        Nothing
        (\c -> c /= '*' && c /= '`' && c /= ';' && c /= '\n' && c /= '{' && notElem c stopChars)
    pure $ TextRun Nothing content
    <|> do
      -- Fallback for '{' if it wasn't a dynamic val
      _ <- char '{'
      let content = unsafeNonEmptyText "{" -- Safe because we know it's "{"
      pure $ TextRun Nothing content

-- Helpers
resourceSymbol :: Parser ResourceType
resourceSymbol = tryChoice [canonicalResource, shorthandResource, legacyResource]

canonicalResource :: Parser ResourceType
canonicalResource = between (char '{') (char '}') parseCanonicalResourceName

shorthandResource :: Parser ResourceType
shorthandResource = mkEnumParser (T.take 1 . tshow)

legacyResource :: Parser ResourceType
legacyResource = between' (char '|') $ mkEnumParser toLegacy
  where
    toLegacy Red = "x"
    toLegacy Yellow = "y"
    toLegacy Blue = "z"

stackPowerParser :: Parser StackPower
stackPowerParser = do
  _ <- optional $ try $ do
    _ <- string' kwStrength <|> string' "str"
    _ <- hspace1
    _ <- optional (char '=')
    hspace
  base <- resourceSymbol
  _ <- hspace
  modVal <- optional $ try $ do
    sign <- (id <$ char '+') <|> (negate <$ char '-')
    _ <- hspace
    sign <$> decimal
  _ <- hspace
  conditional <- optional $ try $ do
    _ <- char '('
    notFollowedBy (string "Cost:")
    content <- takeWhileP Nothing (/= ')')
    _ <- char ')'
    pure $ "(" <> content <> ")"
  _ <- hspace -- Consume trailing hspace
  pure $ StackPower base (fromMaybe 0 modVal) conditional

difficultyParser :: Parser Difficulty
difficultyParser = do
  _ <- optional $ try $ do
    _ <- string' kwCheck <|> string' "Diff"
    _ <- hspace1
    _ <- optional (char '=')
    hspace
  base <- resourceSymbol
  _ <- hspace
  Difficulty base <$> decimal
