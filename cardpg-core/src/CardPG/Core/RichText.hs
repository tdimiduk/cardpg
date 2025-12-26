module CardPG.Core.RichText
  ( TextStyle (..)
  , Inline (..)
  , RichText (..)
  , getInlines
  , mkRichText
  , Block (..)
  , CardBody
  , StackPower (..)
  , unsafeSimpleString
  , simpleString
  )
where

import Data.Aeson (FromJSON (..), ToJSON (..), Value (..))
import Data.Aeson.TH (deriveJSON)
import Data.List.NonEmpty qualified as NE
import Data.Text (Text)
import Data.Text qualified as T
import GHC.Generics (Generic)

import CardPG.Core.Json
import CardPG.Core.NonEmptyText (NonEmptyText, getRawText, mkNonEmptyText, unsafeNonEmptyText)
import CardPG.Core.Primitives (Difficulty, StackPower (..))

-- | 1. The Token Stream

-------------------------------------------------------------------------------

data TextStyle
  = Bold
  | Italic
  | -- | For "Resolve:", "Setup:", etc.
    GameKeyword
  deriving stock (Eq, Show, Generic)

$(deriveJSON cardpgJsonDef ''TextStyle)

-- | Payload for Color Values (Icons or Dynamic Values)
-- | We use inline records in Inline now, but keeping these for backward compat if needed
-- | or we can just remove them. The plan says remove them.
-- | Let's remove TextRunDef and ColorValueDef and put fields directly in Inline.

-- | The Main Inline Sum Type
-- | Refactored to use inline records for standard JSON derivation.
data Inline
  = TextRun
      { style :: Maybe TextStyle
      , content :: NonEmptyText
      }
  | ColorValue
      { value :: StackPower
      }
  | DifficultyValue
      { difficulty :: Difficulty
      }
  | Break
  deriving stock (Eq, Show, Generic)

$(deriveJSON cardpgJsonDef ''Inline)

-- | The Base Machine Type (Always an Array)
newtype RichText = RichText {inlines :: NE.NonEmpty Inline}
  deriving stock (Eq, Show, Generic)

getInlines :: RichText -> NE.NonEmpty Inline
getInlines (RichText x) = x

-- | Smart constructor that merges adjacent TextRuns with the same style
-- | and strips leading/trailing whitespace from the entire RichText.
mkRichText :: [Inline] -> Maybe RichText
mkRichText inlines =
  let merged = mergeAdjacent inlines
      stripped = stripBoundaryWhitespace merged
   in RichText <$> NE.nonEmpty stripped

mergeAdjacent :: [Inline] -> [Inline]
mergeAdjacent (TextRun s1 c1 : TextRun s2 c2 : xs)
  | s1 == s2 = mergeAdjacent (TextRun s1 (c1 <> c2) : xs)
mergeAdjacent (x : xs) = x : mergeAdjacent xs
mergeAdjacent [] = []

stripBoundaryWhitespace :: [Inline] -> [Inline]
stripBoundaryWhitespace [] = []
stripBoundaryWhitespace inlines =
  let withoutLeading = stripStart inlines
      withoutTrailing = reverse (stripStart (reverse withoutLeading))
   in withoutTrailing
  where
    stripStart [] = []
    stripStart (TextRun s c : xs) =
      let strippedText = T.stripStart (getRawText c)
       in case mkNonEmptyText strippedText of
            Nothing -> stripStart xs
            Just c' -> TextRun s c' : xs
    stripStart xs = xs

-- | Unsafe constructor for literals.
-- | Assumes the text is non-empty and does not require stripping/merging.
unsafeSimpleString :: Text -> RichText
unsafeSimpleString t = RichText (TextRun Nothing (unsafeNonEmptyText t) NE.:| [])

-- | Safe constructor that attempts to create a RichText from Text.
-- | Returns Nothing if the text is empty or whitespace-only after stripping.
simpleString :: Text -> Maybe RichText
simpleString t = mkRichText [TextRun Nothing (unsafeNonEmptyText t)]

instance ToJSON RichText where
  toJSON (RichText rs) = toJSON rs
  toEncoding (RichText rs) = toEncoding rs

instance FromJSON RichText where
  parseJSON v = case v of
    String t -> case simpleString t of
      Just rs -> pure rs
      Nothing -> fail "RichText cannot be empty or whitespace only"
    _ -> do
      -- Parse as a list of Inlines (default for newtype with unwrapUnaryRecords=True or just list?)
      -- Wait, RichText is a newtype around NonEmpty Inline.
      -- If we use genericParseJSON with unwrap, it expects the inner type.
      -- Inner type is NonEmpty Inline. Array of Inlines.
      inlines <- parseJSON v
      case mkRichText (NE.toList inlines) of
        Nothing -> fail "RichText cannot be empty or whitespace only"
        Just rs -> pure rs

instance Semigroup RichText where
  (RichText a) <> (RichText b) =
    RichText $ NE.fromList $ mergeAdjacent (NE.toList a ++ NE.toList b)

-- | 2. The Layout Structure

-------------------------------------------------------------------------------

data Block
  = Paragraph RichText
  | Header RichText
  | -- | <hr />
    Rule
  | -- | <ul><li>...</li></ul>
    BulletList [RichText]
  deriving stock (Eq, Show, Generic)

$(deriveJSON cardpgJsonDef ''Block)

type CardBody = [Block]
