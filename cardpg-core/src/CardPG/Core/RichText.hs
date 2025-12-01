module CardPG.Core.RichText
  ( TextStyle(..)
  , Inline(..)
  , RichString
  , mkRichString
  , unRichString
  , Block(..)
  , CardBody
  , StackPower(..)
  , unsafeSimpleString
  , simpleString
  , TextRunDef(..)
  , ColorValueDef(..)
  )
  where

import Data.Aeson (ToJSON(..), FromJSON(..), genericToJSON, genericToEncoding, genericParseJSON, Value(..), object, (.=), (.:), withObject, Options(..))
import qualified Data.Aeson.KeyMap as KM
import qualified Data.Aeson.Key as Key
import qualified Data.List.NonEmpty as NE
import Data.Text (Text)
import qualified Data.Text as T
import GHC.Generics (Generic)

import CardPG.Core.Json
import CardPG.Core.Types (StackPower(..))
import CardPG.Core.NonEmptyText (NonEmptyText, unsafeNonEmptyText, mkNonEmptyText, getNonEmptyText)

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

-- | Payload for Color Values (Icons or Dynamic Values)
data ColorValueDef = ColorValueDef
  { _value :: StackPower 
  } deriving stock (Eq, Show, Generic)

instance ToJSON ColorValueDef where
  toJSON     = genericToJSON safeInlineOptions
  toEncoding = genericToEncoding safeInlineOptions
instance FromJSON ColorValueDef where
  parseJSON = genericParseJSON safeInlineOptions

-- | The Main Inline Sum Type
-- | No partial fields here; just wrappers around safe types.
data Inline
  = TextRun TextRunDef
  | ColorValue ColorValueDef
  | Break
  deriving stock (Eq, Show, Generic)

instance ToJSON Inline where
  toJSON (TextRun d) = addType "textRun" (toJSON d)
  toJSON (ColorValue d) = addType "colorValue" (toJSON d)
  toJSON Break = object ["type" .= ("break" :: Text)]

addType :: Text -> Value -> Value
addType t (Object o) = Object (KM.insert (Key.fromText "type") (String t) o)
addType _ v = v

instance FromJSON Inline where
  parseJSON = withObject "Inline" $ \o -> do
    t <- o .: "type"
    case (t :: Text) of
      "textRun" -> TextRun <$> parseJSON (Object o)
      "colorValue" -> ColorValue <$> parseJSON (Object o)
      "break" -> pure Break
      _ -> fail $ "Unknown Inline type: " ++ show t


newtype RichString = RichString { unRichString :: NE.NonEmpty Inline }
  deriving stock (Eq, Show, Generic)

instance ToJSON RichString where
  toJSON = toJSON . unRichString
  toEncoding = toEncoding . unRichString

instance FromJSON RichString where
  parseJSON v = do
    inlines <- parseJSON v
    case mkRichString (NE.toList inlines) of
      Nothing -> fail "RichString cannot be empty or whitespace only"
      Just rs -> pure rs

instance Semigroup RichString where
  (RichString a) <> (RichString b) = 
    RichString $ NE.fromList $ mergeAdjacent (NE.toList a ++ NE.toList b)

-- | Smart constructor that merges adjacent TextRuns with the same style
-- | and strips leading/trailing whitespace from the entire RichString.
mkRichString :: [Inline] -> Maybe RichString
mkRichString inlines = 
  let merged = mergeAdjacent inlines
      stripped = stripBoundaryWhitespace merged
  in RichString <$> NE.nonEmpty stripped

mergeAdjacent :: [Inline] -> [Inline]
mergeAdjacent (TextRun (TextRunDef s1 c1) : TextRun (TextRunDef s2 c2) : xs)
  | s1 == s2 = mergeAdjacent (TextRun (TextRunDef s1 (c1 <> c2)) : xs)
mergeAdjacent (x:xs) = x : mergeAdjacent xs
mergeAdjacent [] = []

stripBoundaryWhitespace :: [Inline] -> [Inline]
stripBoundaryWhitespace [] = []
stripBoundaryWhitespace inlines = 
  let withoutLeading = stripStart inlines
      withoutTrailing = reverse (stripStart (reverse withoutLeading))
  in withoutTrailing
  where
    stripStart [] = []
    stripStart (TextRun (TextRunDef s c) : xs) =
      let strippedText = T.stripStart (getNonEmptyText c)
      in case mkNonEmptyText strippedText of
           Nothing -> stripStart xs
           Just c' -> TextRun (TextRunDef s c') : xs
    stripStart xs = xs

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


-- | Unsafe constructor for literals. 
-- | Assumes the text is non-empty and does not require stripping/merging.
unsafeSimpleString :: Text -> RichString
unsafeSimpleString t = RichString (TextRun (TextRunDef Nothing (unsafeNonEmptyText t)) NE.:| [])

-- | Safe constructor that attempts to create a RichString from Text.
-- | Returns Nothing if the text is empty or whitespace-only after stripping.
simpleString :: Text -> Maybe RichString
simpleString t = mkRichString [TextRun (TextRunDef Nothing (unsafeNonEmptyText t))]
