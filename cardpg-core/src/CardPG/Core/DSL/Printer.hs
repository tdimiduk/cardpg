{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE RecordWildCards #-}

module CardPG.Core.DSL.Printer (prettyRule, richToString) where

import Data.Text (Text)
import qualified Data.Text as T
import qualified Data.List.NonEmpty as NE
import CardPG.Core.RuleDefs (Rule(..), AttackDef(..), DefendDef(..), GeneralDef(..), StanceDef(..), ChannelDef(..), PrimeDef(..), PassiveDef(..), TaskDef(..), TriggerDef(..))
import CardPG.Core.RichText (RichString, unRichString, Inline(..), StackPower(..), TextStyle(..))
import CardPG.Core.Types (ResourceType(..))

import CardPG.Core.NonEmptyText (getNonEmptyText, NonEmptyText)


effectArrow :: Text
effectArrow = "->"

wrapped :: Text -> Text -> Text
wrapped wrapper t = wrapper <> t <> wrapper

inParens :: Text -> Text
inParens t = "(" <> t <> ")"


prettyRule :: Rule -> Text
prettyRule (RuleAttack AttackDef{..}) =
  "Attack " <> prettyResource _resistedBy <> ": Strength = " <> prettyPower _power <> prettyExtra _effect
prettyRule (RuleDefend DefendDef{..}) =
  "Defend " <> T.intercalate ", " (map prettyResource (NE.toList _resists)) <> ": Strength = " <> prettyPower _power <> prettyExtra _effect
prettyRule (RuleGeneral GeneralDef{..}) = 
  "Action: " <> getNonEmptyText _name <> maybe "" ((" " <>) . inParens. richToString) _cost 
  <> maybe "" ((" " <>) . prettyPower) _power  <> " " <> effectArrow <> " " <> richToString _effect
prettyRule (RuleStance StanceDef{..}) =
  "Stance " <> inParens (getNonEmptyText _duration) <> prettyExtra (Just _effect)
prettyRule (RuleChannel ChannelDef{..}) =
  "Channel " <> inParens (getNonEmptyText _duration) <> prettyExtra (Just _effect)
prettyRule (RulePrime PrimeDef{..}) =
  "Prime " <> inParens (getNonEmptyText _trigger) <> ": " <> prettyRule _reaction
prettyRule (RulePassive PassiveDef{..}) =
  "Passive: " <> prettyPower _bonus <> prettyCondition _condition
prettyRule (RuleTask TaskDef{..}) =
  "Task: " <> getNonEmptyText _name <> parensContent <> " " <> effectArrow <> " " <> richToString _effect
  where
    checkStr = fmap (\c -> "Check " <> prettyPower c) _check
    timeStr = fmap (\t -> "Time " <> richToString t) _time
    costStr = fmap (\c -> "Cost " <> richToString c) _cost
    
    parts = [checkStr, timeStr, costStr]
    inner = T.intercalate "; " [p | Just p <- parts]

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

prettyExtra :: Maybe RichString -> Text
prettyExtra Nothing = ""
prettyExtra (Just rt) = " -> " <> richToString rt



richToString :: RichString -> Text
richToString = T.concat . map inlineToString . NE.toList . unRichString

inlineToString :: Inline -> Text
inlineToString (TextRun (Just Bold) content) = wrapped "**" $ getNonEmptyText content 
inlineToString (TextRun (Just Italic) content) = wrapped "*" $ getNonEmptyText content
inlineToString (TextRun (Just GameKeyword) content) = wrapped "`" $ getNonEmptyText content 
inlineToString (TextRun _ content) = getNonEmptyText content

inlineToString (ColorValue power) = prettyPower power
inlineToString Break = "\n"
