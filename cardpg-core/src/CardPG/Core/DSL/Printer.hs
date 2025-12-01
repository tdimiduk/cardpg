{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE RecordWildCards #-}

module CardPG.Core.DSL.Printer (prettyRule) where

import Data.Text (Text)
import qualified Data.Text as T
import qualified Data.List.NonEmpty as NE
import CardPG.Core.RuleDefs (Rule(..), AttackDef(..), DefendDef(..), GeneralDef(..), StanceDef(..), ChannelDef(..), PrimeDef(..), PassiveDef(..))
import CardPG.Core.RichText (RichString, unRichString, Inline(..), TextRunDef(..), ColorValueDef(..), StackPower(..), TextStyle(..))
import CardPG.Core.Types (ResourceType(..))

import CardPG.Core.NonEmptyText (getNonEmptyText, NonEmptyText)

prettyRule :: Rule -> Text
prettyRule (RuleAttack AttackDef{..}) =
  "Attack " <> prettyResource _resistedBy <> ": Strength = " <> prettyPower _power <> prettyExtra _effect

prettyRule (RuleDefend DefendDef{..}) =
  "Defend " <> T.intercalate ", " (map prettyResource (NE.toList _resists)) <> ": Strength = " <> prettyPower _power <> prettyExtra _effect
prettyRule (RuleGeneral GeneralDef{..}) =
  "General: " <> prettyMaybePower _power <> prettyCost _cost <> " -> " <> richToString _effect
prettyRule (RuleStance StanceDef{..}) =
  "Stance (" <> getNonEmptyText _duration <> ")" <> prettyExtra (Just _effect)
prettyRule (RuleChannel ChannelDef{..}) =
  "Channel (" <> getNonEmptyText _duration <> ")" <> prettyExtra (Just _effect)
prettyRule (RulePrime PrimeDef{..}) =
  "Prime (" <> getNonEmptyText _trigger <> "): " <> prettyRule _reaction
prettyRule (RulePassive PassiveDef{..}) =
  "Passive: " <> prettyPower _bonus <> prettyCondition _condition
prettyRule (RuleNarrative rt) = richToString rt

prettyMaybePower :: Maybe StackPower -> Text
prettyMaybePower Nothing = ""
prettyMaybePower (Just p) = prettyPower p

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

prettyCost :: Maybe RichString -> Text
prettyCost Nothing = ""
prettyCost (Just c) = " (Cost: " <> richToString c <> ")"

richToString :: RichString -> Text
richToString = T.concat . map inlineToString . NE.toList . unRichString

inlineToString :: Inline -> Text
inlineToString (TextRun (TextRunDef (Just Bold) content)) = "**" <> getNonEmptyText content <> "**"
inlineToString (TextRun (TextRunDef (Just Italic) content)) = "*" <> getNonEmptyText content <> "*"
inlineToString (TextRun (TextRunDef (Just GameKeyword) content)) = "`" <> getNonEmptyText content <> "`"
inlineToString (TextRun (TextRunDef _ content)) = getNonEmptyText content

inlineToString (ColorValue (ColorValueDef power)) = prettyPower power
inlineToString Break = "\n"
