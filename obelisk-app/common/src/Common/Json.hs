module Common.Json where

import Data.Aeson (Options(..), defaultOptions, SumEncoding(..))
import Data.Char (toLower)
import Data.List (stripPrefix)
import Data.Maybe (fromMaybe)

-- | Standard JSON Options for the CardPG Engine.
-- | Goal: Producing clean, idiomatic JSON for TypeScript clients.
cardpgJsonOptions :: String -> Options
cardpgJsonOptions prefixToStrip = defaultOptions
  { fieldLabelModifier = stripUnderscore
  , constructorTagModifier = lowerFirst . stripPrefix' prefixToStrip
  
  -- | TS Discrimination: { "type": "attack", ... }
  , sumEncoding = TaggedObject 
      { tagFieldName = "type"
      , contentsFieldName = "data" 
      }
  
  -- | TS Optionality: { "cost": 2 } vs {} (instead of { "cost": null })
  , omitNothingFields = True
  
  -- | Unwrap single-field records so we don't get { "data": { "power": ... } }
  -- | when { "power": ... } would suffice.
  , unwrapUnaryRecords = True
  }
  where
    stripUnderscore ('_':xs) = xs
    stripUnderscore xs       = xs

    lowerFirst (x:xs) = toLower x : xs
    lowerFirst []     = []

    stripPrefix' pre s = fromMaybe s (stripPrefix pre s)

cardpgJsonDef :: Options
cardpgJsonDef = cardpgJsonOptions ""
