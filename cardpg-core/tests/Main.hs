{-# LANGUAGE DeriveGeneric #-}
{-# LANGUAGE DerivingStrategies #-}
{-# LANGUAGE StandaloneDeriving #-}
{-# LANGUAGE GeneralisedNewtypeDeriving #-}
{-# LANGUAGE FlexibleInstances #-}
{-# LANGUAGE ScopedTypeVariables #-}
{-# LANGUAGE DisambiguateRecordFields #-}
{-# OPTIONS_GHC -fno-warn-orphans #-}

module Main where

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
  in counterexample (show encoded) $ decoded === Right x

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
  in counterexample (show encoded) $ decoded === Right x

prop_dslRoundtrip :: SafeRule -> Property
prop_dslRoundtrip (SafeRule r) = 
  let printed = prettyRule r
      parsed = parseRule printed
  in counterexample ("Original: " ++ show r ++ "\nPrinted: " ++ show printed ++ "\nParsed: " ++ show parsed) $ parsed === Right r

-- Arbitrary Instances

-- Arbitrary Instances

instance Arbitrary Text where
  arbitrary = T.pack <$> listOf (elements ['a'..'z'])

instance Arbitrary ResourceType where
  arbitrary = genericArbitrary uniform

instance Arbitrary StackPower where
  arbitrary = genericArbitrary uniform

instance Arbitrary TextStyle where
  arbitrary = genericArbitrary uniform

instance Arbitrary TextRunDef where
  arbitrary = genericArbitrary uniform

instance Arbitrary Inline where
  arbitrary = genericArbitrary uniform

-- | Safe Inline for DSL Roundtrip
-- | The current DSL parser supports simple text and markdown styles (**bold**, *italic*, `code`).
-- | It does NOT support nested styles or icons yet.
newtype SafeInline = SafeInline { getSafeInline :: Inline }
  deriving (Show, Eq)

instance Arbitrary SafeInline where
  arbitrary = oneof
    [ simpleText
    , styledText Bold
    , styledText Italic
    , styledText GameKeyword
    ]
    where
      -- Generate text without special characters that trigger markdown parsing
      safeText = T.pack <$> listOf1 (elements $ ['a'..'z'] ++ ['0'..'9'] ++ [' '])
      
      simpleText = do
        c <- safeText
        return $ SafeInline $ TextRun $ TextRunDef Nothing c
        
      styledText style = do
        c <- safeText
        return $ SafeInline $ TextRun $ TextRunDef (Just style) c

newtype SafeRichString = SafeRichString { getSafeRichString :: RichString }
  deriving (Show, Eq)

instance Arbitrary SafeRichString where
  arbitrary = do
    -- Generate a list of inlines, but ensure we don't have adjacent simple text runs
    -- because the parser merges them (or rather, parses them as separate chunks but semantically they are adjacent).
    -- Actually, the parser produces [TextRun "a", TextRun "b"] if they are separated by nothing?
    -- No, textParser consumes until special char.
    -- So "ab" becomes [TextRun "ab"].
    -- But "a*b*c" becomes [TextRun "a", TextRun "b" (italic), TextRun "c"].
    -- If we generate [TextRun "a", TextRun "b"], printed as "ab", parsed as [TextRun "ab"].
    -- So we still have the merging issue for adjacent plain text.
    -- We can enforce that adjacent inlines are NOT both plain text?
    -- Or just rely on the fact that `safeText` generates non-empty strings and we can just generate a list of styled/plain.
    -- Wait, if we generate [TextRun "a", TextRun "b"], printed "ab", parsed [TextRun "ab"].
    -- Original != Parsed.
    -- So we should probably merge adjacent plain text runs in the generator?
    -- Or just generate a list where no two adjacent items are plain text?
    -- Let's try generating a list of SafeInlines, then merging adjacent plain text runs.
    inlines <- listOf1 (getSafeInline <$> arbitrary)
    return $ SafeRichString (mergeAdjacentText inlines)

mergeAdjacentText :: [Inline] -> [Inline]
mergeAdjacentText (TextRun (TextRunDef Nothing c1) : TextRun (TextRunDef Nothing c2) : xs) =
  mergeAdjacentText (TextRun (TextRunDef Nothing (c1 <> c2)) : xs)
mergeAdjacentText (x:xs) = x : mergeAdjacentText xs
mergeAdjacentText [] = []

-- | Safe Rule for DSL Roundtrip
newtype SafeRule = SafeRule { getSafeRule :: Rule }
  deriving (Show, Eq)

instance Arbitrary SafeRule where
  arbitrary = oneof
    [ do
        p <- arbitrary
        r <- arbitrary
        e <- fmap getSafeRichString <$> arbitrary
        return $ SafeRule $ RuleAttack $ AttackDef p r e
    , do
        p <- arbitrary
        rs <- arbitrary
        e <- fmap getSafeRichString <$> arbitrary
        return $ SafeRule $ RuleDefend $ DefendDef p rs e
    , do
        rt <- getSafeRichString <$> arbitrary
        return $ SafeRule $ RuleNarrative rt
    ]

instance Arbitrary Block where
  arbitrary = genericArbitrary uniform

instance Arbitrary PassiveDef where
  arbitrary = genericArbitrary uniform

instance Arbitrary AttackDef where
  arbitrary = genericArbitrary uniform

instance Arbitrary DefendDef where
  arbitrary = genericArbitrary uniform

instance Arbitrary GeneralDef where
  arbitrary = genericArbitrary uniform

instance Arbitrary StanceDef where
  arbitrary = genericArbitrary uniform

instance Arbitrary ChannelDef where
  arbitrary = genericArbitrary uniform

instance Arbitrary PrimeDef where
  arbitrary = genericArbitrary uniform

instance Arbitrary Rule where
  arbitrary = genericArbitrary uniform

instance Arbitrary Stats where
  arbitrary = genericArbitrary uniform

instance Arbitrary CoreCard where
  arbitrary = genericArbitrary uniform

instance Arbitrary ItemCard where
  arbitrary = genericArbitrary uniform

instance Arbitrary NatureCard where
  arbitrary = genericArbitrary uniform

instance Arbitrary TalentCard where
  arbitrary = genericArbitrary uniform

instance Arbitrary EncounterCard where
  arbitrary = genericArbitrary uniform

instance Arbitrary ConsequenceCard where
  arbitrary = genericArbitrary uniform

instance Arbitrary IconDef where
  arbitrary = genericArbitrary uniform

instance Arbitrary DynamicValDef where
  arbitrary = genericArbitrary uniform

instance Arbitrary GeneralActionDef where
  arbitrary = genericArbitrary uniform

instance Arbitrary EncounterMechanics where
  arbitrary = genericArbitrary uniform

-- Helper for NonEmpty
instance Arbitrary a => Arbitrary (NonEmpty a) where
  arbitrary = do
    x <- arbitrary
    xs <- arbitrary
    return (x :| xs)

