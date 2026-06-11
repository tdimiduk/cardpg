{-# LANGUAGE OverloadedStrings #-}

-- | SVG Path Data Construction DSL
--
-- Pure functions for building SVG path `d` attribute strings.
-- These are framework-agnostic and can be used with any SVG rendering approach.
module Frontend.Svg.Path
  ( -- * Types
    Vec2
  , CubicBezier

    -- * Vector Operations
  , neg
  , negC

    -- * Path Commands
  , vec
  , l
  , c
  , moveTo
  , moveRel

    -- * Path Builders
  , mkPath
  ) where

import Data.Text (Text, pack)

-- | A 2D vector (x, y)
type Vec2 = (Int, Int)

-- | Cubic Bezier control points: (control1, control2, endpoint)
type CubicBezier = (Vec2, Vec2, Vec2)

-- | Show an Int as Text
showInt :: Int -> Text
showInt = pack . show

-- | Format a vector as path data: " x y "
vec :: Vec2 -> [Text]
vec (x, y) = [" ", showInt x, " ", showInt y, " "]

-- | Line-to command (relative)
l :: Vec2 -> [Text]
l v = "l" : vec v

-- | Cubic Bezier command (relative)
c :: CubicBezier -> [Text]
c (v1, v2, v3) = "c" : vec v1 <> vec v2 <> vec v3

-- | Negate a vector
neg :: Vec2 -> Vec2
neg (x, y) = (-x, -y)

-- | Negate all control points in a Cubic Bezier
negC :: CubicBezier -> CubicBezier
negC (v1, v2, v3) = (neg v1, neg v2, neg v3)

-- | Absolute move-to command
moveTo :: Vec2 -> [Text]
moveTo (x, y) = "M" : vec (x, y)

-- | Relative move-to command
moveRel :: Vec2 -> [Text]
moveRel (dx, dy) = "m" : vec (dx, dy)

-- | Build a closed path from line + curve segment pairs
mkPath :: [(Vec2, CubicBezier)] -> [Text]
mkPath segments = concatMap (\(v, cp) -> l v ++ c cp) segments ++ ["z"]
