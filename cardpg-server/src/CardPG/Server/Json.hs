module CardPG.Server.Json
  ( customOptions
  ) where

import Data.Aeson (Options(..), defaultOptions, SumEncoding(..))

-- | Custom Aeson options for JSON encoding
-- | Must match what was in Main.hs
customOptions :: Options
customOptions = defaultOptions
  { sumEncoding = TaggedObject "tag" "contents"
  }
