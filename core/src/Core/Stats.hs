module Core.Stats
  ( getStat
  , getStatValue
  , parseCanonicalResourceName
  , parseStatValue
  , ResourceType (..)
  , StatValue (..)
  , Stats (..)
  , StackPower (..)
  , Difficulty (..)
  , prettyModifier
  ) where

import Core.Language (sepColon)

import Data.Aeson
  ( FromJSON (..)
  , ToJSON (..)
  , Value (..)
  , genericParseJSON
  , genericToJSON
  )
import Data.Aeson.TH (deriveJSON)
import Data.Text (Text)
import GHC.Generics (Generic)
import Text.Megaparsec
  ( between
  )
import Text.Megaparsec.Char (char, space, string)
import Text.Megaparsec.Char.Lexer (decimal)

import Core.Json (cardpgJsonDef)
import Core.Parser (Parser, basicParse, mkEnumParser)
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

instance ToJSON StatValue where
  toJSON v = String $ "{" <> tshow v.color <> ":" <> tshow v.value <> "}"

instance FromJSON StatValue where
  parseJSON (String t) = case basicParse parseStatValue t of
    Right r -> pure r
    Left err -> fail $ "DSL parse failed: " ++ err
  parseJSON v = genericParseJSON cardpgJsonDef v

data StackPower = StackPower
  { source :: ResourceType
  , modifier :: Int
  , conditional :: Maybe Text
  }
  deriving stock (Eq, Show, Generic)

$(deriveJSON cardpgJsonDef ''StackPower)

data Difficulty = Difficulty
  { attribute :: ResourceType
  , value :: Int
  }
  deriving stock (Eq, Show, Generic)

$(deriveJSON cardpgJsonDef ''Difficulty)

prettyModifier :: Int -> Text
prettyModifier n
  | n == 0 = ""
  | n >= 0 = "+ " <> tshow n
  | otherwise = "- " <> tshow (abs n)
