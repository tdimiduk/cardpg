module Frontend.Game.Hand where

import Control.Monad (void)
import Control.Monad.Fix (MonadFix)
import Reflex.Dom.Core

import Core.State (ActorState (..), CoreCardState (..))
import Frontend.Card (CardDisplayMode (..), CardSettings (..))

import Frontend.Style hiding (classes)

import Frontend.Game.PlannedAction (plannedActionWidget)
import Frontend.Html (Render (..))

handWidget ::
  (DomBuilder t m, PostBuild t m, MonadHold t m, MonadFix m) => Dynamic t (Maybe ActorState) -> m ()
handWidget actorDyn = do
  divStyle
    [absolute, bottom0, left0, right0, flex, justifyCenter, itemsEnd, "pb-4", pointerEventsNone]
    $ do
      divStyle [pointerEventsAuto, flex, itemsEnd, justifyCenter, "px-8", "gap-12"] $ do
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

        divStyle [flex, itemsEnd, "transition-opacity", "duration-300", "min-h-[260px]"] $ do
          void $ simpleList handDyn $ \cardDyn -> do
            divStyle [pointerEventsAuto, relative, group, "w-[160px]"] $ do
              divStyle
                [ "transition-transform"
                , "duration-200"
                , "ease-out"
                , "origin-bottom"
                , "hover:-translate-y-8"
                , "hover:z-50"
                , cursorPointer
                ]
                $ do
                  dyn_ $ ffor cardDyn $ renderWith (CardSettings CardFull)
