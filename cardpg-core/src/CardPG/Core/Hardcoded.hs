module CardPG.Core.Hardcoded where

import Data.List.NonEmpty (NonEmpty (..))

import CardPG.Core.Card (CoreCard (..), Stats (..))
import CardPG.Core.NonEmptyText (unsafeNonEmptyText)
import CardPG.Core.RichText (unsafeSimpleString)
import CardPG.Core.RuleDefs (Rule (RuleTask), TaskDef (..))

-- | The canonical Fatigue Card
-- Hardcoded here as a fundamental mechanic of the engine.
-- Matches data/cards/status/core.yaml
fatigueCard :: CoreCard
fatigueCard =
  CoreCard
    { name = unsafeNonEmptyText "Fatigue"
    , tags = Just ("Status" :| ["Fatigue", "Physical"])
    , stats = Stats 1 1 1
    , cost = Nothing
    , rules =
        Just $
          RuleTask
            ( TaskDef
                { name = unsafeNonEmptyText "Sleep"
                , check = Nothing
                , time = Just (unsafeSimpleString "2 Hours")
                , cost = Nothing
                , effect = unsafeSimpleString "Remove this card."
                }
            )
            :| [ RuleTask
                   ( TaskDef
                       { name = unsafeNonEmptyText "Light Rest"
                       , check = Nothing
                       , time = Just (unsafeSimpleString "4 Hours")
                       , cost = Nothing
                       , effect = unsafeSimpleString "Remove this card."
                       }
                   )
               ]
    , flavor = Just (unsafeSimpleString "Fatigue is setting in ...")
    }
