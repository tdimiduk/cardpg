{-# LANGUAGE TemplateHaskell #-}
{-# LANGUAGE ScopedTypeVariables #-}
module CardPG.Core.RichText
  ( TextStyle(..)
  , Inline(..)
  , RichText(..)
  , RichString(..)
  , mkRichString
  , unRichString
  , Block(..)
  , CardBody
  , StackPower(..)
  , unsafeSimpleString
  , simpleString
  )
  where

import Data.Aeson (ToJSON(..), FromJSON(..), Value(..))
import Data.Aeson.TH (deriveJSON)
import qualified Data.List.NonEmpty as NE
import Data.Text (Text)
import qualified Data.Text as T
import GHC.Generics (Generic)

import CardPG.Core.Json
import CardPG.Core.Types (StackPower(..), Difficulty)
import CardPG.Core.NonEmptyText (NonEmptyText, unsafeNonEmptyText, mkNonEmptyText, getNonEmptyText)

-- | 1. The Token Stream
-------------------------------------------------------------------------------

data TextStyle
  = Bold
  | Italic
  | GameKeyword  -- ^ For "Resolve:", "Setup:", etc.
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
      { _style   :: Maybe TextStyle
      , _content :: NonEmptyText
      }
  | ColorValue 
      { _value :: StackPower 
      }
  | DifficultyValue
      { _difficulty :: Difficulty
      }
  | Break
  deriving stock (Eq, Show, Generic)

$(deriveJSON cardpgJsonDef ''Inline)



-- | Smart constructor that merges adjacent TextRuns with the same style
-- | and strips leading/trailing whitespace from the entire RichString.
-- | MOVED BELOW RichString to avoid scope issues if any (though usually not needed in Haskell, TH might be picky)

-- | The Base Machine Type (Always an Array)
newtype RichText = RichText { unRichText :: NE.NonEmpty Inline }
  deriving stock (Eq, Show, Generic)

$(deriveJSON cardpgJsonDef ''RichText)

instance Semigroup RichText where
  (RichText a) <> (RichText b) = 
    RichText $ NE.fromList $ mergeAdjacent (NE.toList a ++ NE.toList b)

-- | The Human Wrapper (Supports "String" or Array)
newtype RichString = RichString { unRichString :: RichText }
  deriving stock (Eq, Show, Generic)

-- | Smart constructor that merges adjacent TextRuns with the same style
-- | and strips leading/trailing whitespace from the entire RichString.
mkRichString :: [Inline] -> Maybe RichString
mkRichString inlines = 
  let merged = mergeAdjacent inlines
      stripped = stripBoundaryWhitespace merged
  in (RichString . RichText) <$> NE.nonEmpty stripped

mergeAdjacent :: [Inline] -> [Inline]
mergeAdjacent (TextRun s1 c1 : TextRun s2 c2 : xs)
  | s1 == s2 = mergeAdjacent (TextRun s1 (c1 <> c2) : xs)
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
    stripStart (TextRun s c : xs) =
      let strippedText = T.stripStart (getNonEmptyText c)
      in case mkNonEmptyText strippedText of
           Nothing -> stripStart xs
           Just c' -> TextRun s c' : xs
    stripStart xs = xs

-- | Unsafe constructor for literals. 
-- | Assumes the text is non-empty and does not require stripping/merging.
unsafeSimpleString :: Text -> RichString
unsafeSimpleString t = RichString $ RichText (TextRun Nothing (unsafeNonEmptyText t) NE.:| [])

-- | Safe constructor that attempts to create a RichString from Text.
-- | Returns Nothing if the text is empty or whitespace-only after stripping.
simpleString :: Text -> Maybe RichString
simpleString t = mkRichString [TextRun Nothing (unsafeNonEmptyText t)]

instance ToJSON RichString where
  toJSON (RichString (RichText (TextRun Nothing t NE.:| []))) = toJSON (getNonEmptyText t)
  toJSON (RichString rs) = toJSON rs
  
  toEncoding (RichString (RichText (TextRun Nothing t NE.:| []))) = toEncoding (getNonEmptyText t)
  toEncoding (RichString rs) = toEncoding rs

instance FromJSON RichString where
  parseJSON v = case v of
    String t -> case simpleString t of
      Just rs -> pure rs
      Nothing -> fail "RichString cannot be empty or whitespace only"
    _ -> do
      RichText inlines <- parseJSON v
      case mkRichString (NE.toList inlines) of
        Nothing -> fail "RichString cannot be empty or whitespace only"
        Just rs -> pure rs


instance Semigroup RichString where
  (RichString a) <> (RichString b) = RichString (a <> b)

-- | 2. The Layout Structure
-------------------------------------------------------------------------------

data Block
  = Paragraph RichString
  | Header RichString
  | Rule                    -- ^ <hr />
  | BulletList [RichString] -- ^ <ul><li>...</li></ul>
  deriving stock (Eq, Show, Generic)

$(deriveJSON cardpgJsonDef ''Block)

type CardBody = [Block]



