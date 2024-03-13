{-# LANGUAGE DeriveAnyClass #-}
{-# LANGUAGE RecordWildCards #-}

module Common.CardParser
  ( parseCards
  , nonEmptyText
  , readAndParse
  , readAndParseTest
  )
  where

import Control.Monad (void)
import Data.Either.Combinators
import Data.List.NonEmpty (NonEmpty(..))
import Data.Text (Text)
import qualified Data.Text as T
import qualified Data.Text.IO as T
import Text.Megaparsec
import Text.Megaparsec.Char
import qualified Text.Megaparsec.Char.Lexer as L
import Data.Void

import Common.Card

type Parser = Parsec Void Text

data CardType = CardStandard | CardAdhoc deriving stock Show

sep :: Char
sep = '\t'

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

card :: Parser Card
card = label "card" $ do
  _actor <- label "actor" $ tsvField textTillTab
  _name <- label "name" $ tsvField textTillTab
  _resources <- resources
  _cost <- cost
  _textbox <- textbox
  label "trailing whitespace for card" hspace
  pure Card {..}

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
  _effect <- label "effect" $ tsvField $ optional fancyText
  _details <- label "details" $ tsvField $ optional fancyText
  pure Textbox {..}

action :: Parser Action
action = label "action"
  (   attack
  <|> defend
  <|> GeneralAction <$> fancyText
  )

attack :: Parser Action
attack = label "attack" $ do
  _ <- string' "attack "
  _resistedBy <- resourceSymbol
  _ <- ots $ string ":"
  _ <- ots $ string' "strength"
  _ <- ots $ optional $ string "="
  _strengthBy <- ots $ resourceSymbol
  _aMod <- ots $ plusModifier
  _aText <- optional textTillTab
  pure Attack {..}

defend :: Parser Action
defend = try standardDefend <|> do
  _ <- ots $ string' "defend:"
  SpecialDefend <$> textTillTab

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
resourceSymbol' = do
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

fancyText :: Parser FancyText
fancyText = FancyText <$> some (ResourceToken <$> resourceSymbol' <|> fancyTextToken)
  where
    fancyTextToken = FancyTextToken <$> takeWhile1P (Just "fancy text token")
      (\x -> notFieldEnd x && x /= '|')

plusModifier :: Parser Int
plusModifier = plusInt <|> L.decimal <|> negativeInt <|> pure 0

orSep :: Parser ()
orSep = void $ ots $ () <$ string ", or" <|> () <$ string " or" <|> () <$ char ','

ots :: Parser p -> Parser p
ots = optionalTrailing hspace

standardDefend :: Parser Action
standardDefend = label "standard defense" $ do
  _ <- string' "defend "
  d <- optionalTrailing orSep resourceSymbol
  ds <- resourceSymbol `sepBy` orSep
  let _resists = d :| ds
  _ <- ots $ string ":"
  _ <- ots $ string' "strength"
  _ <- ots $ optional $ string "="
  _resistWith <- ots $ resourceSymbol
  _dMod <- ots $ plusModifier
  _dText <- optional textTillTab
  pure StandardDefend {..}

blankCard :: Parser Card
blankCard = label "blank card" $ do
  hspace
  pure $ Card "placeholder" "placeholder" (Resources Nothing Nothing Nothing Nothing) (Cost Nothing Nothing) (Textbox Nothing Nothing Nothing)

parseFile :: Parser [Card]
parseFile = do
  _ <- optional header
  c <- (card <|> blankCard) `sepBy` eol
  _ <- many eol
  _ <- eof
  pure c

parseCards :: String -> Text -> Either String [Card]
parseCards context = mapLeft errorBundlePretty . runParser parseFile context

readAndParse :: FilePath -> IO (Either String [Card])
readAndParse name = do
  f <- T.readFile name
  pure $ mapLeft errorBundlePretty $ runParser parseFile name f

readAndParseTest :: FilePath -> IO ()
readAndParseTest name = do
  f <- T.readFile name
  parseTest parseFile f


nonEmptyText :: Text -> Maybe Text
nonEmptyText t = if T.null (T.strip t) then Nothing else Just (T.strip t)
