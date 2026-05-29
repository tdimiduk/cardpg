{-# LANGUAGE FlexibleContexts #-}
{-# LANGUAGE OverloadedStrings #-}

module Frontend.Icons
  ( Icon
  , iconClose
  , iconDeck
  , iconRefresh
  ) where

import Data.Text (Text)
import Reflex.Dom.Core

import Frontend.Svg (svgEl, svgPath)
import Frontend.Svg.Path (CubicBezier, Vec2, mkPath, moveRel, moveTo, neg, negC)

-- | An Icon is just a widget that renders an SVG.
type Icon t m = (DomBuilder t m) => m ()

-- | Helper to wrap content in a standard 24x24 SVG.
iconBase :: (DomBuilder t m) => Text -> m () -> m ()
iconBase className content =
  let attrs =
        "width" =: "100%"
          <> "height" =: "100%"
          <> "viewBox" =: "0 0 24 24"
          <> "fill" =: "none"
          <> "stroke" =: "currentColor"
          <> "stroke-width" =: "2"
          <> "stroke-linecap" =: "round"
          <> "stroke-linejoin" =: "round"
          <> "class" =: className
   in svgEl "svg" attrs content

-- | Lucide 'x' Icon
iconClose :: (DomBuilder t m) => m ()
iconClose = iconBase "lucide-x" $ do
  svgPath "M18 6 6 18"
  svgPath "m6 6 12 12"

-- | Custom Deck Icon
iconDeck :: (DomBuilder t m) => m ()
iconDeck = do
  let attrs =
        "width" =: "100%"
          <> "height" =: "100%"
          <> "viewBox" =: "0 0 512 512"
          <> "fill" =: "currentColor"
          <> "stroke" =: "none"
          <> "class" =: "icon-deck"

  -- Geometry Data
  let vShort, vLong :: Vec2
      vShort = (-169, -66)
      vLong = (232, -111)

      -- Top Face Corners
      cLeft, cTop, cRight, cBottom :: CubicBezier
      cLeft = ((-14, -6), (-14, -17), (0, -24))
      cTop = ((20, -7), (39, -7), (59, -3))
      cRight = negC cLeft
      cBottom = negC cTop

      -- Body Thickness Caps
      capLeft, joinCenter, capRight, joinBottom :: CubicBezier
      capLeft = ((-28, -12), (-30, -28), (-14, -42))
      joinCenter = ((42, 16), (104, 14), (146, -6))
      capRight = ((16, 12), (12, 28), (-14, 42))
      joinBottom = ((-30, 14), (-82, 16), (-118, 6))

  -- Path Construction
  let pathTop =
        mkPath
          [ (vShort, cLeft)
          , (vLong, cTop)
          , (neg vShort, cRight)
          , (neg vLong, cBottom)
          ]

      pathBody =
        mkPath
          [ (vShort, capLeft)
          , (neg vShort, joinCenter)
          , (vLong, capRight)
          , (neg vLong, joinBottom)
          ]

  -- Assemble Layers
  let d =
        mconcat $
          concat $
            [ moveTo (195, 230)
            , pathTop
            , pathBody
            ]
              ++ [moveRel (0, 82) ++ pathBody | _ <- [1 .. 3 :: Int]]

  svgEl "svg" attrs $ svgPath d

-- | Lucide 'refresh-cw' Icon
iconRefresh :: (DomBuilder t m) => m ()
iconRefresh = iconBase "lucide-refresh-cw" $ do
  svgPath "M3 12a9 9 0 0 1 9-9 9.75 9.75 0 0 1 6.74 2.74L21 8"
  svgPath "M21 3v5h-5"
  svgPath "M21 12a9 9 0 0 1-9 9 9.75 9.75 0 0 1-6.74-2.74L3 16"
  svgPath "M8 16H3v5"
