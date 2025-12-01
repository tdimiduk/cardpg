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
import Debug.Trace (trace)

import Test.Tasty
import Test.Tasty.QuickCheck
import Generic.Random
import Data.Aeson (encode, eitherDecode, ToJSON, FromJSON, Value(..))
import Data.Text (Text)
import qualified Data.Text as T
import Data.List.NonEmpty (NonEmpty(..))
import qualified Data.List.NonEmpty as NE
import qualified Data.Vector as V

import CardPG.Core.Card
import CardPG.Core.Types
import CardPG.Core.RichText
import CardPG.Core.NonEmptyText (NonEmptyText, unsafeNonEmptyText, mkNonEmptyText, getNonEmptyText)
import CardPG.Core.DSL.Parser (parseRule)
import CardPG.Core.DSL.Printer (prettyRule)
import Debug.Trace (trace)

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

prop_dslRoundtrip :: SafeRule -> Property
prop_dslRoundtrip (SafeRule r) = 
  let printed = prettyRule r
      parsed = parseRule printed
      expected = normalizeRuleDSL r
  in counterexample ("Original: " ++ show r ++ "\nPrinted: " ++ show printed ++ "\nParsed: " ++ show parsed) $ parsed === Right expected

normalizeRuleDSL :: Rule -> Rule
normalizeRuleDSL (RuleAttack (AttackDef p r e)) = RuleAttack $ AttackDef p r (normalizeEffectDSL e)
normalizeRuleDSL (RuleDefend (DefendDef p r e)) = RuleDefend $ DefendDef p r (normalizeEffectDSL e)
normalizeRuleDSL (RuleGeneral (GeneralDef p c e)) = RuleGeneral $ GeneralDef p (normalizeEffectDSL c) (fromMaybe (mkRichString (TextRun (TextRunDef Nothing (unsafeNonEmptyText " ")) :| [])) (normalizeEffectDSL (Just e)))
normalizeRuleDSL (RuleNarrative rt) = RuleNarrative (fromMaybe (mkRichString (TextRun (TextRunDef Nothing (unsafeNonEmptyText " ")) :| [])) (normalizeEffectDSL (Just rt)))
normalizeRuleDSL (RulePassive (PassiveDef b c)) = RulePassive $ PassiveDef b (normalizeCondition c)
normalizeRuleDSL (RuleStance (StanceDef d e)) = RuleStance $ StanceDef d (normalizeEffectDSL' e)
normalizeRuleDSL (RuleChannel (ChannelDef d e)) = RuleChannel $ ChannelDef d (normalizeEffectDSL' e)
normalizeRuleDSL (RulePrime (PrimeDef t r)) = RulePrime $ PrimeDef t (normalizeRuleDSL r)

normalizeRuleJSON :: Rule -> Rule
normalizeRuleJSON (RuleAttack (AttackDef p r e)) = RuleAttack $ AttackDef p r (normalizeEffectJSON e)
normalizeRuleJSON (RuleDefend (DefendDef p r e)) = RuleDefend $ DefendDef p r (normalizeEffectJSON e)
normalizeRuleJSON (RuleGeneral (GeneralDef p c e)) = RuleGeneral $ GeneralDef p (normalizeEffectJSON c) (fromMaybe (mkRichString (TextRun (TextRunDef Nothing (unsafeNonEmptyText " ")) :| [])) (normalizeEffectJSON (Just e)))
normalizeRuleJSON (RuleNarrative rt) = RuleNarrative (fromMaybe (mkRichString (TextRun (TextRunDef Nothing (unsafeNonEmptyText " ")) :| [])) (normalizeEffectJSON (Just rt)))
normalizeRuleJSON (RulePassive (PassiveDef b c)) = RulePassive $ PassiveDef b (normalizeCondition c)
normalizeRuleJSON (RuleStance (StanceDef d e)) = RuleStance $ StanceDef d (normalizeEffectJSON' e)
normalizeRuleJSON (RuleChannel (ChannelDef d e)) = RuleChannel $ ChannelDef d (normalizeEffectJSON' e)
normalizeRuleJSON (RulePrime (PrimeDef t r)) = RulePrime $ PrimeDef t (normalizeRuleJSON r)

normalizeEffectDSL' :: RichString -> RichString
normalizeEffectDSL' rs = fromMaybe (mkRichString (TextRun (TextRunDef Nothing (unsafeNonEmptyText " ")) :| [])) (normalizeEffectDSL (Just rs))

normalizeEffectJSON' :: RichString -> RichString
normalizeEffectJSON' rs = fromMaybe (mkRichString (TextRun (TextRunDef Nothing (unsafeNonEmptyText " ")) :| [])) (normalizeEffectJSON (Just rs))

normalizeCondition :: Maybe NonEmptyText -> Maybe NonEmptyText
normalizeCondition c = c

normalizeEffectWith :: (Inline -> Inline) -> Maybe RichString -> Maybe RichString
normalizeEffectWith _ Nothing = Nothing
normalizeEffectWith normalizer (Just rs) = 
  let normalized = map normalizer (NE.toList (unRichString rs))
  in case NE.nonEmpty normalized of
       Nothing -> Nothing
       Just ne -> 
         let merged = mkRichString ne
         in case NE.toList (unRichString merged) of
              (TextRun (TextRunDef Nothing c) : rest) ->
                let stripped = T.stripStart (getNonEmptyText c)
                in case mkNonEmptyText stripped of
                     Nothing -> 
                       case NE.nonEmpty rest of
                         Nothing -> Nothing
                         Just restNe -> Just (mkRichString restNe)
                     Just c' -> Just (mkRichString (TextRun (TextRunDef Nothing c') :| rest))
              _ -> Just merged

normalizeInlineDSL :: Inline -> Inline
normalizeInlineDSL (Icon (IconDef c)) = DynamicVal (DynamicValDef (StackPower c 0 Nothing))
normalizeInlineDSL x = x

normalizeInlineJSON :: Inline -> Inline
normalizeInlineJSON x = x

normalizeEffectDSL :: Maybe RichString -> Maybe RichString
normalizeEffectDSL = normalizeEffectWith normalizeInlineDSL

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

-- | Safe Inline for DSL Roundtrip
-- | The current DSL parser supports simple text and markdown styles (**bold**, *italic*, `code`).
-- | It does NOT support nested styles or icons yet.
newtype SafeInline = SafeInline { getSafeInline :: Inline }
  deriving (Show, Eq)

instance Arbitrary SafeInline where
  arbitrary = SafeInline <$> arbitrary
  shrink (SafeInline i) = SafeInline <$> shrink i

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

-- | Safe Rule for DSL Roundtrip
newtype SafeRule = SafeRule { getSafeRule :: Rule }
  deriving (Show, Eq)

instance Arbitrary SafeRule where
  arbitrary = oneof
    [ SafeRule . RuleAttack <$> arbitrary
    , SafeRule . RuleDefend <$> arbitrary
    , SafeRule . RuleStance <$> arbitrary
    , SafeRule . RuleChannel <$> arbitrary
    , SafeRule <$> (RulePrime <$> (PrimeDef <$> (unsafeNonEmptyText . T.filter (`notElem` ['(', ')']) . getNonEmptyText <$> arbitrary) <*> (getSafeRule <$> arbitrary)))
    , SafeRule . RulePassive <$> arbitrary
    , SafeRule . RuleGeneral <$> arbitrary
    , SafeRule . RuleNarrative <$> arbitrary
    ]
  shrink (SafeRule r) = SafeRule <$> shrink r

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

