{-# LANGUAGE DataKinds #-}
{-# LANGUAGE FlexibleContexts #-}
{-# LANGUAGE FlexibleInstances #-}
{-# LANGUAGE MultiParamTypeClasses #-}
{-# LANGUAGE TypeFamilies #-}
{-# LANGUAGE UndecidableInstances #-}

module Core.RichText
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

import Core.Json
import Core.Language (TextStyle (..), styleDelimiter)
import Core.NonEmptyText (NonEmptyText, getRawText, mkNonEmptyText, unsafeNonEmptyText)

import Control.Monad.Writer (Writer, tell)
import Core.Render (RenderMode (..), RenderStrategy (..))
import Core.Stats (Difficulty (..), ResourceType (..), StackPower (..), StatValue (..))
import Core.Util (tshow)

-- | The Main Inline Sum Type
-- | Refactored to use inline records for standard JSON derivation.
data Inline
  = TextRun
      { style :: Maybe TextStyle
      , content :: NonEmptyText
      }
  | ColorValue
      { value :: StatValue
      }
  | DifficultyValue
      { difficulty :: Difficulty
      }
  | Break
  deriving stock (Eq, Show, Generic)

$(deriveJSON cardpgJsonDef ''Inline)

newtype RichText = RichText {inlines :: NE.NonEmpty Inline}
  deriving stock (Eq, Show, Generic)

instance (RenderStrategy mode Inline m, Monad m) => RenderStrategy mode RichText m where
  type StrategyConfig mode RichText = StrategyConfig mode Inline
  renderStrategyWith c rt = mapM_ (renderStrategyWith @mode c) (getInlines rt)

-- Text Mode Implementation for Inline
instance RenderStrategy 'TextMode Inline (Writer [Text]) where
  renderStrategy (TextRun (Just style) content) = tell [wrapped (styleDelimiter style) $ getRawText content]
  renderStrategy (TextRun Nothing content) = tell [getRawText content]
  renderStrategy (ColorValue power) = tell [prettyStatValue power]
  renderStrategy (DifficultyValue diff) = tell [prettyDifficulty diff]
  renderStrategy Break = tell ["\n"]

prettyStatValue :: StatValue -> Text
prettyStatValue s = "{" <> tshow s.color <> ":" <> tshow s.value <> "}"

prettyDifficulty :: Difficulty -> Text
prettyDifficulty (Difficulty attr val) = prettyResource attr <> " " <> tshow val

prettyResource :: ResourceType -> Text
prettyResource Red = "{Red}"
prettyResource Yellow = "{Yellow}"
prettyResource Blue = "{Blue}"

wrapped :: Text -> Text -> Text
wrapped wrapper t = wrapper <> t <> wrapper

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
