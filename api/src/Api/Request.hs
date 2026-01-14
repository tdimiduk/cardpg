module Api.Request where

import Data.Aeson.GADT.TH (deriveJSONGADT)
import Data.Constraint.Extras.TH (deriveArgDict)
import Data.GADT.Compare.TH (deriveGCompare, deriveGEq)
import Data.GADT.Show.TH (deriveGShow)
import Data.Text (Text)
import Data.UUID (UUID)

import Core.Primitives (ActorId, CardInstanceId, CardLocation, ChallengeId)
import Core.Stats (ResourceType)

import Api.Types (StateUpdate)

data ApiRequest a where
  Join :: Text -> ApiRequest (Either Text UUID)
  SendChat :: Maybe ActorId -> Text -> ApiRequest () -- We'll get the message we sent as a push
  -- Game Actions (Mirrors Command enum)
  DrawCards :: ActorId -> ApiRequest (Either Text [StateUpdate])
  Defend :: ActorId -> ChallengeId -> ApiRequest (Either Text [StateUpdate])
  PlanMove :: ActorId -> Int -> Int -> ApiRequest (Either Text [StateUpdate])
  PlanAction
    :: ActorId -> CardInstanceId -> [CardInstanceId] -> ApiRequest (Either Text [StateUpdate])
  PlanNarrative
    :: ActorId -> [CardInstanceId] -> ResourceType -> ApiRequest (Either Text [StateUpdate])
  CancelPlan :: ActorId -> ApiRequest (Either Text [StateUpdate])
  StartResolution :: ApiRequest (Either Text [StateUpdate])
  EndDefense :: ActorId -> ApiRequest (Either Text [StateUpdate])
  Reshuffle :: ActorId -> ApiRequest (Either Text [StateUpdate])
  AddStatus :: ActorId -> Text -> CardLocation -> ApiRequest (Either Text [StateUpdate])
  DestroyStatus :: ActorId -> Text -> Maybe CardInstanceId -> ApiRequest (Either Text [StateUpdate])
  AddConsequence :: ActorId -> Maybe Int -> ApiRequest (Either Text [StateUpdate])
  DestroyConsequence :: ActorId -> CardInstanceId -> ApiRequest (Either Text [StateUpdate])
  DiscardCards :: ActorId -> [CardInstanceId] -> ApiRequest (Either Text [StateUpdate])
  ReturnToDeck :: ActorId -> [CardInstanceId] -> ApiRequest (Either Text [StateUpdate])
  EndRound :: ApiRequest (Either Text [StateUpdate])
  Pass :: ActorId -> ApiRequest (Either Text [StateUpdate])

deriveGShow ''ApiRequest
deriveGEq ''ApiRequest
deriveGCompare ''ApiRequest
deriveArgDict ''ApiRequest
deriveJSONGADT ''ApiRequest
