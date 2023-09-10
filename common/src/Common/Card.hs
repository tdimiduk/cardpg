{-# LANGUAGE DeriveAnyClass #-}

module Common.Card where

import Control.Monad (mzero)
import Data.Aeson (ToJSON, FromJSON)
import Data.ByteString (ByteString)
import qualified Data.ByteString.Lazy as LBS
import Data.Csv
import Data.Text (Text)
import qualified Data.Text.Encoding as T
import qualified Data.Vector as V
import GHC.Generics

data Card = Card
  { _name :: Text
  , _red :: Text
  , _yellow :: Text
  , _blue :: Text
  , _keywordProvide
  , _cost :: Maybe Text
  , _keywordCost :: Maybe Text
  , _action :: Maybe Text
  , _effect :: Maybe Text
  , _details :: Maybe Text
  }
  deriving stock (Generic, Show)
  deriving anyclass (ToJSON, FromJSON)

instance ToNamedRecord Card
instance FromNamedRecord Card where
  parseNamedRecord m = Card
    <$> m .: "name"
    <*> m .: "red"
    <*> m .: "yellow"
    <*> m .: "blue"
    <*> m .: "keywordProvide"
    <*> m .: "cost"
    <*> m .: "keywordCost"
    <*> m .: "action"
    <*> m .: "effect"
    <*> m .: "details"

data AdhocCard = AdhocCard
  { _ahcName :: Text
  , _blocks :: V.Vector Text
  }
  deriving stock (Generic, Show)
  deriving anyclass (ToJSON, FromJSON)

instance FromRecord AdhocCard where
  parseRecord v
    | length v > 1 = AdhocCard <$> v .! 0 <*> pure (T.decodeUtf8 <$> V.drop 1 v)
    | otherwise = mzero

readCardsCsv :: ByteString -> Either String (Header, V.Vector Card)
readCardsCsv = decodeByName . LBS.fromStrict

readAdhocCardsCsv :: ByteString -> Either String (V.Vector AdhocCard)
readAdhocCardsCsv = decode HasHeader . LBS.fromStrict
