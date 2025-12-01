module CardPG.Core.RichText
  ( TextStyle(..)
  , Inline(..)
  , RichString
  , mkRichString
  , unRichString
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
import qualified Data.List.NonEmpty as NE
import Data.Text (Text)
import GHC.Generics (Generic)

import CardPG.Core.Json
import CardPG.Core.Types (ResourceType(..))
import CardPG.Core.NonEmptyText (NonEmptyText, unsafeNonEmptyText)

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
  , _content :: NonEmptyText
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


newtype RichString = RichString { unRichString :: NE.NonEmpty Inline }
  deriving stock (Eq, Show, Generic)

instance ToJSON RichString where
  toJSON = toJSON . unRichString
  toEncoding = toEncoding . unRichString

instance FromJSON RichString where
  parseJSON v = mkRichString <$> parseJSON v

instance Semigroup RichString where
  (RichString a) <> (RichString b) = mkRichString (a <> b)

-- | Smart constructor that merges adjacent TextRuns with the same style
mkRichString :: NE.NonEmpty Inline -> RichString
mkRichString = RichString . NE.fromList . mergeAdjacent . NE.toList

mergeAdjacent :: [Inline] -> [Inline]
mergeAdjacent (TextRun (TextRunDef s1 c1) : TextRun (TextRunDef s2 c2) : xs)
  | s1 == s2 = mergeAdjacent (TextRun (TextRunDef s1 (c1 <> c2)) : xs)
mergeAdjacent (x:xs) = x : mergeAdjacent xs
mergeAdjacent [] = []

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
simpleString t = mkRichString (TextRun (TextRunDef Nothing (unsafeNonEmptyText t)) NE.:| [])
