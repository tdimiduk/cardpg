module CardPG.Core.Parser (Parser, hspace, hspace1, basicParse) where

import Control.Monad (void)
import Data.Text (Text)
import Data.Void (Void)
import Text.Megaparsec
  ( Parsec
  , errorBundlePretty
  , parse
  , takeWhile1P
  , takeWhileP
  )

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
