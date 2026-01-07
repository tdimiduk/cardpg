module Frontend.Game.Hand where

import Control.Monad (void)
import Control.Monad.Fix (MonadFix)
import Reflex.Dom.Core

import Core.State (ActorState (..), CoreCardState (..))
import Frontend.Card ()
import Frontend.Game.PlannedAction (plannedActionWidget)
import Frontend.Html (Render (..))

handWidget ::
  (DomBuilder t m, PostBuild t m, MonadHold t m, MonadFix m) => Dynamic t (Maybe ActorState) -> m ()
handWidget actorDyn = do
  divClass "absolute bottom-0 left-0 right-0 flex justify-center items-end pb-4 pointer-events-none" $ do
    divClass "pointer-events-auto flex items-end justify-center px-8 gap-12" $ do
      -- Planned Action Section (Left)
      dyn_ $ ffor actorDyn $ \case
        Just actor -> maybe blank plannedActionWidget actor.coreState.planned
        Nothing -> blank

      -- Hand Section (Right)
      let handDyn = ffor actorDyn $ \case
            Just actor -> actor.coreState.hand
            Nothing -> []

      -- We need to check if there is a planned action to know if we should dim the hand
      -- But for now, we'll just render the hand as is.

      divClass "flex items-end transition-opacity duration-300 min-h-[260px]" $ do
        void $ simpleList handDyn $ \cardDyn -> do
          divClass "pointer-events-auto relative group w-[160px]" $ do
            divClass
              "transition-transform duration-200 ease-out origin-bottom hover:-translate-y-8 hover:z-50 cursor-pointer"
              $ do
                dyn_ $ ffor cardDyn render
