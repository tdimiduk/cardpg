{-# LANGUAGE ExtendedDefaultRules #-}
{-# LANGUAGE FlexibleInstances #-}
{-# LANGUAGE OrPatterns #-}
{-# LANGUAGE QuantifiedConstraints #-}
{-# LANGUAGE UndecidableInstances #-}
{-# OPTIONS_GHC -Wno-orphans #-}
{-# OPTIONS_GHC -Wno-type-defaults #-}

module Frontend.Card
  ( CardDisplayMode (..)
  , CardSettings (..)
  , StatsDisplayMode (..)
  , StatsSettings (..)
  ) where

import Data.Default (Default (..))
import Reflex.Dom.Core

import Core.Card
import Core.Render (IconMode (..))

import Core.Render.Rule ()
import Core.Stats
  ( ResourceType (..)
  , getStatValue
  )
import Core.Util (tshow)

import Frontend.Html
import Frontend.Style (CssClass, component, divStyle, row, rowWith, spacer)
import Frontend.Style qualified as Style
import Frontend.Svg (renderHexagon)
import Frontend.UI.Scaler (scalable)

data CardDisplayMode = CardFull | CardPrint | CardRow
  deriving (Eq, Show, Enum, Bounded)

newtype CardSettings = CardSettings
  { displayMode :: CardDisplayMode
  }
  deriving (Eq, Show)

instance Default CardSettings where
  def = CardSettings CardFull

data StatsDisplayMode = StatsRow | StatsCol
  deriving (Eq, Show)

data StatsSettings = StatsSettings
  { statsLayout :: StatsDisplayMode
  , statsIconMode :: IconMode
  }
  deriving (Eq, Show)

instance Default StatsSettings where
  def = StatsSettings StatsCol IconResponsive

-- Styling Helpers

-- Styling Helpers

cardClasses :: CardSettings -> [CssClass]
cardClasses settings = case settings.displayMode of
  CardFull -> Style.cardBase <> Style.cardScreen
  CardPrint -> Style.cardBase <> Style.cardPrint
  CardRow -> Style.cardRow

artClasses :: CardSettings -> [CssClass]
artClasses settings = case settings.displayMode of
  CardFull -> Style.artBase <> Style.artScreen
  CardPrint -> Style.artBase <> Style.artPrint
  CardRow -> [Style.hidden]

nameClasses :: CardSettings -> [CssClass]
nameClasses settings = case settings.displayMode of
  CardFull -> Style.nameBase <> Style.nameScreen
  CardPrint -> Style.nameBase <> Style.namePrint
  CardRow -> [Style.fontBold, Style.truncateText, "flex-1"]

costClasses :: CardSettings -> [CssClass]
costClasses settings = case settings.displayMode of
  CardFull -> Style.costBase <> Style.costScreen
  CardPrint -> Style.costBase <> Style.costPrint
  CardRow -> Style.costRow

textboxClasses :: CardSettings -> [CssClass]
textboxClasses settings = case settings.displayMode of
  CardFull -> Style.textboxBase <> Style.textboxScreen
  CardPrint -> Style.textboxBase <> Style.textboxPrint
  CardRow -> [Style.hidden]

instance (Monad m, DomBuilder t m) => Render CoreCard m where
  type RenderConfig CoreCard = CardSettings
  renderWith settings c = case settings.displayMode of
    CardRow -> divStyle (cardClasses settings) $ do
      component "name" (nameClasses settings) $ render c.name
      maybe blank (\c' -> renderHexagon (costClasses settings) (Just $ tshow c')) (c.cost)
      spacer
      renderWith (StatsSettings StatsRow IconResponsive) c.stats
    CardFull -> scalable 63 88 $ divStyle (cardClasses settings) $ do
      row $ do
        component "name" (nameClasses settings) $ render c.name
        spacer
        maybe blank (\c' -> renderHexagon (costClasses settings) (Just $ tshow c')) (c.cost)
      component "top" [Style.flex, Style.flexRow, "grow-0", "shrink-0", "h-2/5"] $ do
        renderWith (StatsSettings StatsCol IconResponsive) c.stats
        component "art" (artClasses settings) blank
      component "rules" (textboxClasses settings) $ do
        render c.rules
        render c.flavor
    CardPrint -> divStyle (cardClasses settings) $ do
      row $ do
        component "name" (nameClasses settings) $ render c.name
        spacer
        maybe blank (\c' -> renderHexagon (costClasses settings) (Just $ tshow c')) (c.cost)
      component "top" [Style.flex, Style.flexRow, "grow-0", "shrink-0", "h-2/5"] $ do
        renderWith (StatsSettings StatsCol IconResponsive) c.stats
        component "art" (artClasses settings) blank
      component "rules" (textboxClasses settings) $ do
        render c.rules
        render c.flavor

instance (Monad m, DomBuilder t m) => Render (Stats Int) m where
  type RenderConfig (Stats Int) = StatsSettings
  renderWith settings s =
    let
      layoutClasses = case settings.statsLayout of
        StatsCol ->
          [ Style.flex
          , Style.flexCol
          , Style.justifyBetween
          , "gap-1"
          , "w-fit"
          , "h-full"
          , "pr-1"
          , "pb-1"
          , "items-center"
          ]
        StatsRow -> [Style.flex, "gap-1"]
     in
      component "stats" layoutClasses $
        mapM_ (renderWith settings.statsIconMode . flip getStatValue s) [Red, Yellow, Blue]

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
  type RenderConfig (Identified id a) = RenderConfig a
  renderWith cfg (Identified _ content) = renderWith cfg content

instance (Monad m, DomBuilder t m) => Render ItemCard m where
  type RenderConfig ItemCard = CardSettings
  renderWith settings c = divStyle (cardClasses settings) $ do
    component "name" (nameClasses settings) $ render c.name
    divStyle (artClasses settings) blank
    component "rules" (textboxClasses settings) $ do
      render c.passive
      render c.flavor

instance (Monad m, DomBuilder t m) => Render NatureCard m where
  type RenderConfig NatureCard = CardSettings
  renderWith settings c = divStyle (cardClasses settings) $ do
    component "name" (nameClasses settings) $ render c.name
    divStyle (artClasses settings) blank
    component "rules" (textboxClasses settings) $ do
      render c.passive
      render c.flavor
