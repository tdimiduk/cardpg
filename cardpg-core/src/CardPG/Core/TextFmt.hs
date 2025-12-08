module CardPG.Core.TextFmt (TextFmt (..)) where

import Data.Text (Text)

class TextFmt a where
  toText :: a -> Text
  fromText :: Text -> Either String a
