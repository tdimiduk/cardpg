{-# LANGUAGE FlexibleInstances #-}
{-# LANGUAGE GeneralizedNewtypeDeriving #-}
{-# LANGUAGE UndecidableInstances #-}

module Core.NonEmptyText
  ( NonEmptyText
  , mkNonEmptyText
  , strippedNonEmptyText
  , unsafeNonEmptyText
  , takeWhilePNonEmpty
  , takeWhilePNonEmptyStripped
  , getRawText
  ) where

import Control.Monad (mzero)
import Data.Aeson (FromJSON (..), ToJSON (..), withText)
import Data.Text (Text)
import Data.Text qualified as T
import Data.Void (Void)
import Text.Megaparsec (Parsec, Token, takeWhile1P)

import Core.Render (Render (..))

-- | Parser for NonEmptyText using Megaparsec
-- This wraps takeWhile1P to ensure the result is non-empty at the type level.
takeWhilePNonEmpty :: Maybe String -> (Token Text -> Bool) -> Parsec Void Text NonEmptyText
takeWhilePNonEmpty name p = NonEmptyText <$> takeWhile1P name p

takeWhilePNonEmptyStripped :: Maybe String -> (Token Text -> Bool) -> Parsec Void Text NonEmptyText
takeWhilePNonEmptyStripped name p = do
  s <- takeWhile1P name p
  case strippedNonEmptyText s of
    Just t -> pure t
    Nothing -> fail "only whitespace"

newtype NonEmptyText = NonEmptyText Text
  deriving newtype (Show, Eq, Ord, Semigroup)

getRawText :: NonEmptyText -> Text
getRawText (NonEmptyText t) = t

-- | Smart constructor
mkNonEmptyText :: Text -> Maybe NonEmptyText
mkNonEmptyText t
  | T.null (T.strip t) = Nothing
  | otherwise = Just $ NonEmptyText t

strippedNonEmptyText :: Text -> Maybe NonEmptyText
strippedNonEmptyText t = case T.strip t of
  "" -> Nothing
  s -> Just $ NonEmptyText s

-- | Unsafe constructor for trusted input (e.g. literals)
unsafeNonEmptyText :: Text -> NonEmptyText
unsafeNonEmptyText = NonEmptyText

instance ToJSON NonEmptyText where
  toJSON = toJSON . getRawText

instance FromJSON NonEmptyText where
  parseJSON = withText "NonEmptyText" $ \t ->
    maybe mzero pure (mkNonEmptyText t)

-- | Allow string literals if they are non-empty (runtime check?)
-- Ideally we avoid IsString to prevent runtime errors, but it's convenient.
-- For now, let's NOT implement IsString to force explicit conversion.
instance (Monad m, Render Text m) => Render NonEmptyText m where
  render = render . getRawText
