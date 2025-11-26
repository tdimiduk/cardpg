module Common.Parser.Common
  ( Parser
  , sep
  , semicolin
  , nonEmptyText
  , notLineEnd
  , notFieldEnd
  , textTillTab
  , optionalTrailing
  , tsvField
  , ots
  , resourceSymbol
  , plusModifier
  )
  where

import Control.Applicative (liftA2)
import Data.List.NonEmpty (NonEmpty(..))
import Data.Text (Text)
import qualified Data.Text as T
import Text.Megaparsec hiding (some, sepBy1)
import Text.Megaparsec.Char
import qualified Text.Megaparsec.Char.Lexer as L
import Data.Void

import Common.Card.Common (ResourceType(..))

type Parser = Parsec Void Text

sep :: Char
sep = '\t'

semicolin :: Parser Char
semicolin = char ';'

nonEmptyText :: Text -> Maybe Text
nonEmptyText t = if T.null (T.strip t) then Nothing else Just (T.strip t)

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

ots :: Parser p -> Parser p
ots = optionalTrailing (takeWhile1P (Just "spaces") (\x -> x == ' '))

negativeInt :: Parser Int
negativeInt = do
  _ <- ots $ char '-'
  n <- L.decimal
  pure $ n * (-1)

plusInt :: Parser Int
plusInt = do
  _ <- ots $ char '+'
  ots L.decimal

plusModifier :: Parser Int
plusModifier = plusInt <|> L.decimal <|> negativeInt <|> pure 0

-- Replace some combinators that have NonEmpty requirements with ones that actually return NonEmpty

sepBy1 :: Parser a -> Parser sep -> Parser (NonEmpty a)
sepBy1 p s = liftA2 (:|) p (many (s *> p))

some :: Parser a -> Parser (NonEmpty a)
some p = liftA2 (:|) p (many p)
