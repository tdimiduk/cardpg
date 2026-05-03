{-# LANGUAGE OverloadedRecordDot #-}
{-# LANGUAGE OverloadedStrings #-}
{-# OPTIONS_GHC -Wno-type-defaults #-}

-- | Card rendering functions.
-- | This module provides explicit functions for rendering various card types.
module Frontend.Card
  ( CardDisplayMode (..)
  , CardSettings (..)
  , StatsDisplayMode (..)
  , StatsSettings (..)
  , renderCoreCard
  , renderCoreCardWith
  , renderStats
  , renderStatsWith
  , renderItemCard
  , renderItemCardWith
  , renderNatureCard
  , renderNatureCardWith
  , renderIdentified
  ) where

import Data.Default (Default (..))
import Reflex.Dom.Core

import Core.Card
  ( CoreCard (..)
  , Identified (..)
  , ItemCard (..)
  , NatureCard (..)
  , Stats (..)
  )
import Core.Stats (ResourceType (..), getStatValue)
import Core.Util (tshow)

import Frontend.Render.Common (IconMode (..), renderNonEmptyText)
import Frontend.Render.Rules (renderAttackDef, renderRichText, renderRule, renderStatValue)
import Frontend.Style qualified as Style
  ( artBase
  , artPrint
  , artScreen
  , cardBase
  , cardPrint
  , cardRow
  , cardScreen
  , costBase
  , costPrint
  , costRow
  , costScreen
  , nameBase
  , namePrint
  , nameScreen
  , textboxBase
  , textboxPrint
  , textboxScreen
  )
import Frontend.Style.Common
  ( Style
  , componentS
  , divS
  )
import Frontend.Style.DSL qualified as S
import Frontend.Style.Layout (row, spacer)
import Frontend.Svg (renderHexagon)

--------------------------------------------------------------------------------
-- Display Mode Types
--------------------------------------------------------------------------------

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

--------------------------------------------------------------------------------
-- Styling Helpers
--------------------------------------------------------------------------------

cardClasses :: CardSettings -> Style
cardClasses settings = case settings.displayMode of
  CardFull -> Style.cardBase . Style.cardScreen
  CardPrint -> Style.cardBase . Style.cardPrint
  CardRow -> Style.cardRow

artClasses :: CardSettings -> Style
artClasses settings = case settings.displayMode of
  CardFull -> Style.artBase . Style.artScreen
  CardPrint -> Style.artBase . Style.artPrint
  CardRow -> S.hidden

nameClasses :: CardSettings -> Style
nameClasses settings = case settings.displayMode of
  CardFull -> Style.nameBase . Style.nameScreen
  CardPrint -> Style.nameBase . Style.namePrint
  CardRow -> S.fontBold . S.textTruncate . S.flex1

costClasses :: CardSettings -> Style
costClasses settings = case settings.displayMode of
  CardFull -> Style.costBase . Style.costScreen
  CardPrint -> Style.costBase . Style.costPrint
  CardRow -> Style.costRow

textboxClasses :: CardSettings -> Style
textboxClasses settings = case settings.displayMode of
  CardFull -> Style.textboxBase . Style.textboxScreen
  CardPrint -> Style.textboxBase . Style.textboxPrint
  CardRow -> S.hidden

--------------------------------------------------------------------------------
-- Stats Rendering
--------------------------------------------------------------------------------

-- | Render stats with default settings (column layout, responsive icons)
renderStats :: (DomBuilder t m) => Stats Int -> m ()
renderStats = renderStatsWith def

-- | Render stats with custom settings
renderStatsWith :: (DomBuilder t m) => StatsSettings -> Stats Int -> m ()
renderStatsWith settings s =
  let layoutStyle = case settings.statsLayout of
        StatsCol ->
          S.flexCol
            . S.justifyBetween
            . S.gap S.S1
            . S.wFit
            . S.hFull
            . S.pr S.S1
            . S.pb S.S1
            . S.itemsCenter
        StatsRow -> S.flex . S.gap S.S1
   in componentS "stats" layoutStyle $
        mapM_
          (renderStatValue settings.statsIconMode . flip getStatValue s)
          [Red, Yellow, Blue]

--------------------------------------------------------------------------------
-- CoreCard Rendering
--------------------------------------------------------------------------------

-- | Render a CoreCard with default settings
renderCoreCard :: (DomBuilder t m) => CoreCard -> m ()
renderCoreCard = renderCoreCardWith def

-- | Render a CoreCard with custom settings
renderCoreCardWith :: (DomBuilder t m) => CardSettings -> CoreCard -> m ()
renderCoreCardWith settings c = case settings.displayMode of
  CardRow -> divS (cardClasses settings) $ do
    componentS "name" (nameClasses settings) $ renderNonEmptyText c.name
    maybe blank (\c' -> renderHexagon (costClasses settings) (Just $ tshow c')) c.cost
    spacer
    renderStatsWith (StatsSettings StatsRow IconResponsive) c.stats
  CardFull -> divS (cardClasses settings) $ do
    row $ do
      componentS "name" (nameClasses settings) $ renderNonEmptyText c.name
      spacer
      maybe blank (\c' -> renderHexagon (costClasses settings) (Just $ tshow c')) c.cost
    componentS "top" (S.flexRow . S.grow0 . S.shrink0 . S.h2_5) $ do
      renderStatsWith (StatsSettings StatsCol IconResponsive) c.stats
      componentS "art" (artClasses settings) blank
    componentS "rules" (textboxClasses settings) $ do
      maybe blank (divClass "action" . el "p" . renderAttackDef) c.attack
      mapM_ (mapM_ (divClass "action" . el "p" . renderRule)) c.rules
      mapM_ renderRichText c.flavor
  CardPrint -> divS (cardClasses settings) $ do
    row $ do
      componentS "name" (nameClasses settings) $ renderNonEmptyText c.name
      spacer
      maybe blank (\c' -> renderHexagon (costClasses settings) (Just $ tshow c')) c.cost
    componentS "top" (S.flexRow . S.grow0 . S.shrink0 . S.h2_5) $ do
      renderStatsWith (StatsSettings StatsCol IconResponsive) c.stats
      componentS "art" (artClasses settings) blank
    componentS "rules" (textboxClasses settings) $ do
      maybe blank (divClass "action" . el "p" . renderAttackDef) c.attack
      mapM_ (mapM_ (divClass "action" . el "p" . renderRule)) c.rules
      mapM_ renderRichText c.flavor

--------------------------------------------------------------------------------
-- ItemCard Rendering
--------------------------------------------------------------------------------

-- | Render an ItemCard with default settings
renderItemCard :: (DomBuilder t m) => ItemCard -> m ()
renderItemCard = renderItemCardWith def

-- | Render an ItemCard with custom settings
renderItemCardWith :: (DomBuilder t m) => CardSettings -> ItemCard -> m ()
renderItemCardWith settings c = divS (cardClasses settings) $ do
  componentS "name" (nameClasses settings) $ renderNonEmptyText c.name
  divS (artClasses settings) blank
  componentS "rules" (textboxClasses settings) $ do
    mapM_ (el "p" . text) c.passive
    mapM_ renderRichText c.flavor

--------------------------------------------------------------------------------
-- NatureCard Rendering
--------------------------------------------------------------------------------

-- | Render a NatureCard with default settings
renderNatureCard :: (DomBuilder t m) => NatureCard -> m ()
renderNatureCard = renderNatureCardWith def

-- | Render a NatureCard with custom settings
renderNatureCardWith :: (DomBuilder t m) => CardSettings -> NatureCard -> m ()
renderNatureCardWith settings c = divS (cardClasses settings) $ do
  componentS "name" (nameClasses settings) $ renderNonEmptyText c.name
  divS (artClasses settings) blank
  componentS "rules" (textboxClasses settings) $ do
    mapM_ (el "p" . text) c.passive
    mapM_ renderRichText c.flavor

--------------------------------------------------------------------------------
-- Identified Wrapper Rendering
--------------------------------------------------------------------------------

-- | Render an Identified wrapper by delegating to the inner render function
renderIdentified :: (a -> m ()) -> Identified id a -> m ()
renderIdentified renderInner (Identified _ content) = renderInner content
