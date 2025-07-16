{-# LANGUAGE DeriveAnyClass #-}
{-# LANGUAGE RecordWildCards #-}

module Common.CardParser
  ( parseCards
  , nonEmptyText
  , readAndParse
  , readAndParseTest
  )
  where

import Control.Applicative (liftA2)
import Control.Monad (void)
import Data.Either.Combinators
import Data.List.NonEmpty (NonEmpty(..))
import Data.Text (Text)
import qualified Data.Text as T
import qualified Data.Text.IO as T
import Text.Megaparsec hiding (some, sepBy1)
import Text.Megaparsec.Char
import qualified Text.Megaparsec.Char.Lexer as L
import Data.Void

import Common.Card
import Common.Card.Common

type Parser = Parsec Void Text

data CardType = CardStandard | CardAdhoc deriving stock Show

sep :: Char
sep = '\t'

semicolin :: Parser Char
semicolin = char ';'

header :: Parser CardType
header = do
  _ <- tsvField $ string' "actor"
  _ <- tsvField $ string' "name"
  r <- optional $ string' "red"
  _ <- takeWhileP (Just "rest of header") notLineEnd
  _ <- eol
  pure $ case r of
    Just _ -> CardStandard
    Nothing -> CardAdhoc

card :: Parser CoreCard
card = label "card" $ do
  _actor <- label "actor" $ tsvField textTillTab
  _name <- label "name" $ tsvField textTillTab
  _resources <- resources
  _cost <- cost
  _textbox <- textbox
  label "trailing whitespace for card" hspace
  pure CoreCard {..}

resources :: Parser Resources
resources = label "resources" $ do
    _red <- label "red" $ tsvField $ optional textTillTab
    _yellow <- label "yellow" $ tsvField $ optional textTillTab
    _blue <- label "blue" $ tsvField $ optional textTillTab
    _keywordProvide <- label "keywords provided" $ tsvField $ optional textTillTab
    pure Resources {..}

cost :: Parser Cost
cost = label "cost" $ do
  _cards <- label "cost" $ tsvField $ optional $ textTillTab
  _keywordCost <- label "required keywords" $ tsvField $ optional $ textTillTab
  pure Cost {..}

textbox :: Parser Textbox
textbox = label "textbox" $ do
  _action <- tsvField $ optional action
  _effect <- label "effect" $ tsvField $ optional cardText
  _details <- label "details" $ tsvField $ optional cardText
  pure Textbox {..}

action :: Parser Action
action = label "action"
  (   AttackAction <$> attack
  <|> defend
  <|> GeneralAction <$> cardText
  )

attack :: Parser Attack
attack = label "attack" $ do
  _ <- string' "attack "
  _resistedBy <- resourceSymbol
  _strength <- actionStrength
  _text <- optional cardText
  pure Attack {..}

defend :: Parser Action
defend = try (DefendAction <$> standardDefend) <|> do
  _ <- ots $ string' "defend:"
  SpecialDefend <$> cardText

notLineEnd :: Char -> Bool
notLineEnd x = x /= '\n' && x /= '\r'

notFieldEnd :: Char -> Bool
notFieldEnd x =  x /= sep && notLineEnd x

textTillTab :: Parser Text
textTillTab = takeWhile1P (Just "tab terminated text") (notFieldEnd)

optionalTrailing :: Parser t -> Parser p -> Parser p
optionalTrailing t p = p <* optional t

tsvField :: Parser p -> Parser p
tsvField = label "tsv field" . optionalTrailing tab

resourceSymbol :: Parser ResourceType
resourceSymbol = ots $ resourceSymbol'

resourceSymbol' :: Parser ResourceType
resourceSymbol' = label "resource symbol" $ do
  _ <- char '|'
  r <- Red <$ char 'x' <|> Yellow <$ char 'y' <|> Blue <$ char 'z'
  _ <- char '|'
  pure r

negativeInt :: Parser Int
negativeInt = do
  _ <- ots $ char '-'
  n <- L.decimal
  pure $ n * (-1)

plusInt :: Parser Int
plusInt = do
  _ <- ots $ char '+'
  ots L.decimal

cardText :: Parser CardText
cardText = label "card text" $ CardText <$> cardBlock `sepBy1` (char ';')

cardBlock :: Parser CardBlock
cardBlock = label "card text block" $ Paragraph <$> some (ResourceIcon <$> resourceSymbol' <|> txt)
  where
    txt = Txt <$> takeWhile1P (Just "card text token") (\x -> notFieldEnd x && x /= '|' && x /= ';')

plusModifier :: Parser Int
plusModifier = plusInt <|> L.decimal <|> negativeInt <|> pure 0

orSep :: Parser ()
orSep = label "OR-like" $ void $ ots $ () <$ try (ots (char ',') >> string' "or") <|> () <$ string' "or" <|> () <$ char ','

ots :: Parser p -> Parser p
ots = optionalTrailing (takeWhile1P (Just "spaces") (\x -> x == ' '))

standardDefend :: Parser StandardDefend
standardDefend = label "standard defense" $ do
  _ <- ots $ string' "defend"
  _resists <- resists
  _strength <- actionStrength
  _text <- optional cardText
  pure StandardDefend {..}

resists :: Parser (NonEmpty ResourceType)
resists = label "resists group" $ (ots resourceSymbol) `sepBy1` orSep

actionStrength :: Parser ActionStrength
actionStrength = label "action strength" $ do
  _ <- ots $ string ":"
  _ <- optional $ do
    _ <- ots $ string' "strength"
    ots $ optional $ string "="
  _asResource <- ots $ resourceSymbol
  _asMod <- ots $ plusModifier
  _ <- optional semicolin
  pure ActionStrength {..}

blankCard :: Parser CoreCard
blankCard = label "blank card" $ do
  hspace
  pure $ CoreCard "placeholder" "placeholder" (Resources Nothing Nothing Nothing Nothing) (Cost Nothing Nothing) (Textbox Nothing Nothing Nothing)

parseFile :: Parser [CoreCard]
parseFile = do
  _ <- optional header
  c <- (card <|> blankCard) `sepBy` eol
  _ <- many eol
  _ <- eof
  pure c

parseCards :: String -> Text -> Either String [CoreCard]
parseCards context = mapLeft errorBundlePretty . runParser parseFile context

readAndParse :: FilePath -> IO (Either String [CoreCard])
readAndParse name = do
  f <- T.readFile name
  pure $ mapLeft errorBundlePretty $ runParser parseFile name f

readAndParseTest :: FilePath -> IO ()
readAndParseTest name = do
  f <- T.readFile name
  parseTest parseFile f


nonEmptyText :: Text -> Maybe Text
nonEmptyText t = if T.null (T.strip t) then Nothing else Just (T.strip t)

-- Replace some combinators that have NonEmpty requirements with ones that actually return NonEmpty

sepBy1 :: Parser a -> Parser sep -> Parser (NonEmpty a)
sepBy1 p s = liftA2 (:|) p (many (s *> p))

some :: Parser a -> Parser (NonEmpty a)
some p = liftA2 (:|) p (many p)
