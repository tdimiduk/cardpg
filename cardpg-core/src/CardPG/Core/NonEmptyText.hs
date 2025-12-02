{-# LANGUAGE DeriveGeneric #-}
{-# LANGUAGE GeneralizedNewtypeDeriving #-}
{-# LANGUAGE GeneralizedNewtypeDeriving #-}
{-# LANGUAGE TemplateHaskell #-}
{-# LANGUAGE ScopedTypeVariables #-}
{-# LANGUAGE OverloadedStrings #-}

module CardPG.Core.NonEmptyText 
  ( NonEmptyText
  , mkNonEmptyText
  , unsafeNonEmptyText
  , takeWhilePNonEmpty
  , getNonEmptyText
  ) where

import Data.Text (Text)
import qualified Data.Text as T
import Data.Aeson (ToJSON(..), FromJSON(..), withText)
import Data.Aeson.TypeScript.TH (deriveTypeScript)
import CardPG.Core.Json (cardpgJsonDef)

import Control.Monad (mzero)

import Text.Megaparsec (Parsec, takeWhile1P, Token)
import Data.Void (Void)

-- | Parser for NonEmptyText using Megaparsec
-- This wraps takeWhile1P to ensure the result is non-empty at the type level.
takeWhilePNonEmpty :: Maybe String -> (Token Text -> Bool) -> Parsec Void Text NonEmptyText
takeWhilePNonEmpty name p = NonEmptyText <$> takeWhile1P name p

newtype NonEmptyText = NonEmptyText { getNonEmptyText :: Text }
  deriving newtype (Show, Eq, Ord, Semigroup)

-- | Smart constructor
mkNonEmptyText :: Text -> Maybe NonEmptyText
mkNonEmptyText t
  | T.null (T.strip t) = Nothing
  | otherwise = Just $ NonEmptyText t

-- | Unsafe constructor for trusted input (e.g. literals)
unsafeNonEmptyText :: Text -> NonEmptyText
unsafeNonEmptyText = NonEmptyText

instance ToJSON NonEmptyText where
  toJSON = toJSON . getNonEmptyText

instance FromJSON NonEmptyText where
  parseJSON = withText "NonEmptyText" $ \t ->
    case mkNonEmptyText t of
      Nothing -> mzero
      Just ne -> pure ne

$(deriveTypeScript cardpgJsonDef ''NonEmptyText)


-- | Allow string literals if they are non-empty (runtime check?)
-- Ideally we avoid IsString to prevent runtime errors, but it's convenient.
-- For now, let's NOT implement IsString to force explicit conversion.
