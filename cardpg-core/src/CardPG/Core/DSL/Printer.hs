{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE RecordWildCards #-}

module CardPG.Core.DSL.Printer (prettyRule, richToString) where

import CardPG.Core.Primitives (Difficulty (..), ResourceType (..))
import CardPG.Core.RichText
  ( Inline (..)
  , RichString
  , RichText (..)
  , StackPower (..)
  , TextStyle (..)
  , unRichString
  , unRichText
  )
import CardPG.Core.RuleDefs
  ( AttackDefT (..)
  , ChannelDefT (..)
  , DSLBase
  , GeneralDefT (..)
  , PassiveDef (..)
  , PrimeDefT (..)
  , RuleT (..)
  , StanceDefT (..)
  , TaskDefT (..)
  , TriggerDefT (..)
  )

import Data.List.NonEmpty qualified as NE
import Data.Maybe (catMaybes)
import Data.Text (Text)
import Data.Text qualified as T

import CardPG.Core.NonEmptyText (NonEmptyText, getNonEmptyText)

effectArrow :: Text
effectArrow = "->"

wrapped :: Text -> Text -> Text
wrapped wrapper t = wrapper <> t <> wrapper

inParens :: Text -> Text
inParens t = "(" <> t <> ")"

prettyRule :: DSLBase -> Text
prettyRule (RuleAttack AttackDef{..}) =
  "Attack "
    <> prettyResource _resistedBy
    <> ": Strength = "
    <> prettyPower _power
    <> prettyExtra _effect
prettyRule (RuleGeneral GeneralDef{..}) =
  "Action: "
    <> getNonEmptyText _name
    <> maybe "" ((" " <>) . inParens . richToString) _cost
    <> maybe "" ((" " <>) . prettyDifficulty) _difficulty
    <> " "
    <> effectArrow
    <> " "
    <> richToString _effect
prettyRule (RuleStance StanceDef{..}) =
  "Stance " <> inParens (getNonEmptyText _duration) <> prettyExtra (Just _effect)
prettyRule (RuleChannel ChannelDef{..}) =
  "Channel " <> inParens (getNonEmptyText _duration) <> prettyExtra (Just _effect)
prettyRule (RulePrime PrimeDef{..}) =
  "Prime " <> inParens (getNonEmptyText _trigger) <> ": " <> prettyRule _reaction
prettyRule (RulePassive PassiveDef{..}) =
  "Passive: " <> prettyPower _bonus <> prettyCondition _condition
prettyRule (RuleTask TaskDef{..}) =
  "Task: "
    <> getNonEmptyText _name
    <> parensContent
    <> " "
    <> effectArrow
    <> " "
    <> richToString _effect
  where
    checkStr = fmap (\c -> "Check " <> prettyDifficulty c) _check
    timeStr = fmap (\t -> "Time " <> richToString t) _time
    costStr = fmap (\c -> "Cost " <> richToString c) _cost

    parts = [checkStr, timeStr, costStr]
    inner = T.intercalate "; " (catMaybes parts)

    parensContent = if T.null inner then "" else " (" <> inner <> ")"
prettyRule (RuleTrigger TriggerDef{..}) =
  "When " <> getNonEmptyText _trigger <> " " <> effectArrow <> " " <> richToString _effect
prettyRule (RuleNarrative rt) = richToString rt

prettyCondition :: Maybe NonEmptyText -> Text
prettyCondition Nothing = ""
prettyCondition (Just c) = " " <> getNonEmptyText c

prettyResource :: ResourceType -> Text
prettyResource Red = "{Red}"
prettyResource Yellow = "{Yellow}"
prettyResource Blue = "{Blue}"

prettyPower :: StackPower -> Text
prettyPower (StackPower base 0 Nothing) = prettyResource base
prettyPower (StackPower base modifier conditional) =
  prettyResource base <> " " <> prettyModifier modifier <> prettyConditional conditional

prettyConditional :: Maybe Text -> Text
prettyConditional Nothing = ""
prettyConditional (Just c) = " " <> c

prettyModifier :: Int -> Text
prettyModifier n
  | n >= 0 = "+ " <> T.pack (show n)
  | otherwise = "- " <> T.pack (show (abs n))

prettyDifficulty :: Difficulty -> Text
prettyDifficulty (Difficulty attr val) = prettyResource attr <> " " <> T.pack (show val)

prettyExtra :: Maybe RichString -> Text
prettyExtra Nothing = ""
prettyExtra (Just rt) = " -> " <> richToString rt

richToString :: RichString -> Text
richToString rs = T.concat . map inlineToString . NE.toList . unRichText $ unRichString rs

inlineToString :: Inline -> Text
inlineToString (TextRun (Just Bold) content) = wrapped "**" $ getNonEmptyText content
inlineToString (TextRun (Just Italic) content) = wrapped "*" $ getNonEmptyText content
inlineToString (TextRun (Just GameKeyword) content) = wrapped "`" $ getNonEmptyText content
inlineToString (TextRun _ content) = getNonEmptyText content
inlineToString (ColorValue power) = prettyPower power
inlineToString (DifficultyValue diff) = prettyDifficulty diff
inlineToString Break = "\n"
