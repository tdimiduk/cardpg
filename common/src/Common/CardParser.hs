{-# LANGUAGE DeriveAnyClass #-}
{-# LANGUAGE RecordWildCards #-}

module Common.CardParser
  ( parseCards
  , nonEmptyText
  )
  where

import Data.Either.Combinators
import Data.Text (Text)
import qualified Data.Text as T
import qualified Data.Text.IO as T
import Text.Megaparsec
import Text.Megaparsec.Char
import Data.Void

import Common.Card

type Parser = Parsec Void Text

data CardType = CardStandard | CardAdhoc deriving stock Show

sep :: Char
sep = '\t'

header :: Parser CardType
header = do
  _ <- optional (string' "actor")
  _ <- char sep
  _ <- string' "name"
  _ <- char sep
  r <- optional $ string' "red"
  _ <- many $ anySingleBut '\n'
  _ <- newline
  pure $ case r of
    Just _ -> CardStandard
    Nothing -> CardAdhoc

quoted :: Parser Text
quoted = do
  let quoteChar = '"'
  _ <- char quoteChar <?> "opening quote"
  v <- takeWhile1P (Just "quoted field") (\x -> x /= quoteChar)
  _ <- char quoteChar <?> "closing quote"
  pure v

unquotedFieldBody :: Parser Text
unquotedFieldBody = takeWhile1P (Just "unquoted field") (\x -> x /= sep && x /= '\n' && x /= '\r')

fieldBody :: Parser Text
fieldBody = label "field body" $ quoted <|> unquotedFieldBody

field :: Parser Text
field = label "field" $ do
  _ <- char sep
  fieldBody

optionalField :: Parser (Maybe Text)
optionalField = label "optional field" $ do
  _ <- optional $ char sep
  optional fieldBody

resources :: Parser Resources
resources = label "resources" $ do
    _red <- label "red" optionalField
    _yellow <- label "yellow" optionalField
    _blue <- label "blue" optionalField
    _keywordProvide <- label "keywords provided" optionalField
    pure Resources {..}

textbox :: Parser Textbox
textbox = label "textbox" $ do
  _action <- label "action" optionalField
  _effect <- label "effect" optionalField
  _details <- label "details" optionalField
  pure Textbox {..}

cost :: Parser Cost
cost = label "cost" $ do
  _cards <- label "cost" optionalField
  _keywordCost <- label "required keywords" optionalField
  pure Cost {..}


card :: Parser Card
card = label "card" $ do
  _actor <- label "actor" $ fieldBody
  _name <- label "name" $ field
  _resources <- resources
  _cost <- cost
  _textbox <- textbox
  hspace
  pure Card {..}

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

parseCards context = mapLeft errorBundlePretty . runParser parseFile context

readAndParse :: FilePath -> IO (Either String [Card])
readAndParse name = do
  f <- T.readFile name
  pure $ mapLeft errorBundlePretty $ runParser parseFile name f

readAndParseTest name = do
  f <- T.readFile name
  parseTest parseFile f


nonEmptyText :: Text -> Maybe Text
nonEmptyText t = if T.null (T.strip t) then Nothing else Just (T.strip t)
