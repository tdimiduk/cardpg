{-# LANGUAGE FlexibleInstances #-}
{-# LANGUAGE OverloadedStrings #-}

-- | TextRep typeclass for DSL round-tripping.
-- | Invariant: parseText . toText === Right
module Core.DSL.TextRep
  ( TextRep (..)
  , parseText
  -- Re-exports for convenience
  , ruleParser
  , attackParser
  , richTextParser
  , stackPowerParser
  , difficultyParser
  , resourceTypeParser
  , parseStatValue
  )
where

import Data.List.NonEmpty qualified as NE
import Data.Text (Text)
import Data.Text qualified as T
import Text.Megaparsec (eof)

import Core.DSL.RuleParser
  ( attackParser
  , difficultyParser
  , richTextParser
  , ruleParser
  , stackPowerParser
  )

import Core.Language (sepColon, styleDelimiter)
import Core.Layout
  ( LayoutItem (..)
  , layoutAttackDef
  , layoutDifficulty
  , layoutRule
  , layoutStackPower
  )
import Core.NonEmptyText (getRawText)
import Core.Parser (Parser, basicParse)
import Core.RichText
  ( Inline (..)
  , RichText (..)
  , getInlines
  )
import Core.RuleDefs
  ( AttackDef (..)
  , Rule (..)
  )
import Core.Stats
  ( Difficulty (..)
  , ResourceType (..)
  , StackPower (..)
  , StatValue (..)
  , parseStatValue
  , resourceTypeParser
  )
import Core.Util (tshow)

-- | Typeclass for DSL round-tripping.
-- | Invariant: parseText . toText === Right
class TextRep a where
  toText :: a -> Text
  textParser :: Parser a

-- | Parse text using the TextRep parser
parseText :: (TextRep a) => Text -> Either String a
parseText = basicParse (textParser <* eof)

-- Rule (top-level, fully roundtrippable)
-- Rule (top-level, fully roundtrippable)
instance TextRep Rule where
  toText = renderLayoutText . layoutRule
  textParser = ruleParser

-- AttackDef
instance TextRep AttackDef where
  -- Drop the first two items: "Attack" keyword and space since they are redundant in the YAML context
  -- (the key is already "attack"). The parser supports optional "Attack" keyword, so this remains safe.
  -- TODO: have this only happen for CoreCard YAML (we'd probably like the attack keyword if we ever use
  -- this in a different context where don't have a yaml key right there)
  toText = renderLayoutText . drop 2 . layoutAttackDef
  textParser = attackParser

-- RichText
instance TextRep RichText where
  toText = toTextRichText
  textParser = richTextParser

-- StackPower
instance TextRep StackPower where
  toText = renderLayoutText . layoutStackPower
  textParser = stackPowerParser

-- Difficulty
instance TextRep Difficulty where
  toText = renderLayoutText . layoutDifficulty
  textParser = difficultyParser

-- ResourceType
instance TextRep ResourceType where
  toText = toTextResourceType
  textParser = resourceTypeParser

-- StatValue
instance TextRep StatValue where
  toText = renderLayoutText . layoutStatValue
  textParser = parseStatValue

--------------------------------------------------------------------------------
-- Helpers
--------------------------------------------------------------------------------

renderLayoutText :: [LayoutItem] -> Text
renderLayoutText items = T.concat $ map renderLayoutItem items

renderLayoutItem :: LayoutItem -> Text
renderLayoutItem (Keyword t) = t
renderLayoutItem (Literal t) = t
renderLayoutItem (Symbol r Nothing) = toTextResourceType r
renderLayoutItem (Symbol r (Just t)) = toTextResourceType r <> " " <> t
renderLayoutItem (RichContent rt) = toTextRichText rt
renderLayoutItem (Group items) = "(" <> renderLayoutText items <> ")"
renderLayoutItem Space = " "

layoutStatValue :: StatValue -> [LayoutItem]
layoutStatValue s =
  [ Literal $ "{" <> tshow s.color <> sepColon <> " " <> tshow s.value <> "}"
  ]

toTextResourceType :: ResourceType -> Text
toTextResourceType Red = "{Red}"
toTextResourceType Yellow = "{Yellow}"
toTextResourceType Blue = "{Blue}"

toTextInline :: Inline -> Text
toTextInline (TextRun (Just style) content) = wrapped (styleDelimiter style) $ getRawText content
toTextInline (TextRun Nothing content) = getRawText content
toTextInline (ColorValue power) = renderLayoutText $ layoutStatValue power
toTextInline (DifficultyValue diff) = renderLayoutText $ layoutDifficulty diff
toTextInline Break = "\n"

wrapped :: Text -> Text -> Text
wrapped wrapper t = wrapper <> t <> wrapper

toTextRichText :: RichText -> Text
toTextRichText rt = T.concat $ toTextInline <$> NE.toList (getInlines rt)
