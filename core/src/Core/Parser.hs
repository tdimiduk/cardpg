module Core.Parser (Parser, hspace, hspace1, basicParse, choiceEnum, mkEnumParser, tryChoice) where

import Control.Monad (void)
import Data.Text (Text)
import Data.Void (Void)
import Text.Megaparsec
  ( Parsec
  , choice
  , errorBundlePretty
  , parse
  , takeWhile1P
  , takeWhileP
  , try
  , (<|>)
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
mkEnumParser toText = choiceEnum $ \val -> val <$ string' (toText val)

-- | Tries a list of parsers, backtracking if they fail, except for the last one.
tryChoice :: [Parser a] -> Parser a
tryChoice [] = choice []
tryChoice [x] = x
tryChoice (x : xs) = try x <|> tryChoice xs
