{-# LANGUAGE DeriveAnyClass #-}

module Common.Card where

import Data.Aeson
import Data.Csv
import Data.Text (Text)
import GHC.Generics

data Card = Card
  { name :: Text
  , red :: Int
  , yellow :: Int
  , blue :: Maybe Int
  , green :: Maybe Int
  , cost :: Maybe Text
  , body :: Text

  }
  deriving stock (Generic, Show)
  deriving anyclass (ToJSON, FromJSON)

instance ToNamedRecord Card
instance FromNamedRecord Card
