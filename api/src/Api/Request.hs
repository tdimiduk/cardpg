module Api.Request where

import Data.Aeson (Value)
import Data.Aeson.GADT.TH (deriveJSONGADT)
import Data.Constraint.Extras.TH (deriveArgDict)
import Data.GADT.Compare.TH (deriveGCompare, deriveGEq)
import Data.GADT.Show.TH (deriveGShow)
import Data.Text (Text)
import Data.UUID (UUID)

import Core.Primitives (ActorId, CardInstanceId)

import Api.Types (Command, StateUpdate)

data ApiRequest a where
  Join :: Text -> ApiRequest (Either Text UUID)
  GameAction :: Command -> ApiRequest (Either Text [StateUpdate])
  DrawCards :: ActorId -> ApiRequest (Either Text [StateUpdate])
  ReshuffleDeck :: ActorId -> ApiRequest (Either Text [StateUpdate])
  AddConsequence :: ActorId -> Maybe Int -> ApiRequest (Either Text [StateUpdate])
  RemoveConsequence :: ActorId -> CardInstanceId -> ApiRequest (Either Text [StateUpdate])

deriveGShow ''ApiRequest
deriveGEq ''ApiRequest
deriveGCompare ''ApiRequest
deriveArgDict ''ApiRequest
deriveJSONGADT ''ApiRequest
