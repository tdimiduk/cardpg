{-# LANGUAGE DataKinds #-}
{-# LANGUAGE OverloadedRecordDot #-}

module Frontend.Game.ActorDetails
  ( actorDetailsWidget
  ) where

import Control.Monad.Fix (MonadFix)
import Reflex.Dom.Core hiding (button)
import Prelude hiding (filter, id, map)

import Core.Primitives (ActorId)
import Core.State (ActorState (..), CoreCardState (..))

import Frontend.Game.ActorDetails.Assets (equippedWidget, traitsWidget)
import Frontend.Game.ActorDetails.Consequences (consequencesWidget)
import Frontend.Game.ActorDetails.Deck (deckWidget)
import Frontend.Game.ActorDetails.Stats (statsWidget)
import Frontend.Game.Class (MonadGame)

import Frontend.Style.Common
import Frontend.Style.DSL qualified as S
import Frontend.UI.Button (ButtonConfig (..), ButtonVariant (..), button)

actorDetailsWidget
  :: ( DomBuilder t m
     , PostBuild t m
     , MonadHold t m
     , MonadFix m
     , Adjustable t m
     , Prerender t m
     , MonadGame t m
     )
  => ActorId
  -> Dynamic t ActorState
  -> m (Event t ())
actorDetailsWidget actorId actorState = componentS "actor-details" (S.flexCol . S.gap S.S2 . S.wFull) $ do
  deckWidget actorId actorState

  statsWidget actorState

  consequencesWidget actorId actorState

  equippedWidget actorState

  traitsWidget actorState

  let defendingDyn = (.coreState.defending) <$> actorState
  resumeEvt <- dyn $ ffor defendingDyn $ \case
    Nothing -> return never
    Just _ ->
      button
        def
          { variant = VariantPrimary
          , fullWidth = True
          }
        $ text "Resume Defense"
  switchHold never resumeEvt
