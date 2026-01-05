{-# LANGUAGE OverloadedStrings #-}

module Frontend.Catalog (catalogWidget) where

import Data.List.NonEmpty (NonEmpty (..))
import Data.Text (Text)
import Reflex.Dom.Core

import CardPG.Core.Card
import CardPG.Core.NonEmptyText (NonEmptyText, unsafeNonEmptyText)
import CardPG.Core.RichText (unsafeSimpleString)
import CardPG.Core.Stats

-- Import the Render instance
import Frontend.Card ()
import Frontend.Html (Render (..))

catalogWidget :: (DomBuilder t m) => m ()
catalogWidget = do
  el "h1" $ text "Component Catalog"

  el "h2" $ text "Core Cards"
  divClass "cards" $ do
    render exampleAttack
    render exampleSkill
    render exampleHeavyText

  el "h2" $ text "Card Elements"
  -- We can also render individual parts if needed, but rendering full cards is best for now
  text "Individual elements (TODO)"

-- | Example Data
mkText :: Text -> NonEmptyText
mkText = unsafeNonEmptyText

exampleAttack :: CoreCard
exampleAttack =
  CoreCard
    { name = mkText "Strike"
    , tags = Just $ "Melee" :| ["Attack"]
    , stats = Stats{red = 3, yellow = 3, blue = 1}
    , cost = Just 1
    , rules = Just $ RuleAttack attackDef :| []
    , flavor = Nothing
    }
  where
    attackDef =
      AttackDef
        { power = StackPower Red 2 Nothing
        , resistedBy = Red
        , effect = Just $ unsafeSimpleString "Deal damage."
        }

exampleSkill :: CoreCard
exampleSkill =
  CoreCard
    { name = mkText "Focus"
    , tags = Just $ "Skill" :| []
    , stats = Stats{red = 0, yellow = 0, blue = 2}
    , cost = Nothing
    , rules = Just $ RuleGeneral generalDef :| []
    , flavor = Just $ unsafeSimpleString "Calm your mind."
    }
  where
    generalDef =
      GeneralDef
        { name = mkText "Meditate"
        , cost = Nothing
        , difficulty = Nothing
        , effect = unsafeSimpleString "Restore 1 Focus."
        }

exampleHeavyText :: CoreCard
exampleHeavyText =
  CoreCard
    { name = mkText "Ancient Tome"
    , tags = Just $ "Item" :| ["Lore"]
    , stats = Stats{red = 0, yellow = 1, blue = 1}
    , cost = Just 2
    , rules = Just $ RulePassive passiveDef :| [RuleTrigger triggerDef]
    , flavor =
        Just $ unsafeSimpleString "The pages crumble at your touch, yet the words burn into your mind."
    }
  where
    passiveDef =
      PassiveDef
        { bonus = StackPower Blue 1 (Just "Intelligence")
        , condition = Nothing
        }
    triggerDef =
      TriggerDef
        { trigger = mkText "You play a Blue card"
        , effect = unsafeSimpleString "Draw a card."
        }
