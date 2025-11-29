module CardPG.Core.RichText
  ( TextStyle(..)
  , Inline(..)
  , RichString
  , Block(..)
  , CardBody
  , StackPower(..)
  , simpleString
  , TextRunDef(..)
  , IconDef(..)
  , DynamicValDef(..) 
  )
  where

import Data.Aeson (ToJSON(..), FromJSON(..), genericToJSON, genericToEncoding, genericParseJSON, Value(..), object, (.=), (.:), withObject, Options(..))
import qualified Data.Aeson.KeyMap as KM
import qualified Data.Aeson.Key as Key
import Data.Text (Text)
import GHC.Generics (Generic)

import CardPG.Core.Json
import CardPG.Core.Types (ResourceType(..))

data StackPower = StackPower
  { _source      :: ResourceType
  , _modifier    :: Int
  , _conditional :: Maybe Text
  }
  deriving stock (Eq, Show, Generic)

instance ToJSON StackPower where
  toJSON = genericToJSON cardpgJsonDef
  toEncoding = genericToEncoding cardpgJsonDef

instance FromJSON StackPower where
  parseJSON = genericParseJSON cardpgJsonDef


-- | 1. The Token Stream
-------------------------------------------------------------------------------

data TextStyle
  = Bold
  | Italic
  | GameKeyword  -- ^ For "Resolve:", "Setup:", etc.
  deriving stock (Eq, Show, Generic)

instance ToJSON TextStyle where
  toJSON = genericToJSON cardpgJsonDef
  toEncoding = genericToEncoding cardpgJsonDef

instance FromJSON TextStyle where
  parseJSON = genericParseJSON cardpgJsonDef

data TextRunDef = TextRunDef
  { _style   :: Maybe TextStyle
  , _content :: Text 
  } deriving stock (Eq, Show, Generic)

instance ToJSON TextRunDef where
  toJSON     = genericToJSON (cardpgJsonOptions "")
  toEncoding = genericToEncoding (cardpgJsonOptions "")
instance FromJSON TextRunDef where
  parseJSON = genericParseJSON (cardpgJsonOptions "")

-- | Options that don't unwrap unary records, so we can always add "type" to an object.
safeInlineOptions :: Options
safeInlineOptions = (cardpgJsonOptions "") { unwrapUnaryRecords = False }

-- | Payload for Icons
data IconDef = IconDef
  { _color   :: ResourceType 
  } deriving stock (Eq, Show, Generic)

instance ToJSON IconDef where
  toJSON     = genericToJSON safeInlineOptions
  toEncoding = genericToEncoding safeInlineOptions
instance FromJSON IconDef where
  parseJSON = genericParseJSON safeInlineOptions

-- | Payload for Dynamic Math
data DynamicValDef = DynamicValDef
  { _value   :: StackPower 
  } deriving stock (Eq, Show, Generic)

instance ToJSON DynamicValDef where
  toJSON     = genericToJSON safeInlineOptions
  toEncoding = genericToEncoding safeInlineOptions
instance FromJSON DynamicValDef where
  parseJSON = genericParseJSON safeInlineOptions

-- | The Main Inline Sum Type
-- | No partial fields here; just wrappers around safe types.
data Inline
  = TextRun TextRunDef
  | Icon IconDef
  | DynamicVal DynamicValDef
  | Break
  deriving stock (Eq, Show, Generic)

instance ToJSON Inline where
  toJSON (TextRun d) = addType "textRun" (toJSON d)
  toJSON (Icon d) = addType "icon" (toJSON d)
  toJSON (DynamicVal d) = addType "dynamicVal" (toJSON d)
  toJSON Break = object ["type" .= ("break" :: Text)]

addType :: Text -> Value -> Value
addType t (Object o) = Object (KM.insert (Key.fromText "type") (String t) o)
addType _ v = v

instance FromJSON Inline where
  parseJSON = withObject "Inline" $ \o -> do
    t <- o .: "type"
    case (t :: Text) of
      "textRun" -> TextRun <$> parseJSON (Object o)
      "icon" -> Icon <$> parseJSON (Object o)
      "dynamicVal" -> DynamicVal <$> parseJSON (Object o)
      "break" -> pure Break
      _ -> fail $ "Unknown Inline type: " ++ show t

-- | A list allows for Monoidal concatenation (text <> icon).
type RichString = [Inline]


-- | 2. The Layout Structure
-------------------------------------------------------------------------------

data Block
  = Paragraph RichString
  | Header RichString
  | Rule                    -- ^ <hr />
  | BulletList [RichString] -- ^ <ul><li>...</li></ul>
  deriving stock (Eq, Show, Generic)

instance ToJSON Block where
  toJSON = genericToJSON cardpgJsonDef
  toEncoding = genericToEncoding cardpgJsonDef

instance FromJSON Block where
  parseJSON = genericParseJSON cardpgJsonDef

type CardBody = [Block]

simpleString :: Text -> RichString
simpleString t = [TextRun (TextRunDef Nothing t)]
