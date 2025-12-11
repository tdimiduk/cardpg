{-# LANGUAGE OverloadedStrings #-}

module CardPG.Core.Hardcoded where

import Data.List.NonEmpty (NonEmpty(..))

import CardPG.Core.Card (CoreCard, CoreCardT(..), Stats(..))
import CardPG.Core.NonEmptyText (unsafeNonEmptyText)
import CardPG.Core.RichText (unsafeSimpleString)
import CardPG.Core.RuleDefs (DSLRule(..), RuleT(RuleTask), TaskDefT(..))

-- | The canonical Fatigue Card
-- Hardcoded here as a fundamental mechanic of the engine.
-- Matches data/cards/status/core.yaml
fatigueCard :: CoreCard
fatigueCard = CoreCard
  { _id = Just "status-fatigue"
  , _name = unsafeNonEmptyText "Fatigue"
  , _tags = Just ("Status" :| ["Fatigue", "Physical"])
  , _stats = Stats 1 1 1
  , _cost = Nothing
  , _rules = Just $ 
      DSLRule (RuleTask $ TaskDef
        { _name = unsafeNonEmptyText "Sleep"
        , _check = Nothing
        , _time = Just (unsafeSimpleString "2 Hours")
        , _cost = Nothing
        , _effect = unsafeSimpleString "Remove this card."
        }) :|
      [ DSLRule (RuleTask $ TaskDef
        { _name = unsafeNonEmptyText "Light Rest"
        , _check = Nothing
        , _time = Just (unsafeSimpleString "4 Hours")
        , _cost = Nothing
        , _effect = unsafeSimpleString "Remove this card."
        })
      ]
  , _flavor = Just (unsafeSimpleString "Fatigue is setting in ...")
  }
