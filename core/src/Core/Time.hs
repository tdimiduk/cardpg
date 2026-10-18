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
  , ExpeditionTime (..)
  , expeditionDay
  , expeditionHour
  , expeditionMinute
  , formatExpeditionTime
  , addMinutes
  , addExpeditionDuration
  , clockTicksCrossed
  , expeditionTimeParser
  ) where

import Control.Applicative ((<|>))
import Data.Aeson (FromJSON (..), ToJSON (..), Value (..), withObject, (.:), (.:?))
import Data.Text (Text)
import Data.Text qualified as T
import GHC.Generics (Generic)
import Text.Megaparsec (choice, try)
import Text.Megaparsec.Char (char, string')
import Text.Megaparsec.Char.Lexer (decimal)
import Text.Read (readMaybe)

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

--------------------------------------------------------------------------------
-- Expedition Chronometer Time
--------------------------------------------------------------------------------

newtype ExpeditionTime = ExpeditionTime {totalMinutes :: Int}
  deriving stock (Eq, Ord, Show, Generic)

expeditionDay :: ExpeditionTime -> Int
expeditionDay (ExpeditionTime m) = (m `div` 1440) + 1

expeditionHour :: ExpeditionTime -> Int
expeditionHour (ExpeditionTime m) = (m `mod` 1440) `div` 60

expeditionMinute :: ExpeditionTime -> Int
expeditionMinute (ExpeditionTime m) = m `mod` 60

formatExpeditionTime :: ExpeditionTime -> Text
formatExpeditionTime t =
  let d = expeditionDay t
      h = expeditionHour t
      m = expeditionMinute t
      pad2 n = if n < 10 then "0" <> tshow n else tshow n
   in "Day " <> tshow d <> ", " <> pad2 h <> ":" <> pad2 m

addMinutes :: Int -> ExpeditionTime -> ExpeditionTime
addMinutes delta (ExpeditionTime m) = ExpeditionTime (m + delta)

addExpeditionDuration :: Duration -> ExpeditionTime -> ExpeditionTime
addExpeditionDuration dur (ExpeditionTime m) = ExpeditionTime (m + toMinutes dur)

clockTicksCrossed :: ExpeditionTime -> Duration -> Duration -> Int
clockTicksCrossed (ExpeditionTime startMin) delta interval =
  let d = toMinutes delta
      i = toMinutes interval
   in if i <= 0 then 0 else (startMin + d) `div` i - startMin `div` i

expeditionTimeParser :: Parser ExpeditionTime
expeditionTimeParser = try dayFormat <|> try hhmmFormat <|> (ExpeditionTime . toMinutes <$> durationParser)
  where
    dayFormat = do
      hspace
      _ <- string' "day"
      hspace
      d <- decimal
      hspace
      _ <- char ','
      hspace
      h <- decimal
      _ <- char ':'
      m <- decimal
      hspace
      pure $ ExpeditionTime ((d - 1) * 1440 + h * 60 + m)

    hhmmFormat = do
      hspace
      h <- decimal
      _ <- char ':'
      m <- decimal
      hspace
      pure $ ExpeditionTime (h * 60 + m)

instance TextRep ExpeditionTime where
  toText = formatExpeditionTime
  textParser = expeditionTimeParser

instance ToJSON ExpeditionTime where
  toJSON = String . formatExpeditionTime

instance FromJSON ExpeditionTime where
  parseJSON (String t) = case parseText t of
    Right et -> pure et
    Left _ ->
      case readMaybe (T.unpack t) of
        Just n -> pure $ ExpeditionTime n
        Nothing -> fail $ "Could not parse ExpeditionTime from: " ++ T.unpack t
  parseJSON (Number n) = pure $ ExpeditionTime (round n)
  parseJSON (Object o) = do
    m <- o .: "total_minutes" <|> o .: "totalMinutes"
    pure $ ExpeditionTime m
  parseJSON v = fail $ "Expected String, Number, or Object for ExpeditionTime, got " ++ show v
