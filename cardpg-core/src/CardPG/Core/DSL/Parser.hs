module CardPG.Core.DSL.Parser (parseRule) where

import Control.Applicative (optional, some, (<|>))
import Control.Monad (void)
import Data.Maybe (fromMaybe)
import Data.Text (Text)

import Data.Void (Void)
import Text.Megaparsec
  ( Parsec
  , between
  , choice
  , eof
  , errorBundlePretty
  , lookAhead
  , notFollowedBy
  , parse
  , sepBy1
  , takeWhile1P
  , takeWhileP
  , try
  )
import Text.Megaparsec.Char (char, space, space1, string, string')
import Text.Megaparsec.Char.Lexer (decimal)

import CardPG.Core.NonEmptyText
  ( mkNonEmptyText
  , takeWhilePNonEmpty
  , takeWhilePNonEmptyStripped
  , unsafeNonEmptyText
  )
import CardPG.Core.Primitives (Difficulty (..), ResourceType (..))
import CardPG.Core.RichText (Inline (..), RichText, StackPower (..), TextStyle (..), mkRichText)
import CardPG.Core.RuleDefs
  ( AttackDefT (..)
  , GeneralDefT (..)
  , OngoingDefT (..)
  , PassiveDef (..)
  , Rule
  , RuleT (..)
  , TaskDefT (..)
  , TriggerDefT (..)
  )

type Parser = Parsec Void Text

parseRule :: Text -> Either String Rule
parseRule t = case parse ruleParser "" t of
  Left err -> Left $ errorBundlePretty err
  Right r -> Right r

ruleParser :: Parser Rule
ruleParser =
  choice
    [ try (attackParser <* eof)
    , try (ongoingParser <* eof)
    , try (passiveParser <* eof)
    , try (taskParser <* eof)
    , try (triggerParser <* eof)
    , try (generalParser <* eof)
    , narrativeParser <* eof
    ]

-- Helpers (General)
-- The parser p must not consume ')'
betweenParens :: Parser a -> Parser a
betweenParens p = do
  _ <- char '('
  r <- p
  _ <- char ')'
  pure r

effectArrow :: Parser Text
effectArrow = string "->"

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

-- Ongoing (Stance, Channel, Prime)
-- Ongoing (Life) -> Effect
ongoingParser :: Parser Rule
ongoingParser = do
  _ <- string' "Ongoing"
  _ <- space
  life <- betweenParens (richTextParserWith [')'])
  _ <- separatorParser
  RuleOngoing . OngoingDef life <$> richTextParser

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

-- Task
-- Task: Name ({Color} X, Time) -> Effect
taskParser :: Parser Rule
taskParser = do
  _ <- string' "Task:"
  _ <- space
  name <- takeWhilePNonEmptyStripped (Just "Task name") (\c -> c /= '(' && c /= '{' && c /= '-')

  (check, time, cost) <-
    try
      ( do
          _ <- char '('

          let checkP = try $ do
                _ <- string' "Check"
                _ <- hspace1
                difficultyParser

          let timeP = try $ do
                _ <- string' "Time"
                _ <- hspace1
                richTextParserWith [';', ')']

          let costP = try $ do
                _ <- string' "Cost"
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
  _ <- string' "When"
  _ <- space1
  trigger <- takeWhilePNonEmptyStripped (Just "Trigger condition") (\c -> c /= '-' && c /= '>')

  _ <- space
  _ <- effectArrow
  _ <- hspace

  RuleTrigger . TriggerDef trigger <$> richTextParser

-- General (Explicit Action)
generalParser :: Parser Rule
generalParser = do
  _ <- string' "Action:" <|> string' "General:"
  _ <- space
  name <- takeWhilePNonEmptyStripped (Just "Action name") (\c -> c /= '(' && c /= '{' && c /= '-')

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
    choice
      [ try (space >> effectArrow >> hspace)
      , try (space >> string ";" >> hspace)
      , try (space >> char ',' >> hspace)
      , hspace
      ]

hspace :: Parser ()
hspace = void $ takeWhileP Nothing (\c -> c == ' ' || c == '\t')

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
  choice
    [ try boldParser
    , try italicParser
    , try keywordParser
    , try colorValueParser
    , breakParser stopChars
    , textParserStopAt stopChars
    ]

breakParser :: [Char] -> Parser Inline
breakParser stopChars = do
  c <- lookAhead (char ';' <|> char '\n')
  if c `elem` stopChars
    then fail "Stop char"
    else do
      _ <- char c
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
  (DifficultyValue <$> try difficultyParser) <|> (ColorValue <$> stackPowerParser)

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
resourceSymbol =
  choice
    [ try canonicalResource
    , try shorthandResource
    , legacyResource
    ]

canonicalResource :: Parser ResourceType
canonicalResource =
  between (char '{') (char '}') $
    choice
      [ Red <$ string' "Red"
      , Yellow <$ string' "Yellow"
      , Blue <$ string' "Blue"
      ]

shorthandResource :: Parser ResourceType
shorthandResource =
  choice
    [ Red <$ string' "R"
    , Yellow <$ string' "Y"
    , Blue <$ string' "B"
    ]

legacyResource :: Parser ResourceType
legacyResource =
  between (char '|') (char '|') $
    choice
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
    _ <- string' "Check" <|> string' "Diff"
    _ <- hspace1
    _ <- optional (char '=')
    hspace
  base <- resourceSymbol
  _ <- hspace
  Difficulty base <$> decimal
