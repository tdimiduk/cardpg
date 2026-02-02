module Core.Json
  ( cardpgJsonOptions
  , cardpgJsonDef
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
ardpgJsonDef = cardpgJsonOptions ""
