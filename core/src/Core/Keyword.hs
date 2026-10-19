{-# LANGUAGE DerivingStrategies #-}
{-# LANGUAGE OverloadedStrings #-}

module Core.Keyword
  ( Keyword (..)
  , mkKeyword
  , unsafeKeyword
  , keywordToText
  , keywordParser
  ) where

import Control.Monad (mzero)
import Data.Aeson (FromJSON (..), ToJSON (..), withText)
import Data.String (IsString (..))
import Data.Text (Text)
import Data.Text qualified as T
import Data.Void (Void)
import GHC.Generics (Generic)
import Text.Megaparsec (Parsec, Token)

import Core.NonEmptyText
  ( NonEmptyText
  , getRawText
  , strippedNonEmptyText
  , takeWhilePNonEmptyStripped
  , unsafeNonEmptyText
  )

newtype Keyword = Keyword {unKeyword :: NonEmptyText}
  deriving stock (Show, Eq, Ord, Generic)

keywordToText :: Keyword -> Text
keywordToText (Keyword net) = getRawText net

mkKeyword :: Text -> Maybe Keyword
mkKeyword t = Keyword <$> strippedNonEmptyText t

unsafeKeyword :: Text -> Keyword
unsafeKeyword t = Keyword (unsafeNonEmptyText (T.strip t))

instance IsString Keyword where
  fromString s = case mkKeyword (T.pack s) of
    Just k -> k
    Nothing -> error "Keyword.fromString: empty keyword"

instance ToJSON Keyword where
  toJSON = toJSON . keywordToText

instance FromJSON Keyword where
  parseJSON = withText "Keyword" $ \t ->
    maybe mzero pure (mkKeyword t)

keywordParser :: Maybe String -> (Token Text -> Bool) -> Parsec Void Text Keyword
keywordParser name p = Keyword <$> takeWhilePNonEmptyStripped name p
