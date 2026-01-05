{-# LANGUAGE ExtendedDefaultRules #-}
{-# LANGUAGE FlexibleInstances #-}
{-# LANGUAGE UndecidableInstances #-}
{-# OPTIONS_GHC -Wno-orphans #-}
{-# OPTIONS_GHC -Wno-type-defaults #-}

module Frontend.Card
  (
  ) where

import Data.List (intersperse)
import Data.Maybe (catMaybes)

import Reflex.Dom.Core

import CardPG.Core.Card
import CardPG.Core.NonEmptyText (getRawText)
import CardPG.Core.Stats
  ( ResourceType (..)
  , getStatValue
  )
import CardPG.Core.Util (tshow)

import Frontend.Card.Common (art, inParensLS)
import Frontend.Html

instance (DomBuilder t m) => Render CoreCard m where
  render c = divClass "card" $ do
    divClass "flex" $ do
      divClass "name" $ text $ getRawText c.name
      divClass "expand" blank
      maybe blank (divClass "cost" . text . tshow) (c.cost)
    divClass "flex" $ do
      render c.stats
      art
    divClass "textbox" $ do
      render c.rules
      render c.flavor

instance (DomBuilder t m) => Render (Stats Int) m where
  render s = divClass "numbers" $ mapM_ (render . flip getStatValue s) [Red, Yellow, Blue]

-- Rules rendering to match legacy textbox style
instance (DomBuilder t m) => Render Rule m where
  render rule = divClass "action" $ case rule of
    RuleAttack x -> render x
    RuleGeneral x -> render x
    RuleTask x -> render x
    RuleTrigger x -> render x
    RuleOngoing x -> render x
    RuleNarrative x -> render x
    RulePassive x -> render x

instance (DomBuilder t m) => Render AttackDef m where
  render d = do
    el "p" $ do
      text "Attack "
      render d.resistedBy
      text ": "
      render d.power
      maybe blank render d.effect

instance (DomBuilder t m) => Render GeneralDef m where
  render d = do
    el "p" $ do
      text "Action: "
      text $ getRawText d.name
      maybe blank inParensLS (d.cost)
      maybe blank (\x -> text " " >> render x) d.difficulty
      text " -> "
      render d.effect

instance (DomBuilder t m) => Render TaskDef m where
  render d = do
    el "p" $ do
      text "Task: "
      text $ getRawText d.name

      let checkPart = fmap (\x -> text "Check " >> render x) d.check
          timePart = fmap (\x -> text "Time " >> render x) d.time
          costPart = fmap (\x -> text "Cost " >> render x) d.cost
          parts = catMaybes [checkPart, timePart, costPart]

      case parts of
        [] -> blank
        ps -> do
          text " ("
          sequence_ $ intersperse (text "; ") ps
          text ")"

      text " -> "
      render d.effect

instance (DomBuilder t m, Render a m) => Render (Identified id a) m where
  render (Identified _ content) = render content

instance (DomBuilder t m) => Render TriggerDef m where
  render d = do
    el "p" $ do
      text $ "When " <> getRawText d.trigger
      text " -> "
      render d.effect

instance (DomBuilder t m) => Render OngoingDef m where
  render d = do
    el "p" $ do
      text "Ongoing ("
      render d.life
      text ")"
      text " -> "
      render d.effect

instance (DomBuilder t m) => Render PassiveDef m where
  render d = do
    el "p" $ do
      text "Passive: "
      render d.bonus
      maybe blank (\t -> text (" " <> getRawText t)) d.condition

-- TODO: Render stack power fully
