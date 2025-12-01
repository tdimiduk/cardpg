{-# LANGUAGE DeriveGeneric #-}
{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE RecordWildCards #-}
{-# LANGUAGE DuplicateRecordFields #-}

module CardCompiler.VttExporter where

import Data.Aeson (ToJSON(..), FromJSON(..), genericToJSON, genericToEncoding, genericParseJSON, Value(..), object, (.=), (.:), withObject, Options(..))
import qualified Data.Aeson as Aeson
import qualified Data.Aeson.KeyMap as KM
import qualified Data.Aeson.Key as Key
import Data.Text (Text)
import qualified Data.Text as T
import qualified Data.Text.IO as TIO
import qualified Data.ByteString.Lazy as LBS
import GHC.Generics (Generic)
import System.FilePath (takeBaseName)
import Data.Maybe (fromMaybe)
import Control.Monad (forM)
import qualified Data.Yaml as Yaml
import Data.List.NonEmpty (NonEmpty)
import qualified Data.List.NonEmpty as NE

import CardPG.Core.Card (CoreCard(..), ItemCard(..), Rule(..), Stats(..), Actor(..))
import CardPG.Core.Json (cardpgJsonOptions)
import CardPG.Core.DSL.Parser (parseRule)
import CardPG.Core.NonEmptyText (getNonEmptyText, NonEmptyText)
import CardPG.Core.RichText (simpleString, RichString)

-- | Shadow Type for Rules to force structured JSON
newtype StructuredRule = StructuredRule { unStructuredRule :: Rule }
  deriving (Show, Generic)

instance ToJSON StructuredRule where
  toJSON (StructuredRule r) = genericToJSON (cardpgJsonOptions "Rule") r

-- | Shadow Type for CoreCard to use StructuredRule
data VttCoreCard = VttCoreCard
  { _id     :: Maybe Text
  , _name   :: Text
  , _tags   :: Maybe (NonEmpty Text)
  , _stats  :: Stats
  , _cost   :: Maybe Int
  , _rules  :: Maybe (NonEmpty StructuredRule)
  , _flavor :: Maybe RichString
  }
  deriving (Show, Generic)

instance ToJSON VttCoreCard where
  toJSON = genericToJSON (cardpgJsonOptions "CoreCard")

-- | VTT Actor Type
data VttActor = VttActor
  { _id    :: Text
  , _name  :: Text
  , _tags  :: [Text]
  , _items :: [ItemCard]
  , _deck  :: [VttCoreCard]
  }
  deriving (Show, Generic)

instance ToJSON VttActor where
  toJSON = genericToJSON (cardpgJsonOptions "Actor")

-- | Load and Export Function
loadAndExport :: [FilePath] -> FilePath -> IO ()
loadAndExport inputFiles outputFile = do
  allActors <- forM inputFiles $ \file -> do
    result <- Yaml.decodeFileEither file
    case result of
      Left err -> do
        putStrLn $ "Warning: Failed to parse " ++ file ++ ": " ++ show err
        return Nothing
      Right actor -> do
        return $ Just $ convertActor actor

  let validActors = [ a | Just a <- allActors ]
  LBS.writeFile outputFile (Aeson.encode validActors)
  putStrLn $ "Exported " ++ show (length validActors) ++ " actors to " ++ outputFile

-- | Convert Actor to VttActor
convertActor :: Actor -> VttActor
convertActor Actor{..} = VttActor
  { _id = slugify _name
  , _name = _name
  , _tags = maybe [] NE.toList _tags
  , _items = map ensureItemId _items
  , _deck = map toVttCoreCard _deck
  }

-- | Convert CoreCard to VttCoreCard
toVttCoreCard :: CoreCard -> VttCoreCard
toVttCoreCard CoreCard{..} = VttCoreCard
  { _id = Just $ fromMaybe (slugify (getNonEmptyText _name)) _id
  , _name = getNonEmptyText _name
  , _tags = _tags
  , _stats = _stats
  , _cost = _cost
  , _rules = fmap (fmap StructuredRule) _rules
  , _flavor = _flavor
  }

-- | Helper to ensure ItemCard has an ID
ensureItemId :: ItemCard -> ItemCard
ensureItemId item@ItemCard{..} = item { _id = Just $ fromMaybe (slugify (getNonEmptyText _name)) _id }

-- | Simple slugify
slugify :: Text -> Text
slugify = T.toLower . T.replace " " "-"
