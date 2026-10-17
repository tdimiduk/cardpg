{-# LANGUAGE OverloadedRecordDot #-}
{-# LANGUAGE OverloadedStrings #-}

module Core.Time
  ( TimeUnit (..)
  , Duration (..)
  , durationParser
  , timeUnitParser
  , canonicalDurationText
  , toMinutes
  , fromMinutes
  , addDuration
  , scaleDuration
  ) where

import Data.Aeson (FromJSON (..), ToJSON (..), Value (..))
import Data.Text (Text)
import GHC.Generics (Generic)
import Text.Megaparsec (choice, try)
import Text.Megaparsec.Char (string')
import Text.Megaparsec.Char.Lexer (decimal)

import Core.DSL (Parser, TextRep (..), hspace, parseText, tryChoice)
import Core.Util (tshow)

data TimeUnit = Minute | Hour | Day
  deriving stock (Eq, Ord, Show, Enum, Bounded, Generic)

data Duration = Duration
  { value :: Int
  , unit :: TimeUnit
  }
  deriving stock (Eq, Show, Generic)

instance Ord Duration where
  compare d1 d2 =
    case compare (toMinutes d1) (toMinutes d2) of
      EQ -> compare d1.unit d2.unit
      other -> other

toMinutes :: Duration -> Int
toMinutes (Duration v Minute) = v
toMinutes (Duration v Hour) = v * 60
toMinutes (Duration v Day) = v * 1440

fromMinutes :: Int -> Duration
fromMinutes m
  | m > 0 && m `mod` 1440 == 0 = Duration (m `div` 1440) Day
  | m > 0 && m `mod` 60 == 0 = Duration (m `div` 60) Hour
  | otherwise = Duration m Minute

addDuration :: Duration -> Duration -> Duration
addDuration d1 d2
  | d1.unit == d2.unit = Duration (d1.value + d2.value) d1.unit
  | otherwise = fromMinutes (toMinutes d1 + toMinutes d2)

scaleDuration :: Int -> Duration -> Duration
scaleDuration factor (Duration v u) = Duration (factor * v) u

canonicalDurationText :: Duration -> Text
canonicalDurationText (Duration v Minute) = tshow v <> " min"
canonicalDurationText (Duration 1 Hour) = "1 hour"
canonicalDurationText (Duration v Hour) = tshow v <> " hours"
canonicalDurationText (Duration 1 Day) = "1 day"
canonicalDurationText (Duration v Day) = tshow v <> " days"

timeUnitParser :: Parser TimeUnit
timeUnitParser =
  tryChoice
    [ Minute
        <$ try (choice [string' "minutes", string' "minute", string' "mins", string' "min", string' "m"])
    , Hour <$ try (choice [string' "hours", string' "hour", string' "hrs", string' "hr", string' "h"])
    , Day <$ try (choice [string' "days", string' "day", string' "d"])
    ]

durationParser :: Parser Duration
durationParser = do
  hspace
  v <- decimal
  hspace
  u <- timeUnitParser
  hspace
  pure $ Duration v u

instance TextRep Duration where
  toText = canonicalDurationText
  textParser = durationParser

instance ToJSON Duration where
  toJSON = String . toText

instance FromJSON Duration where
  parseJSON (String t) = case parseText t of
    Right d -> pure d
    Left err -> fail $ "Duration DSL parse failed: " ++ err
  parseJSON (Number n) = pure $ Duration (round n) Minute
  parseJSON v = fail $ "Expected String or Number for Duration, got " ++ show v
