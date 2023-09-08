{-# LANGUAGE DeriveAnyClass #-}

module Common.Card where

import Data.Aeson (ToJSON, FromJSON)
import Data.ByteString (ByteString)
import Data.Csv
import Data.Text (Text)
import Data.Vector
import GHC.Generics
import qualified Data.ByteString.Lazy as LBS

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

readCardsCsv :: ByteString -> Either String (Header, Vector Card)
readCardsCsv = decodeByName . LBS.fromStrict
