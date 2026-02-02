module Core.DSL (Parser, hspace, hspace1, basicParse, choiceEnum, mkEnumParser, tryChoice, TextRep (..), parseText) where

import Control.Applicative (empty, (<|>))
import Control.Monad (void)
import Data.Text (Text)
import Data.Void (Void)
import Text.Megaparsec
  ( MonadParsec
  , Parsec
  , choice
  , eof
  , errorBundlePretty
  , parse
  , takeWhile1P
  , takeWhileP
  , try
  )
import Text.Megaparsec.Char (string')

type Parser = Parsec Void Text

isHspace :: Char -> Bool
isHspace c = c == ' ' || c == '\t'

hspace :: Parser ()
hspace = void $ takeWhileP Nothing isHspace

hspace1 :: Parser ()
hspace1 = void $ takeWhile1P Nothing isHspace

basicParse :: Parser a -> Text -> Either String a
basicParse p t = case parse p "" t of
  Left err -> Left $ errorBundlePretty err
  Right r -> Right r

choiceEnum :: (Enum a, Bounded a) => (a -> Parser b) -> Parser b
choiceEnum f = choice $ map f [minBound .. maxBound]

mkEnumParser :: (Enum a, Bounded a) => (a -> Text) -> Parser a
mkEnumParser f = choiceEnum $ \val -> val <$ string' (f val)

-- | Tries a list of parsers, backtracking if they fail, except for the last one.
tryChoice :: (MonadParsec e s f) => [f a] -> f a
tryChoice [] = empty
tryChoice [x] = x
tryChoice (x : xs) = try x <|> tryChoice xs

-- | Typeclass for DSL round-tripping.
-- | Invariant: parseText . toText === Right
class TextRep a where
  toText :: a -> Text
  textParser :: Parser a

-- | Parse text using the TextRep parser
parseText :: (TextRep a) => Text -> Either String a
parseText = basicParse (textParser <* eof)
