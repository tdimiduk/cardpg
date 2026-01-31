{-# LANGUAGE DataKinds #-}
{-# LANGUAGE ExtendedDefaultRules #-}
{-# LANGUAGE FlexibleInstances #-}
{-# LANGUAGE MultiParamTypeClasses #-}
{-# LANGUAGE OrPatterns #-}
{-# LANGUAGE QuantifiedConstraints #-}
{-# LANGUAGE TypeApplications #-}
{-# LANGUAGE TypeFamilies #-}
{-# LANGUAGE UndecidableInstances #-}
{-# OPTIONS_GHC -Wno-orphans #-}
{-# OPTIONS_GHC -Wno-type-defaults #-}

module Frontend.Card
  ( CardDisplayMode (..)
  , CardSettings (..)
  , StatsDisplayMode (..)
  , StatsSettings (..)
  , renderWith
  ) where

import Data.Default (Default (..))
import Reflex.Dom.Core

import Core.Card
import Core.Language (cmdAttack)
import Core.Render
  ( ComputeRenderMode
  , IconMode (..)
  , Render (..)
  , RenderMode (..)
  , RenderStrategy (..)
  )

import Core.Render.Rule ()
import Core.Stats
  ( ResourceType (..)
  , getStatValue
  )
import Core.Util (tshow)

import Frontend.Html ()
import Frontend.Style (CssClass, component, divStyle, row, spacer)
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

instance (Monad m, DomBuilder t m, ComputeRenderMode m ~ 'HtmlMode) => RenderStrategy 'HtmlMode CoreCard m where
  type StrategyConfig 'HtmlMode CoreCard = CardSettings
  renderStrategyWith settings c = case settings.displayMode of
    CardRow -> divStyle (cardClasses settings) $ do
      component "name" (nameClasses settings) $ renderStrategy @'HtmlMode c.name
      maybe blank (\c' -> renderHexagon (costClasses settings) (Just $ tshow c')) (c.cost)
      spacer
      renderStrategyWith @'HtmlMode (StatsSettings StatsRow IconResponsive) c.stats
    CardFull -> scalable 63 88 $ divStyle (cardClasses settings) $ do
      row $ do
        component "name" (nameClasses settings) $ renderStrategy @'HtmlMode c.name
        spacer
        maybe blank (\c' -> renderHexagon (costClasses settings) (Just $ tshow c')) (c.cost)
      component "top" [Style.flex, Style.flexRow, "grow-0", "shrink-0", "h-2/5"] $ do
        renderStrategyWith @'HtmlMode (StatsSettings StatsCol IconResponsive) c.stats
        component "art" (artClasses settings) blank
      component "rules" (textboxClasses settings) $ do
        maybe
          blank
          (\atk -> divClass "action" $ el "p" $ render cmdAttack >> text " " >> renderStrategy @'HtmlMode atk)
          c.attack
        renderStrategy @'HtmlMode c.rules
        renderStrategy @'HtmlMode c.flavor
    CardPrint -> divStyle (cardClasses settings) $ do
      row $ do
        component "name" (nameClasses settings) $ renderStrategy @'HtmlMode c.name
        spacer
        maybe blank (\c' -> renderHexagon (costClasses settings) (Just $ tshow c')) (c.cost)
      component "top" [Style.flex, Style.flexRow, "grow-0", "shrink-0", "h-2/5"] $ do
        renderStrategyWith @'HtmlMode (StatsSettings StatsCol IconResponsive) c.stats
        component "art" (artClasses settings) blank
      component "rules" (textboxClasses settings) $ do
        maybe
          blank
          (\atk -> divClass "action" $ el "p" $ render cmdAttack >> text " " >> renderStrategy @'HtmlMode atk)
          c.attack
        renderStrategy @'HtmlMode c.rules
        renderStrategy @'HtmlMode c.flavor

instance (Monad m, DomBuilder t m, ComputeRenderMode m ~ 'HtmlMode) => RenderStrategy 'HtmlMode (Stats Int) m where
  type StrategyConfig 'HtmlMode (Stats Int) = StatsSettings
  renderStrategyWith settings s =
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
        mapM_
          (renderStrategyWith @'HtmlMode settings.statsIconMode . flip getStatValue s)
          [Red, Yellow, Blue]

-- Rules rendering to match legacy textbox style
instance (Monad m, DomBuilder t m, ComputeRenderMode m ~ 'HtmlMode) => RenderStrategy 'HtmlMode Rule m where
  renderStrategy rule = divClass "action" $ el "p" $ case rule of
    RuleGeneral x -> renderStrategy @'HtmlMode x
    RuleTask x -> renderStrategy @'HtmlMode x
    RuleTrigger x -> renderStrategy @'HtmlMode x
    RuleOngoing x -> renderStrategy @'HtmlMode x
    RuleNarrative x -> renderStrategy @'HtmlMode x
    RulePassive x -> renderStrategy @'HtmlMode x

-- Identified instance remains using bridge if convenient, or switch.
-- Identified wrapper usually proxies config. StrategyConfig 'HtmlMode (Identified id a) = StrategyConfig 'HtmlMode a.
-- The generic instance in Core/Render.hs handles this? No, Core doesn't know Identified.
-- Identified is in Core/Card.hs? No, Core/Identified.hs?
-- Wait, the instance in Card.hs was: instance ... => Render (Identified id a) m.
-- I changed it to RenderStrategy 'HtmlMode (Identified id a) m.
-- It delegates to renderStrategyWith cfg content.
-- This uses renderStrategyWith for 'HtmlMode. So clear.

instance
  (Monad m, DomBuilder t m, RenderStrategy 'HtmlMode a m, ComputeRenderMode m ~ 'HtmlMode)
  => RenderStrategy 'HtmlMode (Identified id a) m
  where
  type StrategyConfig 'HtmlMode (Identified id a) = StrategyConfig 'HtmlMode a
  renderStrategyWith cfg (Identified _ content) = renderStrategyWith @'HtmlMode cfg content

instance (Monad m, DomBuilder t m, ComputeRenderMode m ~ 'HtmlMode) => RenderStrategy 'HtmlMode ItemCard m where
  type StrategyConfig 'HtmlMode ItemCard = CardSettings
  renderStrategyWith settings c = divStyle (cardClasses settings) $ do
    component "name" (nameClasses settings) $ renderStrategy @'HtmlMode c.name
    divStyle (artClasses settings) blank
    component "rules" (textboxClasses settings) $ do
      renderStrategy @'HtmlMode c.passive
      renderStrategy @'HtmlMode c.flavor

instance (Monad m, DomBuilder t m, ComputeRenderMode m ~ 'HtmlMode) => RenderStrategy 'HtmlMode NatureCard m where
  type StrategyConfig 'HtmlMode NatureCard = CardSettings
  renderStrategyWith settings c = divStyle (cardClasses settings) $ do
    component "name" (nameClasses settings) $ renderStrategy @'HtmlMode c.name
    divStyle (artClasses settings) blank
    component "rules" (textboxClasses settings) $ do
      renderStrategy @'HtmlMode c.passive
      renderStrategy @'HtmlMode c.flavor
