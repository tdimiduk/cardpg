module Core.Stats
  ( getStat
  , getStatValue
  , parseCanonicalResourceName
  , parseStatValue
  , resourceSymbol
  , stackPowerParser
  , difficultyParser
  , ResourceType (..)
  , StatValue (..)
  , Stats (..)
  , StackPower (..)
  , Difficulty (..)
  , prettyModifier
  , toTextResourceType
  ) where

import Core.Language (kwCheck, kwStrength, sepColon)

import Control.Applicative (optional, (<|>))
import Data.Maybe (fromMaybe)

import Data.Aeson
  ( FromJSON (..)
  , ToJSON (..)
  , Value (..)
  , genericParseJSON
  , genericToJSON
  )
import Data.Aeson.TH (deriveJSON)
import Data.Text (Text)
import Data.Text qualified as T
import GHC.Generics (Generic)
import Text.Megaparsec
  ( between
  , notFollowedBy
  , takeWhileP
  , try
  )
import Text.Megaparsec.Char (char, space, string, string')
import Text.Megaparsec.Char.Lexer (decimal)

import Core.DSL
  ( Parser
  , TextRep (..)
  , hspace
  , hspace1
  , mkEnumParser
  , parseText
  , tryChoice
  )
import Core.Json (cardpgJsonDef)
import Core.Util (tshow)

data ResourceType = Red | Yellow | Blue
  deriving stock (Eq, Ord, Show, Enum, Bounded, Generic)

$(deriveJSON cardpgJsonDef ''ResourceType)

data Stats a = Stats
  { red :: a
  , yellow :: a
  , blue :: a
  }
  deriving stock (Eq, Show, Generic, Functor, Foldable, Traversable)

instance (ToJSON a) => ToJSON (Stats a) where
  toJSON = genericToJSON cardpgJsonDef

instance (FromJSON a) => FromJSON (Stats a) where
  parseJSON = genericParseJSON cardpgJsonDef

instance (Semigroup a) => Semigroup (Stats a) where
  Stats r1 y1 b1 <> Stats r2 y2 b2 = Stats (r1 <> r2) (y1 <> y2) (b1 <> b2)

instance (Monoid a) => Monoid (Stats a) where
  mempty = Stats mempty mempty mempty

parseCanonicalResourceName :: Parser ResourceType
parseCanonicalResourceName = mkEnumParser tshow

parseStatValue :: Parser StatValue
parseStatValue = between (char '{') (char '}') $ do
  color <- parseCanonicalResourceName
  _ <- string sepColon
  _ <- space
  value <- decimal
  pure $ StatValue{..}

getStat :: ResourceType -> Stats a -> a
getStat Red = (.red)
getStat Yellow = (.yellow)
getStat Blue = (.blue)

getStatValue :: ResourceType -> Stats Int -> StatValue
getStatValue c s = StatValue (getStat c s) c

data StatValue = StatValue
  { value :: Int
  , color :: ResourceType
  }
  deriving stock (Eq, Show, Generic)

instance TextRep StatValue where
  toText s = "{" <> tshow s.color <> sepColon <> " " <> tshow s.value <> "}"
  textParser = parseStatValue

instance ToJSON StatValue where
  toJSON = String . toText

instance FromJSON StatValue where
  parseJSON (String t) = case parseText t of
    Right r -> pure r
    Left err -> fail $ "StatValue DSL parse failed: " ++ err
  parseJSON v = genericParseJSON cardpgJsonDef v

data StackPower = StackPower
  { source :: ResourceType
  , modifier :: Int
  , conditional :: Maybe Text
  }
  deriving stock (Eq, Show, Generic)

instance TextRep StackPower where
  toText (StackPower s m c) =
    let base = "Strength " <> toTextResourceType s
        modTxt = if m /= 0 then " " <> prettyModifier m else ""
        condTxt = maybe "" (" " <>) c
     in base <> modTxt <> condTxt
  textParser = stackPowerParser

instance ToJSON StackPower where
  toJSON = String . toText

instance FromJSON StackPower where
  parseJSON (String t) = case parseText t of
    Right r -> pure r
    Left err -> fail $ "StackPower DSL parse failed: " ++ err
  parseJSON v = genericParseJSON cardpgJsonDef v

prettyModifier :: Int -> Text
prettyModifier n
  | n == 0 = ""
  | n >= 0 = "+ " <> tshow n
  | otherwise = "- " <> tshow (abs n)
data Difficulty = Difficulty
  { attribute :: ResourceType
  , value :: Int
  }
  deriving stock (Eq, Show, Generic)

instance TextRep Difficulty where
  toText (Difficulty a v) = "Check " <> toTextResourceType a <> " " <> tshow v
  textParser = difficultyParser

instance ToJSON Difficulty where
  toJSON = String . toText

instance FromJSON Difficulty where
  parseJSON (String t) = case parseText t of
    Right r -> pure r
    Left err -> fail $ "Difficulty DSL parse failed: " ++ err
  parseJSON v = genericParseJSON cardpgJsonDef v

toTextResourceType :: ResourceType -> Text
toTextResourceType Red = "{Red}"
toTextResourceType Yellow = "{Yellow}"
toTextResourceType Blue = "{Blue}"

-- Parsers moved from RuleParser.hs

between' :: Parser a -> Parser b -> Parser b
between' p = between p p

resourceSymbol :: Parser ResourceType
resourceSymbol = tryChoice [canonicalResource, shorthandResource, legacyResource]

canonicalResource :: Parser ResourceType
canonicalResource = between (char '{') (char '}') parseCanonicalResourceName

shorthandResource :: Parser ResourceType
shorthandResource = mkEnumParser (T.take 1 . tshow)

legacyResource :: Parser ResourceType
legacyResource = between' (char '|') $ mkEnumParser toLegacy
  where
    toLegacy Red = "x"
    toLegacy Yellow = "y"
    toLegacy Blue = "z"

stackPowerParser :: Parser StackPower
stackPowerParser = do
  _ <- optional $ try $ do
    _ <- string' kwStrength <|> string' "str"
    _ <- hspace1
    _ <- optional (char '=')
    hspace
  base <- resourceSymbol
  _ <- hspace
  modVal <- optional $ try $ do
    sign <- (id <$ char '+') <|> (negate <$ char '-')
    _ <- hspace
    sign <$> decimal
  _ <- hspace
  conditional <- optional $ try $ do
    _ <- char '('
    notFollowedBy (string "Cost:")
    content <- takeWhileP Nothing (/= ')')
    _ <- char ')'
    pure $ "(" <> content <> ")"
  _ <- hspace -- Consume trailing hspace
  pure $ StackPower base (fromMaybe 0 modVal) conditional

difficultyParser :: Parser Difficulty
difficultyParser = do
  _ <- optional $ try $ do
    _ <- string' kwCheck <|> string' "Diff"
    _ <- hspace1
    _ <- optional (char '=')
    hspace
  base <- resourceSymbol
  _ <- hspace
  Difficulty base <$> decimal
