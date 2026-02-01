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
import Core.Language (cmdAttack)
import Core.Stats (ResourceType (..), getStatValue)
import Core.Util (tshow)

import Frontend.Html (renderNonEmptyText, resourceSymbol)
import Frontend.Render.Common (IconMode (..))
import Frontend.Render.Rules (renderAttackDef, renderRichText, renderRule, renderStatValue)
import Frontend.Style (CssClass, component, divStyle, row, spacer)
import Frontend.Style qualified as Style
import Frontend.Svg (renderHexagon)
import Frontend.UI.Scaler (scalable)

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

--------------------------------------------------------------------------------
-- Stats Rendering
--------------------------------------------------------------------------------

-- | Render stats with default settings (column layout, responsive icons)
renderStats :: (DomBuilder t m) => Stats Int -> m ()
renderStats = renderStatsWith def

-- | Render stats with custom settings
renderStatsWith :: (DomBuilder t m) => StatsSettings -> Stats Int -> m ()
renderStatsWith settings s =
  let layoutClasses = case settings.statsLayout of
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
   in component "stats" layoutClasses $
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
  CardRow -> divStyle (cardClasses settings) $ do
    component "name" (nameClasses settings) $ renderNonEmptyText c.name
    maybe blank (\c' -> renderHexagon (costClasses settings) (Just $ tshow c')) c.cost
    spacer
    renderStatsWith (StatsSettings StatsRow IconResponsive) c.stats
  CardFull -> scalable 63 88 $ divStyle (cardClasses settings) $ do
    row $ do
      component "name" (nameClasses settings) $ renderNonEmptyText c.name
      spacer
      maybe blank (\c' -> renderHexagon (costClasses settings) (Just $ tshow c')) c.cost
    component "top" [Style.flex, Style.flexRow, "grow-0", "shrink-0", "h-2/5"] $ do
      renderStatsWith (StatsSettings StatsCol IconResponsive) c.stats
      component "art" (artClasses settings) blank
    component "rules" (textboxClasses settings) $ do
      maybe
        blank
        (\atk -> divClass "action" $ el "p" $ text cmdAttack >> text " " >> renderAttackDef atk)
        c.attack
      mapM_ (mapM_ (divClass "action" . el "p" . renderRule)) c.rules
      mapM_ renderRichText c.flavor
  CardPrint -> divStyle (cardClasses settings) $ do
    row $ do
      component "name" (nameClasses settings) $ renderNonEmptyText c.name
      spacer
      maybe blank (\c' -> renderHexagon (costClasses settings) (Just $ tshow c')) c.cost
    component "top" [Style.flex, Style.flexRow, "grow-0", "shrink-0", "h-2/5"] $ do
      renderStatsWith (StatsSettings StatsCol IconResponsive) c.stats
      component "art" (artClasses settings) blank
    component "rules" (textboxClasses settings) $ do
      maybe
        blank
        (\atk -> divClass "action" $ el "p" $ text cmdAttack >> text " " >> renderAttackDef atk)
        c.attack
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
renderItemCardWith settings c = divStyle (cardClasses settings) $ do
  component "name" (nameClasses settings) $ renderNonEmptyText c.name
  divStyle (artClasses settings) blank
  component "rules" (textboxClasses settings) $ do
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
renderNatureCardWith settings c = divStyle (cardClasses settings) $ do
  component "name" (nameClasses settings) $ renderNonEmptyText c.name
  divStyle (artClasses settings) blank
  component "rules" (textboxClasses settings) $ do
    mapM_ (el "p" . text) c.passive
    mapM_ renderRichText c.flavor

--------------------------------------------------------------------------------
-- Identified Wrapper Rendering
--------------------------------------------------------------------------------

-- | Render an Identified wrapper by delegating to the inner render function
renderIdentified :: (a -> m ()) -> Identified id a -> m ()
renderIdentified renderInner (Identified _ content) = renderInner content
