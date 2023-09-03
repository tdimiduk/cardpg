{-# LANGUAGE DeriveAnyClass #-}

module Common.Card where

import Data.Aeson
import Data.ByteString (ByteString)
import Data.Csv
import Data.Text (Text)
import Data.Vector
import GHC.Generics
import qualified Data.ByteString.Lazy as LBS

data Card = Card
  { name :: Text
  , red :: Text
  , yellow :: Text
  , blue :: Text
  , keywordProvide
  , cost :: Maybe Text
  , keywordCost :: Maybe Text
  , action :: Maybe Text
  , effect :: Maybe Text
  , details :: Maybe Text


  }
  deriving stock (Generic, Show)
  deriving anyclass (ToJSON, FromJSON)

instance ToNamedRecord Card
instance FromNamedRecord Card

readCardsCsv :: ByteString -> Either String (Header, Vector Card)
readCardsCsv = decodeByName . LBS.fromStrict
