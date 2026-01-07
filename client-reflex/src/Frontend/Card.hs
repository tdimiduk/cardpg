{-# LANGUAGE ExtendedDefaultRules #-}
{-# LANGUAGE FlexibleInstances #-}
{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE QuantifiedConstraints #-}
{-# LANGUAGE UndecidableInstances #-}
{-# OPTIONS_GHC -Wno-orphans #-}
{-# OPTIONS_GHC -Wno-type-defaults #-}

module Frontend.Card
  ( CardDisplayMode (..)
  , CardSettings (..)
  ) where

import Data.Default (Default (..))
import Reflex.Dom.Core

import Core.Card
import Core.NonEmptyText (getRawText)
import Core.Render (IconMode (..))
import Core.Render.Rule ()
import Core.Stats
  ( ResourceType (..)
  , getStatValue
  )
import Core.Util (tshow)

import Frontend.Html
import Frontend.Style hiding (classes)
import Frontend.Style qualified as Style
import Frontend.Svg (renderHexagon)

data CardDisplayMode = CardFull | CardPrint | CardCompactVertical | CardCompactHorizontal
  deriving (Eq, Show, Enum, Bounded)

newtype CardSettings = CardSettings
  { displayMode :: CardDisplayMode
  }
  deriving (Eq, Show)

instance Default CardSettings where
  def = CardSettings CardFull

-- Styling Helpers

cardClasses :: CardSettings -> [Class]
cardClasses settings = case settings.displayMode of
  CardFull ->
    [ flex
    , flexCol
    , p1_5
    , "aspect-[63/88]"
    , wFull
    , hAuto
    , "break-inside-avoid"
    , relative
    , overflowHidden
    , "rounded-[3mm]"
    , border2
    , borderSlate600
    , bgSlate900
    , textSlate200
    , shadowXl
    ]
  CardPrint ->
    [ flex
    , flexCol
    , "aspect-auto"
    , "p-[2mm]"
    , "m-0"
    , "w-[56mm]"
    , "h-[80mm]"
    , "border-[0.2mm]"
    , roundedNone
    , bgWhite
    , textBlack
    , shadowNone
    , borderBlack
    , "break-inside-avoid"
    , relative
    , overflowHidden
    ]
  CardCompactVertical ->
    [ flex
    , flexRow
    , itemsCenter
    , "gap-1"
    , p1
    , bgSlate900
    , border
    , borderSlate700
    , rounded
    ]
  CardCompactHorizontal ->
    [ flex
    , flexCol
    , p1
    , bgSlate900
    , border
    , borderSlate700
    , rounded
    , textXs
    ]

artClasses :: CardSettings -> [Class]
artClasses settings = case settings.displayMode of
  CardFull -> ["grow", "h-full", roundedSm, bgSlate800]
  CardPrint -> ["h-[33mm]", roundedNone, bgTransparent]
  _ -> [hidden]

nameClasses :: CardSettings -> [Class]
nameClasses settings = case settings.displayMode of
  CardFull -> [textSm, fontBold, textSlate200]
  CardPrint -> [textSm, fontBold, textBlack]
  CardCompactVertical -> [fontBold, textSm, textSlate100, truncateText, "flex-1"]
  CardCompactHorizontal -> [fontBold, truncateText]

costClasses :: CardSettings -> [Class]
costClasses settings = case settings.displayMode of
  CardFull -> ["w-[1.4em]", "h-[1.4em]", "-my-[0.1em]", textSlate200]
  CardPrint -> ["w-[1.4em]", "h-[1.4em]", "-my-[0.1em]", textBlack]
  CardCompactVertical -> [textSlate200, "scale-75"]
  CardCompactHorizontal -> [textSlate200, "scale-50"]

textboxClasses :: CardSettings -> [Class]
textboxClasses settings = case settings.displayMode of
  CardFull ->
    [ "flex-1"
    , textXs
    , "border-[0.2mm]"
    , "p-[2mm]"
    , rounded
    , "bg-slate-800/50"
    , borderSlate600
    , grow
    , "[&_p]:mt-0"
    , "[&_p]:mb-[0.1em]"
    , "[&_p]:leading-tight"
    ]
  CardPrint ->
    [ "flex-1"
    , textXs
    , "border-[0.2mm]"
    , "p-[2mm]"
    , roundedNone
    , bgTransparent
    , borderBlack
    , grow
    , "[&_p]:mt-0"
    , "[&_p]:mb-[0.1em]"
    , "[&_p]:leading-tight"
    ]
  _ -> [hidden]

instance (Monad m, DomBuilder t m) => Render CoreCard m where
  type RenderConfig CoreCard = CardSettings
  renderWith settings c = case settings.displayMode of
    CardCompactVertical -> divStyle (cardClasses settings) $ do
      elAttr "div" ("data-component" =: "stats") $
        mapM_ (render . flip getStatValue c.stats) [Red, Yellow, Blue]
      elAttr "div" ("class" =: Style.classes (nameClasses settings) <> "data-component" =: "name") $
        text $
          getRawText c.name
      maybe blank (\c' -> renderHexagon (Style.classes $ costClasses settings) (Just $ tshow c')) (c.cost)
    CardCompactHorizontal -> divStyle (cardClasses settings) $ do
      divStyle
        [flex, justifyBetween, itemsCenter, borderB, borderSlate700, "pb-1", "mb-1"]
        $ do
          elAttr "div" ("class" =: Style.classes (nameClasses settings) <> "data-component" =: "name") $
            text $
              getRawText c.name
          maybe blank (\c' -> renderHexagon (Style.classes $ costClasses settings) (Just $ tshow c')) (c.cost)
      elAttr "div" ("class" =: Style.classes [flex, "justify-around"] <> "data-component" =: "stats") $ do
        mapM_ (render . flip getStatValue c.stats) [Red, Yellow, Blue]
    _ -> divStyle (cardClasses settings) $ do
      divStyle [flex] $ do
        elAttr "div" ("class" =: Style.classes (nameClasses settings) <> "data-component" =: "name") $
          text $
            getRawText c.name
        divStyle [grow] blank
        maybe blank (\c' -> renderHexagon (Style.classes $ costClasses settings) (Just $ tshow c')) (c.cost)
      divStyle [flex, "basis-[37.5%]", "grow-0", "shrink-0"] $ do
        elAttr
          "div"
          ( "class"
              =: Style.classes
                ["flex", "flex-col", justifyBetween, "h-full", "mt-0", "mb-1", "align-middle", itemsCenter]
              <> "data-component" =: "stats"
          )
          $ renderWith IconResponsive c.stats
        divStyle (artClasses settings) blank
      elAttr "div" ("class" =: Style.classes (textboxClasses settings) <> "data-component" =: "rules") $ do
        render c.rules
        render c.flavor

instance (Monad m, DomBuilder t m) => Render (Stats Int) m where
  type RenderConfig (Stats Int) = IconMode
  renderWith mode s = mapM_ (renderWith mode . flip getStatValue s) [Red, Yellow, Blue]

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
    divStyle [flex] $ do
      elAttr "div" ("class" =: Style.classes (nameClasses settings) <> "data-component" =: "name") $
        text $
          getRawText c.name
      divStyle [grow] blank
    divStyle [flex] $ do
      divStyle (artClasses settings) blank
    elAttr "div" ("class" =: Style.classes (textboxClasses settings) <> "data-component" =: "rules") $ do
      render c.passive
      render c.flavor

instance (Monad m, DomBuilder t m) => Render NatureCard m where
  type RenderConfig NatureCard = CardSettings
  renderWith settings c = divStyle (cardClasses settings) $ do
    divStyle [flex] $ do
      elAttr "div" ("class" =: Style.classes (nameClasses settings) <> "data-component" =: "name") $
        text $
          getRawText c.name
      divStyle [grow] blank
    divStyle [flex] $ do
      divStyle (artClasses settings) blank
    elAttr "div" ("class" =: Style.classes (textboxClasses settings) <> "data-component" =: "rules") $ do
      render c.passive
      render c.flavor
