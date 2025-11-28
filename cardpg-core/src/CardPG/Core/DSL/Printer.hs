{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE RecordWildCards #-}

module CardPG.Core.DSL.Printer where

import Data.Text (Text)
import qualified Data.Text as T
import qualified Data.List.NonEmpty as NE
import CardPG.Core.Card (Rule(..), AttackDef(..), DefendDef(..))
import CardPG.Core.RichText (RichString, Inline(..), TextRunDef(..), IconDef(..), DynamicValDef(..), StackPower(..), TextStyle(..))
import CardPG.Core.Types (ResourceType(..))

prettyRule :: Rule -> Text
prettyRule (RuleAttack AttackDef{..}) =
  "Attack " <> prettyResource _resistedBy <> ": Strength = " <> prettyPower _power <> prettyExtra _effect
prettyRule (RuleDefend DefendDef{..}) =
  "Defend " <> T.intercalate ", " (map prettyResource (NE.toList _resists)) <> ": Strength = " <> prettyPower _power <> prettyExtra _effect
prettyRule (RuleNarrative rt) = richToString rt
prettyRule _ = "TODO: Implement printer for other rule types"

prettyResource :: ResourceType -> Text
prettyResource Red = "{Red}"
prettyResource Yellow = "{Yellow}"
prettyResource Blue = "{Blue}"

prettyPower :: StackPower -> Text
prettyPower (StackPower base modifier) =
  prettyResource base <> " " <> prettyModifier modifier

prettyModifier :: Int -> Text
prettyModifier n
  | n >= 0 = "+ " <> T.pack (show n)
  | otherwise = "- " <> T.pack (show (abs n))

prettyExtra :: Maybe RichString -> Text
prettyExtra Nothing = ""
prettyExtra (Just rt) = " " <> richToString rt

richToString :: RichString -> Text
richToString = T.concat . map inlineToString

inlineToString :: Inline -> Text
inlineToString (TextRun (TextRunDef (Just Bold) content)) = "**" <> content <> "**"
inlineToString (TextRun (TextRunDef (Just Italic) content)) = "*" <> content <> "*"
inlineToString (TextRun (TextRunDef (Just GameKeyword) content)) = "`" <> content <> "`"
inlineToString (TextRun (TextRunDef _ content)) = content
inlineToString (Icon (IconDef color)) = prettyResource color
inlineToString (DynamicVal (DynamicValDef power)) = prettyPower power
inlineToString Break = "\n"
