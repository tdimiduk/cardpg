{-# LANGUAGE ExtendedDefaultRules #-}
{-# LANGUAGE FlexibleInstances #-}
{-# LANGUAGE QuantifiedConstraints #-}
{-# LANGUAGE UndecidableInstances #-}
{-# OPTIONS_GHC -Wno-orphans #-}
{-# OPTIONS_GHC -Wno-type-defaults #-}

module Frontend.Card
  (
  ) where

import Reflex.Dom.Core

import CardPG.Core.Card
import CardPG.Core.NonEmptyText (getRawText)
import CardPG.Core.Render.Rule ()
import CardPG.Core.Stats
  ( ResourceType (..)
  , getStatValue
  )
import CardPG.Core.Util (tshow)

import Frontend.Card.Common (art)
import Frontend.Html

instance (Monad m, DomBuilder t m) => Render CoreCard m where
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

instance (Monad m, DomBuilder t m) => Render (Stats Int) m where
  render s = divClass "numbers" $ mapM_ (render . flip getStatValue s) [Red, Yellow, Blue]

-- Rules rendering to match legacy textbox style
instance (Monad m, DomBuilder t m) => Render Rule m where
  render rule = divClass "action" $ el "p" $ case rule of
    RuleAttack x -> render x
    RuleGeneral x -> render x
    RuleTask x -> render x
    RuleTrigger x -> render x
    RuleOngoing x -> render x
    RuleNarrative x -> render x
    RulePassive x -> render x

instance (Monad m, DomBuilder t m, Render a m) => Render (Identified id a) m where
  render (Identified _ content) = render content
