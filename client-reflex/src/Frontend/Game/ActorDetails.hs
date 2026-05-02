{-# LANGUAGE DataKinds #-}

module Frontend.Game.ActorDetails
  ( actorDetailsWidget
  ) where

import Control.Monad.Fix (MonadFix)
import Reflex.Dom.Core
import Prelude hiding (filter, id, map)

import Api.Request (ApiRequest)
import Core.Primitives (ActorId)
import Core.State (ActorState)

import Frontend.Game.ActorDetails.Assets (equippedWidget, traitsWidget)
import Frontend.Game.ActorDetails.Consequences (consequencesWidget)
import Frontend.Game.ActorDetails.Deck (deckWidget)
import Frontend.Game.ActorDetails.Stats (statsWidget)

import Frontend.Style.Common
import Frontend.Style.DSL qualified as S

actorDetailsWidget
  :: ( DomBuilder t m
     , PostBuild t m
     , MonadHold t m
     , MonadFix m
     , Adjustable t m
     , Requester t m
     , Request m ~ ApiRequest
     , Prerender t m
     )
  => ActorId
  -> Dynamic t ActorState
  -> m ()
actorDetailsWidget actorId actorState = componentS "actor-details" (S.flexCol . S.gap 2 . S.wFull) $ do
  deckWidget actorId actorState

  statsWidget actorState

  consequencesWidget actorId actorState

  equippedWidget actorState

  traitsWidget actorState
