module Core.Json
  ( cardpgJsonOptions
  , cardpgJsonDef
  , stripEmpty
  ) where

import Data.Aeson (Options (..), Value (..), defaultOptions)
import Data.Aeson.KeyMap qualified as KM
import Data.Char (toLower)
import Data.List (stripPrefix)
import Data.Maybe (fromMaybe)
import Data.Vector qualified as V

-- | Standard JSON Options for the CardPG Engine.
-- | Goal: Producing clean, idiomatic JSON for TypeScript clients.
cardpgJsonOptions :: String -> Options
cardpgJsonOptions prefixToStrip =
  defaultOptions
    { constructorTagModifier = lowerFirst . stripPrefix' prefixToStrip
    , omitNothingFields = True
    }
  where
    lowerFirst (x : xs) = toLower x : xs
    lowerFirst [] = []

    stripPrefix' pre s = fromMaybe s (stripPrefix pre s)

cardpgJsonDef :: Options
cardpgJsonDef = cardpgJsonOptions ""

-- | Recursively strip empty arrays and nulls from JSON Values
stripEmpty :: Value -> Value
stripEmpty (Object m) = Object $ KM.map stripEmpty $ KM.filter (not . isEmpty) m
  where
    isEmpty (Array v) = V.null v
    isEmpty (String s) = s == ""
    isEmpty Null = True
    isEmpty _ = False
stripEmpty (Array v) = Array $ V.map stripEmpty v
stripEmpty v = v
