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
import Web.Atomic.CSS.Layout (flexCol, flexRow)
import Web.Atomic.Types (CSS, Rule)

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
import Frontend.Style.Class (MonadStyle, StyledDomBuilder)
import Frontend.Style.Common
  ( Style
  , component
  , componentT
  , divT
  , toStyle
  )
import Frontend.Style.Common qualified as Style
import Frontend.Style.DSL qualified as S
import Frontend.Style.Layout (row, spacer)
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
renderStats :: (DomBuilder t m, MonadStyle m) => Stats Int -> m ()
renderStats = renderStatsWith def

-- | Render stats with custom settings
renderStatsWith :: (StyledDomBuilder t m, MonadStyle m) => StatsSettings -> Stats Int -> m ()
renderStatsWith settings s =
  let layoutStyle = case settings.statsLayout of
        StatsCol ->
          S.flexCol
            . S.justifyBetween
            . S.gap1
            . S.wFit
            . S.hFull
            . S.pr1
            . S.pb1
            . S.itemsCenter
        StatsRow -> S.flex . S.gap1
   in componentT "stats" layoutStyle $
        mapM_
          (renderStatValue settings.statsIconMode . flip getStatValue s)
          [Red, Yellow, Blue]

--------------------------------------------------------------------------------
-- CoreCard Rendering
--------------------------------------------------------------------------------

-- | Render a CoreCard with default settings
renderCoreCard :: (DomBuilder t m, MonadStyle m) => CoreCard -> m ()
renderCoreCard = renderCoreCardWith def

-- | Render a CoreCard with custom settings
renderCoreCardWith :: (DomBuilder t m, MonadStyle m) => CardSettings -> CoreCard -> m ()
renderCoreCardWith settings c = case settings.displayMode of
  CardRow -> divT (cardClasses settings) $ do
    componentT "name" (nameClasses settings) $ renderNonEmptyText c.name
    maybe blank (\c' -> renderHexagon (costClasses settings mempty) (Just $ tshow c')) c.cost
    spacer
    renderStatsWith (StatsSettings StatsRow IconResponsive) c.stats
  CardFull -> scalable 63 88 $ divT (cardClasses settings) $ do
    row $ do
      componentT "name" (nameClasses settings) $ renderNonEmptyText c.name
      spacer
      maybe blank (\c' -> renderHexagon (costClasses settings mempty) (Just $ tshow c')) c.cost
    componentT "top" (S.flexRow . S.grow0 . S.shrink0 . S.h2_5) $ do
      renderStatsWith (StatsSettings StatsCol IconResponsive) c.stats
      componentT "art" (artClasses settings) blank
    componentT "rules" (textboxClasses settings) $ do
      maybe blank (divClass "action" . el "p" . renderAttackDef) c.attack
      mapM_ (mapM_ (divClass "action" . el "p" . renderRule)) c.rules
      mapM_ renderRichText c.flavor
  CardPrint -> divT (cardClasses settings) $ do
    row $ do
      componentT "name" (nameClasses settings) $ renderNonEmptyText c.name
      spacer
      maybe blank (\c' -> renderHexagon (costClasses settings mempty) (Just $ tshow c')) c.cost
    componentT "top" (S.flexRow . S.grow0 . S.shrink0 . S.h2_5) $ do
      renderStatsWith (StatsSettings StatsCol IconResponsive) c.stats
      componentT "art" (artClasses settings) blank
    componentT "rules" (textboxClasses settings) $ do
      maybe blank (divClass "action" . el "p" . renderAttackDef) c.attack
      mapM_ (mapM_ (divClass "action" . el "p" . renderRule)) c.rules
      mapM_ renderRichText c.flavor

--------------------------------------------------------------------------------
-- ItemCard Rendering
--------------------------------------------------------------------------------

-- | Render an ItemCard with default settings
renderItemCard :: (DomBuilder t m, MonadStyle m) => ItemCard -> m ()
renderItemCard = renderItemCardWith def

-- | Render an ItemCard with custom settings
renderItemCardWith :: (DomBuilder t m, MonadStyle m) => CardSettings -> ItemCard -> m ()
renderItemCardWith settings c = divT (cardClasses settings) $ do
  componentT "name" (nameClasses settings) $ renderNonEmptyText c.name
  divT (artClasses settings) blank
  componentT "rules" (textboxClasses settings) $ do
    mapM_ (el "p" . text) c.passive
    mapM_ renderRichText c.flavor

--------------------------------------------------------------------------------
-- NatureCard Rendering
--------------------------------------------------------------------------------

-- | Render a NatureCard with default settings
renderNatureCard :: (DomBuilder t m, MonadStyle m) => NatureCard -> m ()
renderNatureCard = renderNatureCardWith def

-- | Render a NatureCard with custom settings
renderNatureCardWith :: (DomBuilder t m, MonadStyle m) => CardSettings -> NatureCard -> m ()
renderNatureCardWith settings c = divT (cardClasses settings) $ do
  componentT "name" (nameClasses settings) $ renderNonEmptyText c.name
  divT (artClasses settings) blank
  componentT "rules" (textboxClasses settings) $ do
    mapM_ (el "p" . text) c.passive
    mapM_ renderRichText c.flavor

--------------------------------------------------------------------------------
-- Identified Wrapper Rendering
--------------------------------------------------------------------------------

-- | Render an Identified wrapper by delegating to the inner render function
renderIdentified :: (a -> m ()) -> Identified id a -> m ()
renderIdentified renderInner (Identified _ content) = renderInner content
