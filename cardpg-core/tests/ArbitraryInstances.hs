
{-# LANGUAGE DisambiguateRecordFields #-}
{-# LANGUAGE FlexibleInstances #-}
{-# LANGUAGE OverloadedRecordDot #-}
{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE ScopedTypeVariables #-}
{-# OPTIONS_GHC -fno-warn-orphans #-}

module ArbitraryInstances where

import Data.List.NonEmpty (NonEmpty (..))
import qualified Data.List.NonEmpty as NE
import Data.Maybe (fromMaybe)
import Data.Text (Text)
import qualified Data.Text as T
import Generic.Random
import Test.Tasty.QuickCheck

import CardPG.Core.Card
import CardPG.Core.DSL.Printer (richToString)
import CardPG.Core.NonEmptyText (NonEmptyText (..), getNonEmptyText, unsafeNonEmptyText)
import CardPG.Core.RichText
import CardPG.Core.Types

-- Arbitrary Instances

instance Arbitrary Text where
  arbitrary = T.pack <$> listOf (elements ['a' .. 'z'])
  shrink t = T.pack <$> shrink (T.unpack t)

instance Arbitrary ResourceType where
  arbitrary = genericArbitrary uniform
  shrink = genericShrink

instance Arbitrary StackPower where
  arbitrary = do
    base <- arbitrary
    modVal <- arbitrary
    cond <-
      oneof
        [ pure Nothing
        , do
            t <- T.pack <$> listOf1 (elements ['a' .. 'z'])
            pure $ Just $ "(" <> t <> ")"
        ]
    pure $ StackPower base modVal cond
  shrink = genericShrink

instance Arbitrary Difficulty where
  arbitrary = do
    attr <- arbitrary
    val <- getPositive <$> arbitrary
    pure $ Difficulty attr val
  shrink d = filter (\d' -> d'._value >= 1) (genericShrink d)

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
    | l <- shrink (NE.toList (unRichText (unRichString rs)))
    , not (null l)
    , Just rs' <- [mkRichString l]
    ]

instance Arbitrary Block where
  arbitrary = genericArbitrary uniform
  shrink = genericShrink

instance Arbitrary PassiveDef where
  arbitrary = genericArbitrary uniform
  shrink = genericShrink

instance (Arbitrary rt) => Arbitrary (AttackDefT rt) where
  arbitrary = genericArbitrary uniform
  shrink = genericShrink

instance (Arbitrary rt) => Arbitrary (GeneralDefT rt) where
  arbitrary = genericArbitrary uniform
  shrink = genericShrink

instance (Arbitrary rt) => Arbitrary (StanceDefT rt) where
  arbitrary = genericArbitrary uniform
  shrink = genericShrink

instance (Arbitrary rt) => Arbitrary (ChannelDefT rt) where
  arbitrary = genericArbitrary uniform
  shrink = genericShrink

instance Arbitrary (PrimeDefT RichString) where
  arbitrary = do
    trig <- arbitrary
    -- Break recursion by using a simple rule
    let simpleReaction = RuleNarrative (fromMaybe (unsafeSimpleString "Reaction") (simpleString "Reaction"))
    return $ PrimeDef trig simpleReaction
  shrink _ = []

instance (Arbitrary rt) => Arbitrary (TriggerDefT rt) where
  arbitrary = genericArbitrary uniform
  shrink = genericShrink

instance (Arbitrary rt) => Arbitrary (TaskDefT rt) where
  arbitrary = do
    name <- arbitrary
    check <- arbitrary
    time <- arbitrary
    cost <- arbitrary
    TaskDef name check time cost <$> arbitrary
  shrink = genericShrink

instance Arbitrary DSLBase where
  arbitrary =
    oneof
      [ RuleAttack <$> arbitrary
      , RuleGeneral <$> arbitrary
      , RuleTask <$> arbitrary
      , RuleTrigger <$> arbitrary
      , RuleStance <$> arbitrary
      , RuleChannel <$> arbitrary
      , RulePrime <$> arbitrary
      , RulePassive <$> arbitrary
      , RuleNarrative <$> arbitrarySafeRichString
      ]
  shrink = genericShrink

instance Arbitrary DSLRule where
  arbitrary = genericArbitrary uniform
  shrink = genericShrink

arbitrarySafeRichString :: Gen RichString
arbitrarySafeRichString = do
  rs <- arbitrary
  -- Ensure it doesn't start with a keyword
  let t = richToString rs
  if any (`T.isPrefixOf` t) keywords
    then arbitrarySafeRichString
    else return rs
  where
    keywords =
      [ "Attack"
      , "Action:"
      , "General:"
      , "Task:"
      , "When"
      , "Stance"
      , "Channel"
      , "Prime"
      , "Passive:"
      ]

-- Need richToString for the check, but it's in Printer.hs which imports RuleDefs.
-- ArbitraryInstances imports CardPG.Core.Card (which exports RuleDefs) and RichText.
-- It does NOT import Printer.
-- So I cannot use richToString here easily without circular dependency if Printer imports RuleDefs.
-- Printer imports RuleDefs. ArbitraryInstances imports RuleDefs.
-- So I can import Printer in ArbitraryInstances?
-- Printer imports RuleDefs. RuleDefs does NOT import Printer.
-- So ArbitraryInstances -> Printer -> RuleDefs.
-- ArbitraryInstances -> RuleDefs.
-- This is fine.

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
    t <- T.pack <$> listOf1 (elements ['a' .. 'z'])
    return $ unsafeNonEmptyText t
  shrink ne =
    [ unsafeNonEmptyText (T.pack s)
    | s <- shrink (T.unpack (getNonEmptyText ne))
    , not (null s)
    ]

-- Helper for NonEmpty
instance (Arbitrary a) => Arbitrary (NonEmpty a) where
  arbitrary = do
    x <- arbitrary
    xs <- arbitrary
    return (x :| xs)
  shrink ne = [NE.fromList l | l <- shrink (NE.toList ne), not (null l)]
