{-# LANGUAGE FlexibleInstances #-}
{-# LANGUAGE OverloadedRecordDot #-}
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
import Data.Maybe (catMaybes)
import Data.Text (Text)
import Data.Text qualified as T
import Text.Megaparsec (eof)

import Core.Language
  ( cmdAction
  , cmdOngoing
  , cmdPassive
  , cmdTask
  , cmdWhen
  , kwCheck
  , kwCost
  , kwStr
  , kwTime
  , sepColon
  , sepSemi
  , styleDelimiter
  )
import Core.NonEmptyText (NonEmptyText, getRawText)
import Core.Parser (Parser, basicParse)
import Core.RichText
  ( Inline (..)
  , RichText (..)
  , getInlines
  )
import Core.RuleDefs
  ( AttackDef (..)
  , GeneralDef (..)
  , OngoingDef (..)
  , PassiveDef (..)
  , Rule (..)
  , TaskDef (..)
  , TriggerDef (..)
  )
import Core.Stats
  ( Difficulty (..)
  , ResourceType (..)
  , StackPower (..)
  , StatValue (..)
  , parseStatValue
  , prettyModifier
  , resourceTypeParser
  )
import Core.Util (tshow)

-- Import parsers from RuleParser
import Core.DSL.RuleParser
  ( attackParser
  , difficultyParser
  , richTextParser
  , ruleParser
  , stackPowerParser
  )

-- | Typeclass for DSL round-tripping.
-- | Invariant: parseText . toText === Right
class TextRep a where
  toText :: a -> Text
  textParser :: Parser a

-- | Parse text using the TextRep parser
parseText :: (TextRep a) => Text -> Either String a
parseText = basicParse (textParser <* eof)

-- Rule (top-level, fully roundtrippable)
instance TextRep Rule where
  toText (RuleGeneral def) = toTextGeneralDef def
  toText (RuleOngoing def) = toTextOngoingDef def
  toText (RulePassive def) = toTextPassiveDef def
  toText (RuleTask def) = toTextTaskDef def
  toText (RuleTrigger def) = toTextTriggerDef def
  toText (RuleNarrative rt) = toTextRichText rt
  textParser = ruleParser

-- AttackDef
instance TextRep AttackDef where
  toText def =
    toTextResourceType def.resistedBy
      <> sepColon
      <> " "
      <> kwStr
      <> " = "
      <> toTextStackPower def.power
      <> maybe "" (\e -> " → " <> toTextRichText e) def.effect
  textParser = attackParser

-- RichText
instance TextRep RichText where
  toText = toTextRichText
  textParser = richTextParser

-- StackPower
instance TextRep StackPower where
  toText = toTextStackPower
  textParser = stackPowerParser

-- Difficulty
instance TextRep Difficulty where
  toText = toTextDifficulty
  textParser = difficultyParser

-- ResourceType
instance TextRep ResourceType where
  toText = toTextResourceType
  textParser = resourceTypeParser

-- StatValue
instance TextRep StatValue where
  toText = toTextStatValue
  textParser = parseStatValue

--------------------------------------------------------------------------------
-- Helper functions for toText serialization
-- These are used internally and by types that don't need full TextRep instances
--------------------------------------------------------------------------------

toTextResourceType :: ResourceType -> Text
toTextResourceType Red = "{Red}"
toTextResourceType Yellow = "{Yellow}"
toTextResourceType Blue = "{Blue}"

toTextDifficulty :: Difficulty -> Text
toTextDifficulty (Difficulty attr val) = toTextResourceType attr <> " " <> tshow val

toTextStackPower :: StackPower -> Text
toTextStackPower (StackPower base 0 Nothing) = toTextResourceType base
toTextStackPower (StackPower base modifier conditional) =
  toTextResourceType base
    <> " "
    <> prettyModifier modifier
    <> maybe "" (" " <>) conditional

toTextInline :: Inline -> Text
toTextInline (TextRun (Just style) content) = wrapped (styleDelimiter style) $ getRawText content
toTextInline (TextRun Nothing content) = getRawText content
toTextInline (ColorValue power) = toTextStatValue power
toTextInline (DifficultyValue diff) = toTextDifficulty diff
toTextInline Break = "\n"

toTextStatValue :: StatValue -> Text
toTextStatValue s = "{" <> tshow s.color <> ":" <> tshow s.value <> "}"

wrapped :: Text -> Text -> Text
wrapped wrapper t = wrapper <> t <> wrapper

toTextRichText :: RichText -> Text
toTextRichText rt = T.concat $ toTextInline <$> NE.toList (getInlines rt)

toTextNonEmptyText :: NonEmptyText -> Text
toTextNonEmptyText = getRawText

toTextGeneralDef :: GeneralDef -> Text
toTextGeneralDef def =
  cmdAction
    <> " "
    <> toTextNonEmptyText def.name
    <> maybe "" (\c -> " (" <> toTextRichText c <> ")") def.cost
    <> maybe "" (\d -> " " <> toTextDifficulty d) def.difficulty
    <> " → "
    <> toTextRichText def.effect

toTextOngoingDef :: OngoingDef -> Text
toTextOngoingDef def =
  cmdOngoing
    <> " ("
    <> toTextRichText def.life
    <> ") → "
    <> toTextRichText def.effect

toTextPassiveDef :: PassiveDef -> Text
toTextPassiveDef def =
  cmdPassive
    <> " "
    <> toTextStackPower def.bonus
    <> maybe "" (\c -> " " <> toTextNonEmptyText c) def.condition

toTextTaskDef :: TaskDef -> Text
toTextTaskDef def =
  cmdTask
    <> " "
    <> toTextNonEmptyText def.name
    <> renderTaskParts def
    <> " → "
    <> toTextRichText def.effect
  where
    renderTaskParts d =
      let parts =
            catMaybes
              [ fmap (\c -> kwCheck <> " " <> toTextDifficulty c) d.check
              , fmap (\t -> kwTime <> " " <> toTextRichText t) d.time
              , fmap (\c -> kwCost <> " " <> toTextRichText c) d.cost
              ]
       in if null parts
            then ""
            else " (" <> T.intercalate (sepSemi <> " ") parts <> ")"

toTextTriggerDef :: TriggerDef -> Text
toTextTriggerDef def =
  cmdWhen
    <> " "
    <> toTextNonEmptyText def.trigger
    <> " → "
    <> toTextRichText def.effect
