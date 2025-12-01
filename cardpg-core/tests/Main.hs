{-# LANGUAGE DeriveGeneric #-}
{-# LANGUAGE DerivingStrategies #-}
{-# LANGUAGE StandaloneDeriving #-}
{-# LANGUAGE GeneralisedNewtypeDeriving #-}
{-# LANGUAGE FlexibleInstances #-}
{-# LANGUAGE ScopedTypeVariables #-}
{-# LANGUAGE DisambiguateRecordFields #-}
{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE RecordWildCards #-}
{-# OPTIONS_GHC -fno-warn-orphans #-}
module Main where

import Data.Maybe (fromMaybe, mapMaybe)

import Test.Tasty
import Test.Tasty.QuickCheck
import Generic.Random
import Data.Aeson (encode, eitherDecode)
import Data.Text (Text)
import qualified Data.Text as T
import Data.List.NonEmpty (NonEmpty(..))
import qualified Data.List.NonEmpty as NE

import CardPG.Core.Card
import CardPG.Core.Types
import CardPG.Core.RichText
import CardPG.Core.NonEmptyText (NonEmptyText, unsafeNonEmptyText, mkNonEmptyText, getNonEmptyText)
import CardPG.Core.DSL.Parser (parseRule)
import CardPG.Core.DSL.Printer (prettyRule)

main :: IO ()
main = defaultMain tests

tests :: TestTree
tests = testGroup "Tests"
  [ testProperty "CoreCard Roundtrip" prop_coreCardRoundtrip
  , testProperty "ItemCard Roundtrip" prop_itemCardRoundtrip
  , testProperty "NatureCard Roundtrip" prop_natureCardRoundtrip
  , testProperty "TalentCard Roundtrip" prop_talentCardRoundtrip
  , testProperty "EncounterCard Roundtrip" prop_encounterCardRoundtrip
  , testProperty "ConsequenceCard Roundtrip" prop_consequenceCardRoundtrip
  , testProperty "DSL Roundtrip" prop_dslRoundtrip
  ]

prop_coreCardRoundtrip :: CoreCard -> Property
prop_coreCardRoundtrip x = 
  let encoded = encode x
      decoded = eitherDecode encoded
      normalized = normalizeCoreCard x
  in counterexample (show encoded) $ decoded === Right normalized

prop_itemCardRoundtrip :: ItemCard -> Property
prop_itemCardRoundtrip x = 
  let encoded = encode x
      decoded = eitherDecode encoded
  in counterexample (show encoded) $ decoded === Right x

prop_natureCardRoundtrip :: NatureCard -> Property
prop_natureCardRoundtrip x = 
  let encoded = encode x
      decoded = eitherDecode encoded
  in counterexample (show encoded) $ decoded === Right x

prop_talentCardRoundtrip :: TalentCard -> Property
prop_talentCardRoundtrip x = 
  let encoded = encode x
      decoded = eitherDecode encoded
  in counterexample (show encoded) $ decoded === Right x

prop_encounterCardRoundtrip :: EncounterCard -> Property
prop_encounterCardRoundtrip x = 
  let encoded = encode x
      decoded = eitherDecode encoded
  in counterexample (show encoded) $ decoded === Right x

prop_consequenceCardRoundtrip :: ConsequenceCard -> Property
prop_consequenceCardRoundtrip x = 
  let encoded = encode x
      decoded = eitherDecode encoded
      normalized = normalizeConsequenceCard x
  in counterexample (show encoded) $ decoded === Right normalized

normalizeCoreCard :: CoreCard -> CoreCard
normalizeCoreCard c@CoreCard{..} = c
  { _rules = fmap (fmap normalizeRuleDSL) _rules
  , _flavor = normalizeEffectJSON _flavor
  }

normalizeConsequenceCard :: ConsequenceCard -> ConsequenceCard
normalizeConsequenceCard c@ConsequenceCard{..} = c
  { _rules = fmap (fmap normalizeRuleDSL) _rules
  }

prop_dslRoundtrip :: Rule -> Property
prop_dslRoundtrip r = 
  let printed = prettyRule r
      parsed = parseRule printed
      expected = normalizeRuleDSL r
  in counterexample ("Original: " ++ show r ++ "\nPrinted: " ++ show printed ++ "\nParsed: " ++ show parsed) $ parsed === Right expected

normalizeRuleDSL :: Rule -> Rule
normalizeRuleDSL = normalizeRuleWith normalizeEffectDSL

normalizeRuleJSON :: Rule -> Rule
normalizeRuleJSON = normalizeRuleWith normalizeEffectJSON

normalizeRuleWith :: (Maybe RichString -> Maybe RichString) -> Rule -> Rule
normalizeRuleWith norm (RuleAttack (AttackDef p r e)) = RuleAttack $ AttackDef p r (norm e)
normalizeRuleWith norm (RuleDefend (DefendDef p r e)) = RuleDefend $ DefendDef p r (norm e)
normalizeRuleWith norm (RuleGeneral (GeneralDef p c e)) = RuleGeneral $ GeneralDef p (norm c) (fromMaybe (mkRichString (TextRun (TextRunDef Nothing (unsafeNonEmptyText " ")) :| [])) (norm (Just e)))
normalizeRuleWith norm (RuleNarrative rt) = RuleNarrative (fromMaybe (mkRichString (TextRun (TextRunDef Nothing (unsafeNonEmptyText " ")) :| [])) (norm (Just rt)))
normalizeRuleWith _ (RulePassive (PassiveDef b c)) = RulePassive $ PassiveDef b (normalizeCondition c)
normalizeRuleWith norm (RuleStance (StanceDef d e)) = RuleStance $ StanceDef d (fromMaybe (mkRichString (TextRun (TextRunDef Nothing (unsafeNonEmptyText " ")) :| [])) (norm (Just e)))
normalizeRuleWith norm (RuleChannel (ChannelDef d e)) = RuleChannel $ ChannelDef d (fromMaybe (mkRichString (TextRun (TextRunDef Nothing (unsafeNonEmptyText " ")) :| [])) (norm (Just e)))
normalizeRuleWith norm (RulePrime (PrimeDef t r)) = RulePrime $ PrimeDef t (normalizeRuleWith norm r)

normalizeCondition :: Maybe NonEmptyText -> Maybe NonEmptyText
normalizeCondition c = c

normalizeInlineDSL :: Inline -> Inline
normalizeInlineDSL (Icon (IconDef c)) = DynamicVal (DynamicValDef (StackPower c 0 Nothing))
normalizeInlineDSL x = x

normalizeInlineJSON :: Inline -> Inline
normalizeInlineJSON x = x

normalizeEffectDSL :: Maybe RichString -> Maybe RichString
normalizeEffectDSL Nothing = Nothing
normalizeEffectDSL (Just rs) = 
  let normalized = map normalizeInlineDSL (NE.toList (unRichString rs))
  in case NE.nonEmpty normalized of
       Nothing -> Nothing
       Just ne -> stripLeadingWhitespace (mkRichString ne)

stripLeadingWhitespace :: RichString -> Maybe RichString
stripLeadingWhitespace rs = 
  case NE.toList (unRichString rs) of
    (TextRun (TextRunDef Nothing c) : rest) ->
      let stripped = T.stripStart (getNonEmptyText c)
      in case mkNonEmptyText stripped of
           Nothing -> 
             case NE.nonEmpty rest of
               Nothing -> Nothing
               Just restNe -> Just (mkRichString restNe)
           Just c' -> Just (mkRichString (TextRun (TextRunDef Nothing c') :| rest))
    _ -> Just rs

normalizeEffectJSON :: Maybe RichString -> Maybe RichString
normalizeEffectJSON Nothing = Nothing
normalizeEffectJSON (Just rs) = 
  let normalized = map normalizeInlineJSON (NE.toList (unRichString rs))
      filtered = mapMaybe filterEmptyTextRun normalized
  in case NE.nonEmpty filtered of
       Nothing -> Nothing
       Just ne -> Just (mkRichString ne)

filterEmptyTextRun :: Inline -> Maybe Inline
filterEmptyTextRun (TextRun (TextRunDef s c)) = 
  let stripped = T.strip (getNonEmptyText c)
  in case mkNonEmptyText stripped of
       Nothing -> Nothing
       Just c' -> Just (TextRun (TextRunDef s c'))
filterEmptyTextRun x = Just x

-- Arbitrary Instances

instance Arbitrary Text where
  arbitrary = T.pack <$> listOf (elements ['a'..'z'])
  shrink t = T.pack <$> shrink (T.unpack t)

instance Arbitrary ResourceType where
  arbitrary = genericArbitrary uniform
  shrink = genericShrink

instance Arbitrary StackPower where
  arbitrary = do
    base <- arbitrary
    modVal <- arbitrary
    cond <- oneof 
      [ pure Nothing
      , do
          t <- arbitrary
          pure $ Just $ "(" <> t <> ")"
      ]
    pure $ StackPower base modVal cond
  shrink = genericShrink

instance Arbitrary TextStyle where
  arbitrary = genericArbitrary uniform
  shrink = genericShrink

instance Arbitrary TextRunDef where
  arbitrary = do
    style <- arbitrary
    content <- arbitrary
    return $ TextRunDef style content

instance Arbitrary Inline where
  arbitrary = genericArbitrary uniform

instance Arbitrary RichString where
  arbitrary = do
    inlines <- listOf1 arbitrary
    return $ mkRichString (NE.fromList inlines)
  shrink rs = 
    [ mkRichString ne 
    | l <- shrink (NE.toList (unRichString rs))
    , not (null l)
    , Just ne <- [NE.nonEmpty l]
    ]

instance Arbitrary Block where
  arbitrary = genericArbitrary uniform
  shrink = genericShrink

instance Arbitrary PassiveDef where
  arbitrary = genericArbitrary uniform
  shrink = genericShrink

instance Arbitrary AttackDef where
  arbitrary = genericArbitrary uniform
  shrink = genericShrink

instance Arbitrary DefendDef where
  arbitrary = genericArbitrary uniform
  shrink = genericShrink

instance Arbitrary GeneralDef where
  arbitrary = genericArbitrary uniform
  shrink = genericShrink

instance Arbitrary StanceDef where
  arbitrary = genericArbitrary uniform
  shrink = genericShrink

instance Arbitrary ChannelDef where
  arbitrary = genericArbitrary uniform
  shrink = genericShrink

instance Arbitrary PrimeDef where
  arbitrary = genericArbitrary uniform
  shrink = genericShrink

instance Arbitrary Rule where
  arbitrary = genericArbitrary uniform
  shrink = genericShrink

instance Arbitrary Stats where
  arbitrary = genericArbitrary uniform
  shrink = genericShrink

instance Arbitrary CoreCard where
  arbitrary = genericArbitrary uniform
  shrink = genericShrink

instance Arbitrary ItemCard where
  arbitrary = genericArbitrary uniform
  shrink = genericShrink

instance Arbitrary NatureCard where
  arbitrary = genericArbitrary uniform
  shrink = genericShrink

instance Arbitrary TalentCard where
  arbitrary = genericArbitrary uniform
  shrink = genericShrink

instance Arbitrary EncounterCard where
  arbitrary = genericArbitrary uniform
  shrink = genericShrink

instance Arbitrary ConsequenceCard where
  arbitrary = genericArbitrary uniform
  shrink = genericShrink

instance Arbitrary IconDef where
  arbitrary = genericArbitrary uniform
  shrink = genericShrink

instance Arbitrary DynamicValDef where
  arbitrary = genericArbitrary uniform
  shrink = genericShrink

instance Arbitrary GeneralActionDef where
  arbitrary = genericArbitrary uniform
  shrink = genericShrink

instance Arbitrary EncounterMechanics where
  arbitrary = genericArbitrary uniform
  shrink = genericShrink

instance Arbitrary NonEmptyText where
  arbitrary = do
    t <- T.pack <$> listOf1 (elements ['a'..'z'])
    return $ unsafeNonEmptyText t
  shrink ne = 
    [ unsafeNonEmptyText (T.pack s) 
    | s <- shrink (T.unpack (getNonEmptyText ne))
    , not (null s)
    ]

-- Helper for NonEmpty
instance Arbitrary a => Arbitrary (NonEmpty a) where
  arbitrary = do
    x <- arbitrary
    xs <- arbitrary
    return (x :| xs)
  shrink ne = [ NE.fromList l | l <- shrink (NE.toList ne), not (null l) ]

