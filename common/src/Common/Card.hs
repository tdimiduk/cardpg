{-# LANGUAGE DeriveAnyClass #-}
{-# LANGUAGE RecordWildCards #-}

module Common.Card where

import Control.Monad (mzero)
import Data.Aeson (ToJSON, FromJSON)
import Data.ByteString (ByteString)
import qualified Data.ByteString.Lazy as LBS
import Data.Csv (FromRecord, parseRecord, DecodeOptions(..), HasHeader(..), (.!), defaultDecodeOptions, decodeWith)
import Data.List.NonEmpty (NonEmpty)
import Data.Text (Text)
import qualified Data.Text.Encoding as T
import qualified Data.Vector as V
import GHC.Base (ord)
import GHC.Generics

data Card = Card
  { _actor :: Text
  , _name :: Text
  , _resources :: Resources
  , _cost :: Cost
  , _textbox :: Textbox
  }
  deriving stock (Show, Generic)
  deriving anyclass (ToJSON, FromJSON)

data Resources = Resources
  { _red :: Maybe Text
  , _yellow :: Maybe Text
  , _blue :: Maybe Text
  , _keywordProvide :: Maybe Text
  }
  deriving stock (Show, Generic)
  deriving anyclass (ToJSON, FromJSON)

data Cost = Cost
  { _cards :: Maybe Text
  , _keywordCost :: Maybe Text
  }
  deriving stock (Show, Generic)
  deriving anyclass (ToJSON, FromJSON)

data Textbox = Textbox
  { _action :: Maybe Action
  , _effect :: Maybe FancyText
  , _details :: Maybe FancyText
  }
  deriving stock (Show, Generic)
  deriving anyclass (ToJSON, FromJSON)

data ResourceType = Red | Yellow | Blue
  deriving stock (Show, Generic)
  deriving anyclass (ToJSON, FromJSON)

data Action = GeneralAction FancyText
  | Attack
    { _resistedBy :: ResourceType
    , _strengthBy :: ResourceType
    , _aMod :: Int
    , _aText :: Maybe Text
    }
  | StandardDefend
    { _resists :: NonEmpty ResourceType
    , _resistWith :: ResourceType
    , _dMod :: Int
    , _dText :: Maybe Text
    }
  | SpecialDefend Text
  deriving stock (Show, Generic)
  deriving anyclass (ToJSON, FromJSON)

data FancyToken = FancyTextToken Text | ResourceToken ResourceType
  deriving stock (Show, Generic)
  deriving anyclass (ToJSON, FromJSON)

data FancyText = FancyText [FancyToken]
  deriving stock (Show, Generic)
  deriving anyclass (ToJSON, FromJSON)

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

type InputDelimeter = DecodeOptions

csv :: InputDelimeter
csv = defaultDecodeOptions

tsv :: InputDelimeter
tsv = defaultDecodeOptions { decDelimiter = fromIntegral (ord '\t') }

readAdhocCards :: HasHeader -> DecodeOptions -> ByteString -> Either String (V.Vector AdhocCard)
readAdhocCards hasHeader options = decodeWith options hasHeader . LBS.fromStrict

