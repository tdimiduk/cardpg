module CardPG.Core.Json
  ( cardpgJsonOptions
  , cardpgJsonDef
  , cardpgTaggedOptions
  , stripEmpty
  ) where

import Data.Aeson (Options(..), defaultOptions, SumEncoding(..), Value(..))
import qualified Data.Aeson.KeyMap as KM
import Data.Char (toLower)
import Data.List (stripPrefix)
import Data.Maybe (fromMaybe)
import qualified Data.Vector as V

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

-- | Options that force a "type" tag even for single constructors.
-- | Useful for CoreCard/ItemCard to be discriminated unions.
cardpgTaggedOptions :: String -> Options
cardpgTaggedOptions prefixToStrip = (cardpgJsonOptions prefixToStrip)
  { tagSingleConstructors = True
  }

-- | Recursively strip empty arrays and nulls from JSON Values
stripEmpty :: Value -> Value
stripEmpty (Object m) = Object $ KM.map stripEmpty $ KM.filter (not . isEmpty) m
  where
    isEmpty (Array v) = V.null v
    isEmpty (String s) = s == ""
    isEmpty Null      = True
    isEmpty _         = False
stripEmpty (Array v) = Array $ V.map stripEmpty v
stripEmpty v = v
