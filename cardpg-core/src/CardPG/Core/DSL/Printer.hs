module CardPG.Core.DSL.Printer (prettyRule, richToString, prettyModifier) where

import Data.List.NonEmpty qualified as NE
import Data.Maybe (catMaybes)
import Data.Text (Text)
import Data.Text qualified as T

import CardPG.Core.NonEmptyText (NonEmptyText, getRawText)
import CardPG.Core.RichText
  ( Inline (..)
  , RichText
  , StackPower (..)
  , TextStyle (..)
  , getInlines
  )
import CardPG.Core.RuleDefs
  ( AttackDef (..)
  , GeneralDef (..)
  , OngoingDef (..)
  , PassiveDef (..)
  , Rule (..)
  , TaskDef (..)
  , TriggerDef (..)
  )
import CardPG.Core.Stats (Difficulty (..), ResourceType (..), StatValue (..))
import CardPG.Core.Util (tshow)

effectArrow :: Text
effectArrow = "->"

wrapped :: Text -> Text -> Text
wrapped wrapper t = wrapper <> t <> wrapper

inParens :: Text -> Text
inParens t = "(" <> t <> ")"

prettyRule :: Rule -> Text
prettyRule (RuleAttack AttackDef{..}) =
  "Attack "
    <> prettyResource resistedBy
    <> ": Strength = "
    <> prettyPower power
    <> prettyExtra effect
prettyRule (RuleGeneral GeneralDef{..}) =
  "Action: "
    <> getRawText name
    <> maybe "" ((" " <>) . inParens . richToString) cost
    <> maybe "" ((" " <>) . prettyDifficulty) difficulty
    <> " "
    <> effectArrow
    <> " "
    <> richToString effect
prettyRule (RuleOngoing OngoingDef{..}) =
  "Ongoing " <> inParens (richToString life) <> prettyExtra (Just effect)
prettyRule (RulePassive PassiveDef{..}) =
  "Passive: " <> prettyPower bonus <> prettyCondition condition
prettyRule (RuleTask TaskDef{..}) =
  "Task: "
    <> getRawText name
    <> parensContent
    <> " "
    <> effectArrow
    <> " "
    <> richToString effect
  where
    checkStr = fmap (\c -> "Check " <> prettyDifficulty c) check
    timeStr = fmap (\t -> "Time " <> richToString t) time
    costStr = fmap (\c -> "Cost " <> richToString c) cost

    parts = [checkStr, timeStr, costStr]
    inner = T.intercalate "; " (catMaybes parts)

    parensContent = if T.null inner then "" else " (" <> inner <> ")"
prettyRule (RuleTrigger TriggerDef{..}) =
  "When " <> getRawText trigger <> " " <> effectArrow <> " " <> richToString effect
prettyRule (RuleNarrative rt) = richToString rt

prettyCondition :: Maybe NonEmptyText -> Text
prettyCondition Nothing = ""
prettyCondition (Just c) = " " <> getRawText c

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
  | n == 0 = ""
  | n >= 0 = "+ " <> T.pack (show n)
  | otherwise = "- " <> T.pack (show (abs n))

prettyDifficulty :: Difficulty -> Text
prettyDifficulty (Difficulty attr val) = prettyResource attr <> " " <> T.pack (show val)

prettyExtra :: Maybe RichText -> Text
prettyExtra Nothing = ""
prettyExtra (Just rt) = " -> " <> richToString rt

richToString :: RichText -> Text
richToString = T.concat . map inlineToString . NE.toList . getInlines

prettyStatValue :: StatValue -> Text
prettyStatValue s = "{" <> tshow s.color <> ":" <> tshow s.value <> "}"

inlineToString :: Inline -> Text
inlineToString (TextRun (Just Bold) content) = wrapped "**" $ getRawText content
inlineToString (TextRun (Just Italic) content) = wrapped "*" $ getRawText content
inlineToString (TextRun (Just GameKeyword) content) = wrapped "`" $ getRawText content
inlineToString (TextRun _ content) = getRawText content
inlineToString (ColorValue power) = prettyStatValue power
inlineToString (DifficultyValue diff) = prettyDifficulty diff
inlineToString Break = "\n"
