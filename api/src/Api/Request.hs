module Api.Request where

import Data.Aeson (Value)
import Data.Aeson.GADT.TH (deriveJSONGADT)
import Data.Constraint.Extras.TH (deriveArgDict)
import Data.GADT.Compare.TH (deriveGCompare, deriveGEq)
import Data.GADT.Show.TH (deriveGShow)
import Data.Text (Text)
import Data.UUID (UUID)

import Api.Types (Command, StateUpdate)

data ApiRequest a where
  Join :: Text -> ApiRequest (Either Text UUID)
  GameAction :: Command -> ApiRequest (Either Text [StateUpdate])

deriveGShow ''ApiRequest
deriveGEq ''ApiRequest
deriveGCompare ''ApiRequest
deriveArgDict ''ApiRequest
deriveJSONGADT ''ApiRequest
