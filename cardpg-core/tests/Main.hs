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
import Data.Aeson (encode, eitherDecode, ToJSON, FromJSON)
import Data.Text (Text)
import qualified Data.Text as T
import Data.List.NonEmpty (NonEmpty(..))
import qualified Data.List.NonEmpty as NE

import CardPG.Core.Card
import CardPG.Core.Types
import CardPG.Core.RichText

main :: IO ()
main = defaultMain tests

tests :: TestTree
tests = testGroup "Tests"
  [ testProperty "JSON Roundtrip" prop_jsonRoundtrip
  ]

prop_jsonRoundtrip :: DeckCard -> Property
prop_jsonRoundtrip x = 
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

instance Arbitrary DeckCard where
  arbitrary = genericArbitrary uniform

instance Arbitrary IconDef where
  arbitrary = genericArbitrary uniform

instance Arbitrary DynamicValDef where
  arbitrary = genericArbitrary uniform

-- Helper for NonEmpty
instance Arbitrary a => Arbitrary (NonEmpty a) where
  arbitrary = do
    x <- arbitrary
    xs <- arbitrary
    return (x :| xs)
