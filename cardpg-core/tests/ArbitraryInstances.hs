{-# LANGUAGE DeriveGeneric #-}
{-# LANGUAGE StandaloneDeriving #-}
{-# LANGUAGE GeneralisedNewtypeDeriving #-}
{-# LANGUAGE FlexibleInstances #-}
{-# LANGUAGE ScopedTypeVariables #-}
{-# LANGUAGE DisambiguateRecordFields #-}
{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE RecordWildCards #-}
{-# OPTIONS_GHC -fno-warn-orphans #-}

module ArbitraryInstances where

import Test.Tasty.QuickCheck
import Generic.Random
import qualified Data.Text as T
import Data.Text (Text)
import Data.List.NonEmpty (NonEmpty(..))
import qualified Data.List.NonEmpty as NE

import CardPG.Core.Card
import CardPG.Core.Types
import CardPG.Core.RichText
import CardPG.Core.NonEmptyText (NonEmptyText(..), unsafeNonEmptyText, getNonEmptyText)


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
          t <- T.pack <$> listOf1 (elements ['a'..'z'])
          pure $ Just $ "(" <> t <> ")"
      ]
    pure $ StackPower base modVal cond
  shrink = genericShrink

instance Arbitrary TextStyle where
  arbitrary = genericArbitrary uniform
  shrink = genericShrink

instance Arbitrary Inline where
  arbitrary = genericArbitrary uniform

instance Arbitrary RichString where
  arbitrary = do
    inlines <- listOf1 arbitrary
    case mkRichString inlines of
      Nothing -> return $ unsafeSimpleString "empty" -- Fallback, though listOf1 shouldn't be empty, stripping might make it empty
      Just rs -> return rs
  shrink rs = 
    [ rs'
    | l <- shrink (NE.toList (unRichString rs))
    , not (null l)
    , Just rs' <- [mkRichString l]
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
