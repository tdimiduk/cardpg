{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE TemplateHaskell #-}

module Core.RichText
  ( Inline (..)
  , RichText (..)
  , Block (..)
  , CardBody
  , getInlines
  , mkRichText
  , unsafeSimpleString
  , simpleString
  , richTextParser
  , richTextParserWith
  )
where

import Control.Applicative ((<|>))
import Data.Aeson (FromJSON (..), ToJSON (..), Value (..), genericParseJSON)
import Data.Aeson.TH (deriveJSON)
import Data.Aeson.Types qualified as Aeson
import Data.List.NonEmpty qualified as NE
import Data.Text (Text)
import Data.Text qualified as T
import Data.Vector qualified as V
import GHC.Generics (Generic)

import Text.Megaparsec (between, lookAhead, some, try)
import Text.Megaparsec.Char (char, string)

import Core.DSL (Parser, TextRep (..), choiceEnum, parseText, tryChoice)
import Core.Json (cardpgJsonDef, cardpgJsonOptions)
import Core.Language (TextStyle (..), styleDelimiter)
import Core.NonEmptyText
  ( NonEmptyText
  , getRawText
  , mkNonEmptyText
  , takeWhilePNonEmpty
  , unsafeNonEmptyText
  )
import Core.Stats (Difficulty (..), StatValue, difficultyParser, parseStatValue, toTextResourceType)
import Core.Util (tshow)

--------------------------------------------------------------------------------
-- Types works
--------------------------------------------------------------------------------

-- | The Main Inline Sum Type
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

newtype RichText = RichText {inlines :: NE.NonEmpty Inline}
  deriving stock (Eq, Show, Generic)

getInlines :: RichText -> NE.NonEmpty Inline
getInlines (RichText x) = x

-- | Smart constructor that merges adjacent TextRuns with the same style
-- | and strips leading/trailing whitespace from the entire RichText.
mkRichText :: [Inline] -> Maybe RichText
mkRichText inlinesList =
  let merged = mergeAdjacent inlinesList
      stripped = stripBoundaryWhitespace merged
   in RichText <$> NE.nonEmpty stripped

mergeAdjacent :: [Inline] -> [Inline]
mergeAdjacent (TextRun s1 c1 : TextRun s2 c2 : xs)
  | s1 == s2 = mergeAdjacent (TextRun s1 (c1 <> c2) : xs)
mergeAdjacent (x : xs) = x : mergeAdjacent xs
mergeAdjacent [] = []

stripBoundaryWhitespace :: [Inline] -> [Inline]
stripBoundaryWhitespace [] = []
stripBoundaryWhitespace xs =
  let withoutLeading = stripStart xs
      withoutTrailing = stripEnd withoutLeading
   in withoutTrailing
  where
    stripStart [] = []
    stripStart (TextRun s c : ys) =
      let strippedText = T.stripStart (getRawText c)
       in case mkNonEmptyText strippedText of
            Nothing -> stripStart ys
            Just c' -> TextRun s c' : ys
    stripStart ys = ys

    stripEnd ys =
      let rev = reverse ys
          strippedRev = stripEndRev rev
       in reverse strippedRev

    stripEndRev [] = []
    stripEndRev (TextRun s c : ys) =
      let strippedText = T.stripEnd (getRawText c)
       in case mkNonEmptyText strippedText of
            Nothing -> stripEndRev ys
            Just c' -> TextRun s c' : ys
    stripEndRev ys = ys

-- | Unsafe constructor for literals.
unsafeSimpleString :: Text -> RichText
unsafeSimpleString t = RichText (TextRun Nothing (unsafeNonEmptyText t) NE.:| [])

-- | Safe constructor
simpleString :: Text -> Maybe RichText
simpleString t = mkRichText [TextRun Nothing (unsafeNonEmptyText t)]

instance Semigroup RichText where
  (RichText a) <> (RichText b) =
    RichText $ NE.fromList $ mergeAdjacent (NE.toList a ++ NE.toList b)

data Block
  = Paragraph RichText
  | Header RichText
  | Rule
  | BulletList [RichText]
  deriving stock (Eq, Show, Generic)

type CardBody = [Block]

$(deriveJSON cardpgJsonDef ''Inline)
$(deriveJSON cardpgJsonDef ''Block)

--------------------------------------------------------------------------------
-- TextRep Instance
--------------------------------------------------------------------------------

instance TextRep RichText where
  toText rt = T.concat $ toTextInline <$> NE.toList (getInlines rt)
  textParser = richTextParser

toTextInline :: Inline -> Text
toTextInline (TextRun (Just s) content) = wrapped (styleDelimiter s) $ getRawText content
toTextInline (TextRun Nothing content) = getRawText content
toTextInline (ColorValue power) = toText power
toTextInline (DifficultyValue (Difficulty a v)) = toTextResourceType a <> " " <> tshow v
toTextInline Break = "\n"

wrapped :: Text -> Text -> Text
wrapped wrapper t = wrapper <> t <> wrapper

instance ToJSON RichText where
  toJSON = String . toText

instance FromJSON RichText where
  parseJSON (String t) = case parseText t of
    Right r -> pure r
    Left err -> fail $ "RichText DSL parse failed: " ++ err
  parseJSON (Array v) =
    asLines <|> asInlines
    where
      asLines = do
        texts <- mapM parseJSON (V.toList v) :: Aeson.Parser [Text]
        let combined = T.unlines texts
        case parseText combined of
          Right r -> pure r
          Left err -> fail $ "RichText (Lines) DSL parse failed: " ++ err
      asInlines = do
        inlinesList <- mapM parseJSON (V.toList v) :: Aeson.Parser [Inline]
        case mkRichText inlinesList of
          Just r -> pure r
          Nothing -> fail "RichText (Inlines) failed: Empty list"
  parseJSON v = genericParseJSON (cardpgJsonOptions "RichText") v

--------------------------------------------------------------------------------
-- Parsers
--------------------------------------------------------------------------------

richTextParser :: Parser RichText
richTextParser = richTextParserWith []

richTextParserWith :: [Char] -> Parser RichText
richTextParserWith stopChars = do
  inlinesList <- some (inlineParserStopAt stopChars)
  case mkRichText inlinesList of
    Just rs -> pure rs
    Nothing -> fail "Empty rich string"

inlineParserStopAt :: [Char] -> Parser Inline
inlineParserStopAt stopChars =
  tryChoice
    [ formattingParser
    , colorValueParser
    , breakParser stopChars
    , textParserStopAt stopChars
    ]

breakParser :: [Char] -> Parser Inline
breakParser stopChars = do
  c <- char ';' <|> char '\n'
  if c `elem` stopChars
    then fail "Stop char"
    else pure Break

between' :: Parser a -> Parser b -> Parser b
between' p = between p p

formattingParser :: Parser Inline
formattingParser = choiceEnum $ \s ->
  TextRun (Just s)
    <$> between'
      (string $ styleDelimiter s)
      (takeWhilePNonEmpty Nothing (`notElem` formattingStopChars s))

formattingStopChars :: TextStyle -> [Char]
formattingStopChars = T.unpack . T.take 1 . styleDelimiter

colorValueParser :: Parser Inline
colorValueParser = do
  -- Lookahead to ensure we are parsing something that looks like a resource symbol
  -- to avoid consuming normal text that starts with '{' but isn't a resource.
  _ <- lookAhead (char '{')
  (DifficultyValue <$> try difficultyParser) <|> (ColorValue <$> parseStatValue)

textParserStopAt :: [Char] -> Parser Inline
textParserStopAt stopChars =
  do
    -- Ensure we don't consume characters that start other parsers or stop chars
    content <-
      takeWhilePNonEmpty
        Nothing
        (\c -> c /= '*' && c /= '`' && c /= ';' && c /= '\n' && c /= '{' && notElem c stopChars)
    pure $ TextRun Nothing content
    <|> do
      -- Fallback for '{' if it wasn't a dynamic val
      _ <- char '{'
      let content = unsafeNonEmptyText "{" -- Safe because we know it's "{"
      pure $ TextRun Nothing content
