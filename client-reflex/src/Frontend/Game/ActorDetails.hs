module Frontend.Game.ActorDetails
  ( actorDetailsWidget
  ) where

import Control.Monad.Fix (MonadFix)
import Reflex.Dom.Core
import Prelude hiding (filter, id, map, (.))

import Api.Request (ApiRequest)
import Core.Primitives (ActorId)
import Core.State (ActorState)

import Frontend.Game.ActorDetails.Assets (equippedWidget, traitsWidget)
import Frontend.Game.ActorDetails.Consequences (consequencesWidget)
import Frontend.Game.ActorDetails.Deck (deckWidget)
import Frontend.Game.ActorDetails.Stats (statsWidget)
import Frontend.Style

actorDetailsWidget
  :: ( DomBuilder t m
     , PostBuild t m
     , MonadHold t m
     , MonadFix m
     , Adjustable t m
     , Requester t m
     , Request m ~ ApiRequest
     )
  => ActorId
  -> Dynamic t ActorState
  -> m ()
actorDetailsWidget actorId actorState = component "actor-details" [flex, flexCol, "gap-2", "w-full"] $ do
  deckWidget actorId actorState

  statsWidget actorState

  consequencesWidget actorId actorState

  equippedWidget actorState

  traitsWidget actorState
