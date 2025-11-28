{-# LANGUAGE DeriveGeneric #-}
{-# LANGUAGE DerivingStrategies #-}
{-# LANGUAGE StandaloneDeriving #-}
{-# LANGUAGE GeneralisedNewtypeDeriving #-}
{-# LANGUAGE FlexibleInstances #-}
{-# LANGUAGE ScopedTypeVariables #-}
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

