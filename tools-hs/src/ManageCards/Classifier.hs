{-# LANGUAGE OverloadedStrings #-}

module ManageCards.Classifier
  ( classifyLegacy
  , checkShorthandColor
  , checkLegacyArmor
  , checkLegacyDefense
  , checkObsoleteTiers
  , checkLegacyWounds
  , extractCardTexts
  ) where

import Core.Card (CoreCard (..), RulesStatus (..))
import Core.DSL (toText)
import Data.Char (toLower)
import Data.List (tails)
import Data.List.NonEmpty qualified as NE
import Data.Text (Text)
import Data.Text qualified as T

-- | Extract all text fields from a card that could contain rules syntax.
extractCardTexts :: CoreCard -> [Text]
extractCardTexts card =
  let CoreCard{attack = cAttack, rules = cRules, flavor = cFlavor} = card
      mAttack = maybe [] (\a -> [toText a]) cAttack
      mRules = maybe [] (map toText . NE.toList) cRules
      mFlavor = maybe [] (\f -> [toText f]) cFlavor
   in mAttack ++ mRules ++ mFlavor

-- | Shorthand color syntax: |x|, |y|, |z|, |b| (case-insensitive)
checkShorthandColor :: Text -> Bool
checkShorthandColor txt =
  let s = map toLower (T.unpack txt)
   in any isColorPipe (tails s)
  where
    isColorPipe ('|' : c : '|' : _) = c `elem` ['x', 'y', 'z', 'b']
    isColorPipe _ = False

-- | Legacy armor syntax: 'ignore .*armor', 'no armor', 'armor damage' (case-insensitive)
checkLegacyArmor :: Text -> Bool
checkLegacyArmor txt =
  let lt = T.toLower txt
   in "no armor" `T.isInfixOf` lt
        || "armor damage" `T.isInfixOf` lt
        || any lineHasIgnoreArmor (T.lines lt)
  where
    lineHasIgnoreArmor line =
      case T.breakOn "ignore" line of
        (_, rest) | not (T.null rest) -> "armor" `T.isInfixOf` rest
        _ -> False

-- | Legacy defense wording: 'defend from anywhere' (case-insensitive)
checkLegacyDefense :: Text -> Bool
checkLegacyDefense txt =
  "defend from anywhere" `T.isInfixOf` T.toLower txt

-- | Obsolete consequence tiers: 'Minor:', 'Major:', 'Critical:' (case-insensitive)
checkObsoleteTiers :: Text -> Bool
checkObsoleteTiers txt =
  let lt = T.toLower txt
   in "minor:" `T.isInfixOf` lt
        || "major:" `T.isInfixOf` lt
        || "critical:" `T.isInfixOf` lt

-- | Legacy wound phrasing: 'basic wound' (case-insensitive)
checkLegacyWounds :: Text -> Bool
checkLegacyWounds txt =
  "basic wound" `T.isInfixOf` T.toLower txt

-- | Classify a card according to legacy heuristics.
classifyLegacy :: CoreCard -> (RulesStatus, Maybe Text)
classifyLegacy card =
  let texts = extractCardTexts card
      reasons =
        ["Uses shorthand color syntax (|[xyzb]|)" | any checkShorthandColor texts]
          ++ ["Uses legacy armor syntax" | any checkLegacyArmor texts]
          ++ ["Uses legacy defense wording (defend from anywhere)" | any checkLegacyDefense texts]
          ++ ["Uses obsolete consequence tiers (Minor/Major/Critical)" | any checkObsoleteTiers texts]
          ++ ["Uses legacy wound phrasing (basic wound)" | any checkLegacyWounds texts]
   in case reasons of
        [] -> (RulesCurrent, Nothing)
        rs -> (RulesOutdated, Just (T.intercalate "; " rs))
