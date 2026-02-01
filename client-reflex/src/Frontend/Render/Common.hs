-- | Common rendering utilities and types for the frontend.
module Frontend.Render.Common
  ( IconMode (..)
  ) where

import Data.Default (Default (..))

-- | Icon display mode for resource symbols and stat values
data IconMode = IconInline | IconBlock | IconResponsive
  deriving (Eq, Show, Enum, Bounded)

instance Default IconMode where
  def = IconInline
