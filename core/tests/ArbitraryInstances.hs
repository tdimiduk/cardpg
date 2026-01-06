{-# LANGUAGE DisambiguateRecordFields #-}
{-# LANGUAGE FlexibleInstances #-}
{-# LANGUAGE OverloadedRecordDot #-}
{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE ScopedTypeVariables #-}
{-# OPTIONS_GHC -fno-warn-orphans #-}

module ArbitraryInstances where

import Data.List.NonEmpty (NonEmpty (..))
import Data.List.NonEmpty qualified as NE
import Data.Text (Text)
import Data.Text qualified as T
import Generic.Random
import Test.Tasty.QuickCheck

import Core.Card
import Core.DSL.Printer (richToString)
import Core.Language
  ( cmdAction
  , cmdAttack
  , cmdGeneral
  , cmdOngoing
  , cmdPassive
  , cmdTask
  , cmdWhen
  )
import Core.NonEmptyText (NonEmptyText, getRawText, unsafeNonEmptyText)
import Core.Primitives
import Core.RichText
  ( Block (..)
  , Inline (..)
  , RichText (..)
  , TextStyle (..)
  , getInlines
  , mkRichText
  )
import Core.State
import Core.Stats (Difficulty (..), ResourceType (..), StackPower (..), StatValue (..))
import Data.UUID.Types (UUID)
import Data.UUID.Types qualified as UUID

-- Arbitrary Instances

instance Arbitrary Text where
  arbitrary = T.pack <$> listOf (elements ['a' .. 'z'])
  shrink t = T.pack <$> shrink (T.unpack t)

instance Arbitrary ResourceType where
  arbitrary = genericArbitrary uniform
  shrink = genericShrink

instance Arbitrary StatValue where
  arbitrary = do
    c <- arbitrary
    v <- getNonNegative <$> arbitrary
    pure $ StatValue v c
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
  shrink d = filter (\d' -> d'.value >= 1) (genericShrink d)

instance Arbitrary TextStyle where
  arbitrary = genericArbitrary uniform
  shrink = genericShrink

instance Arbitrary Inline where
  arbitrary =
    oneof
      [ TextRun <$> arbitrary <*> arbitrary
      , ColorValue <$> arbitrary
      , DifficultyValue <$> arbitrary
      , pure Break
      ]

instance Arbitrary RichText where
  arbitrary = do
    inlines <- listOf1 arbitrary
    case mkRichText inlines of
      Nothing -> arbitrary
      Just rs -> do
        -- Ensure it doesn't start with a keyword
        let t = richToString rs
        if any (`T.isPrefixOf` t) keywords
          then arbitrary
          else return rs
    where
      keywords =
        [ cmdAttack
        , cmdAction
        , cmdGeneral
        , cmdTask
        , cmdWhen
        , cmdOngoing
        , cmdPassive
        ]
  shrink rs =
    [ rs'
    | l <- shrink (NE.toList (getInlines rs))
    , not (null l)
    , Just rs' <- [mkRichText l]
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

instance Arbitrary GeneralDef where
  arbitrary = genericArbitrary uniform
  shrink = genericShrink

instance Arbitrary OngoingDef where
  arbitrary = genericArbitrary uniform
  shrink = genericShrink

instance Arbitrary TriggerDef where
  arbitrary = genericArbitrary uniform
  shrink = genericShrink

instance Arbitrary TaskDef where
  arbitrary = do
    name <- arbitrary
    check <- arbitrary
    time <- arbitrary
    cost <- arbitrary
    TaskDef name check time cost <$> arbitrary
  shrink = genericShrink

instance Arbitrary Rule where
  arbitrary =
    oneof
      [ RuleAttack <$> arbitrary
      , RuleGeneral <$> arbitrary
      , RuleTask <$> arbitrary
      , RuleTrigger <$> arbitrary
      , RuleOngoing <$> arbitrary
      , RuleNarrative <$> arbitrary
      ]
  shrink = genericShrink

instance (Arbitrary a) => Arbitrary (Stats a) where
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
    | s <- shrink (T.unpack (getRawText ne))
    , not (null s)
    ]

-- Helper for NonEmpty
instance (Arbitrary a) => Arbitrary (NonEmpty a) where
  arbitrary = do
    x <- arbitrary
    xs <- arbitrary
    return (x :| xs)
  shrink ne = [NE.fromList l | l <- shrink (NE.toList ne), not (null l)]

-- State Types

instance Arbitrary UUID where
  arbitrary = UUID.fromWords <$> arbitrary <*> arbitrary <*> arbitrary <*> arbitrary
  shrink _ = [] -- UUIDs don't shrink meaningfully for uniqueness

instance Arbitrary CardInstanceId where
  arbitrary = CardInstanceId <$> arbitrary
  shrink (CardInstanceId u) = CardInstanceId <$> shrink u

instance Arbitrary TargetId where
  arbitrary = TargetId <$> arbitrary
  shrink (TargetId u) = TargetId <$> shrink u

instance Arbitrary CardKind where
  arbitrary = genericArbitrary uniform
  shrink = genericShrink

instance Arbitrary TableCard where
  arbitrary = genericArbitrary uniform
  shrink = genericShrink

instance Arbitrary CorePlayState where
  arbitrary = genericArbitrary uniform
  shrink = genericShrink

instance Arbitrary ActionStack where
  arbitrary = genericArbitrary uniform
  shrink = genericShrink

instance Arbitrary NarrativeStack where
  arbitrary = genericArbitrary uniform
  shrink = genericShrink

instance Arbitrary PlannedAction where
  arbitrary = genericArbitrary uniform
  shrink = genericShrink

instance Arbitrary SpatialState where
  arbitrary = genericArbitrary uniform
  shrink = genericShrink

instance Arbitrary ChallengeSource where
  arbitrary = genericArbitrary uniform
  shrink = genericShrink

instance Arbitrary ActiveChallenge where
  arbitrary = genericArbitrary uniform
  shrink = genericShrink

instance Arbitrary ChallengeId where
  arbitrary = ChallengeId <$> arbitrary
  shrink (ChallengeId u) = ChallengeId <$> shrink u

instance Arbitrary ActiveDefense where
  arbitrary = genericArbitrary uniform
  shrink = genericShrink

instance Arbitrary RevealedEffect where
  arbitrary = genericArbitrary uniform
  shrink = genericShrink

instance (Arbitrary id, Arbitrary a) => Arbitrary (Identified id a) where
  arbitrary = genericArbitrary uniform
  shrink = genericShrink

instance Arbitrary CoreCardState where
  arbitrary = genericArbitrary uniform
  shrink = genericShrink

instance Arbitrary EquipSlot where
  arbitrary = genericArbitrary uniform
  shrink = genericShrink

instance Arbitrary AssetState where
  arbitrary = genericArbitrary uniform
  shrink = genericShrink

instance Arbitrary TableState where
  arbitrary = genericArbitrary uniform
  shrink = genericShrink

instance Arbitrary ActorState where
  arbitrary = genericArbitrary uniform
  shrink = genericShrink
