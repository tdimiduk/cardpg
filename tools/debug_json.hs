{- cabal:
build-depends: base, aeson, bytestring, text, vector
-}
{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE DeriveGeneric #-}
{-# LANGUAGE TemplateHaskell #-}

module Main where

import Data.Aeson
import Data.Aeson.TH
import qualified Data.ByteString.Lazy.Char8 as BL
import GHC.Generics
import Data.Text (Text)
import Data.Char (toLower)
import Data.List (stripPrefix)
import Data.Maybe (fromMaybe)

-- Inlined from CardPG.Core.Json
cardpgJsonOptions :: String -> Options
cardpgJsonOptions prefixToStrip =
  defaultOptions
    { constructorTagModifier = lowerFirst . stripPrefix' prefixToStrip
    , -- \| TS Discrimination: { "type": "attack", ... }
      sumEncoding =
        TaggedObject
          { tagFieldName = "type"
          , contentsFieldName = "data"
          }
    , -- \| TS Optionality: { "cost": 2 } vs {} (instead of { "cost": null })
      omitNothingFields = True
    , -- \| Unwrap single-field records so we don't get { "data": { "power": ... } }
      -- \| when { "power": ... } would suffice.
      unwrapUnaryRecords = False
    }
  where
    lowerFirst (x : xs) = toLower x : xs
    lowerFirst [] = []

    stripPrefix' pre s = fromMaybe s (stripPrefix pre s)

cardpgJsonDef :: Options
cardpgJsonDef = cardpgJsonOptions ""

-- Replicate Types
data AdminCommand
  = ResetGame
  deriving (Show, Eq, Generic)

$(deriveJSON cardpgJsonDef ''AdminCommand)

data ClientMessage
  = Admin {adminCommand :: AdminCommand}
  deriving (Show, Generic)

$(deriveJSON cardpgJsonDef ''ClientMessage)

main :: IO ()
main = do
    let jsonStr = "{\"type\":\"admin\",\"adminCommand\":{\"type\":\"resetGame\"}}"
    putStrLn $ "Trying to decode: " ++ jsonStr
    let decoded = decode (BL.pack jsonStr) :: Maybe ClientMessage
    print decoded
    
    putStrLn "Encoding ResetGame:"
    BL.putStrLn (encode ResetGame)

    putStrLn "Encoding Admin ResetGame:"
    BL.putStrLn (encode (Admin ResetGame))
