{-# LANGUAGE FlexibleContexts #-}
{-# LANGUAGE OverloadedStrings #-}

module Frontend.Icons
  ( Icon
  , iconClose
  , iconDeck
  , iconRefresh
  , iconDefense
  , iconResilience
  , iconSkull
  , iconUser
  , iconSword
  , iconCheck
  , iconNote
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

-- | Dark Fantasy Shield Icon for Defense
iconDefense :: (DomBuilder t m) => m ()
iconDefense = do
  let attrs =
        "width" =: "100%"
          <> "height" =: "100%"
          <> "viewBox" =: "0 0 512 512"
          <> "fill" =: "currentColor"
          <> "stroke" =: "none"
          <> "class" =: "icon-defense"
  svgEl "svg" attrs $
    svgPath
      "M256 16c25 24 100 72 150 72v96c0 96-75 240-150 312-75-72-150-216-150-312V88c50 0 125-48 150-72z"

-- | Dark Fantasy Sprout Icon for Resilience
iconResilience :: (DomBuilder t m) => m ()
iconResilience = iconSprout

-- | Nature Sprout Icon for Resilience
iconSprout :: (DomBuilder t m) => m ()
iconSprout = do
  let attrs =
        "width" =: "100%"
          <> "height" =: "100%"
          <> "viewBox" =: "0 0 512 512"
          <> "fill" =: "currentColor"
          <> "stroke" =: "none"
          <> "class" =: "icon-sprout"
  svgEl "svg" attrs $
    svgPath
      "M255.688 18S198.118 84.876 199 148.875c.11 7.924 1.104 15.806 2.78 23.53 23.498 25.825 43.035 57.618 58.19 95 13.85-31.163 30.07-60.016 50.03-84.967 3.764-12.817 6.056-26.13 5.875-39.313-.88-64-60.188-125.125-60.188-125.125zM24.094 111.47c.138 1.77.174 2.98.406 5.186a251.39 251.39 0 0 0 6.813 37.22c7.703 29.27 22.952 64.12 52.25 87.81 16.455 13.308 40.276 20.756 64.593 27.064s48.935 11.302 67.594 23.156c14.984 9.52 24.296 24.148 28.375 40.813 4.08 16.663 3.338 35.387-.72 55.06-7.072 34.304-24.28 71.737-46.874 105.908h126.44c-22.767-34.427-39.985-72.006-46.94-106.438-3.982-19.722-4.637-38.51-.436-55.188 4.2-16.677 13.665-31.284 28.75-40.78 18.79-11.83 43.49-16.743 67.812-22.938 24.322-6.196 48.034-13.46 64.313-26.625 47.514-38.425 57.337-105.795 59.405-130.19-61.585 1.928-106.926 21.097-142.406 52.19-37.42 32.788-64.065 79.142-85.345 132.436l-5.28 13.156-10.033-10.03-1.53-1.532-.688-2.063C210.397 177.51 133.342 115.054 24.094 111.47z"

-- | Lucide 'skull' Icon
iconSkull :: (DomBuilder t m) => m ()
iconSkull = iconBase "lucide-skull" $ do
  svgPath
    "M12 2a5 5 0 0 0-5 5v3a3 3 0 0 0-3 3v2a5 5 0 0 0 2 4v2a2 2 0 0 0 2 2h8a2 2 0 0 0 2-2v-2a5 5 0 0 0 2-4v-2a3 3 0 0 0-3-3V7a5 5 0 0 0-5-5z"
  svgPath "M9 14h.01"
  svgPath "M15 14h.01"

-- | Lucide 'user' Icon
iconUser :: (DomBuilder t m) => m ()
iconUser = iconBase "lucide-user" $ do
  svgPath "M19 21v-2a4 4 0 0 0-4-4H9a4 4 0 0 0-4 4v2"
  svgPath "M12 11a4 4 0 1 0 0-8 4 4 0 0 0 0 8z"

-- | Lucide 'sword' Icon
iconSword :: (DomBuilder t m) => m ()
iconSword = iconBase "lucide-sword" $ do
  svgPath "M14.5 17.5 3 6V3h3l11.5 11.5z"
  svgPath "M13 19h2"
  svgPath "M16 16v2"
  svgPath "M19 13v2"

-- | Lucide 'check' Icon
iconCheck :: (DomBuilder t m) => m ()
iconCheck =
  iconBase "lucide-check" $
    svgPath "M20 6 9 17l-5-5"

-- | Lucide 'sticky-note' Icon
iconNote :: (DomBuilder t m) => m ()
iconNote =
  iconBase "lucide-sticky-note" $
    svgPath "M15 2H6a2 2 0 0 0-2 2v16a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2V7z M14 2v4a1 1 0 0 0 1 1h4"
