module CardPG.Core.Types
  ( ResourceType(..)
  )
where

import Data.Aeson (ToJSON, FromJSON)
import GHC.Generics (Generic)

data ResourceType = Red | Yellow | Blue
  deriving stock (Eq,Show, Generic)
  deriving anyclass (ToJSON, FromJSON)
