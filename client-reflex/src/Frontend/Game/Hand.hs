module Frontend.Game.Hand where

import Control.Monad (void)
import Control.Monad.Fix (MonadFix)
import Reflex.Dom.Core

import Core.State (ActorState (..), CoreCardState (..))
import Frontend.Card (CardDisplayMode (..), CardSettings (..))

import Frontend.Style hiding (classes)

import Frontend.Game.PlannedAction (plannedActionWidget)
import Frontend.Html (Render (..))

-- | Styles for hand card hover interactions
cardHover :: [CssClass]
cardHover =
  [ "transition-transform"
  , "duration-200"
  , "ease-out"
  , "origin-bottom"
  , "hover:-translate-y-8"
  , "hover:z-50"
  , cursorPointer
  ]

handWidget ::
  (DomBuilder t m, PostBuild t m, MonadHold t m, MonadFix m) => Dynamic t (Maybe ActorState) -> m ()
handWidget actorDyn = do
  overlayBottomWith [flex, justifyCenter, itemsEnd, "pb-4", pointerEventsNone] $ do
    rowWith ["gap-12", pointerEventsAuto, itemsEnd, "px-8"] $ do
      -- Planned Action Section (Left)
      dyn_ $ ffor actorDyn $ \case
        Just actor -> maybe blank plannedActionWidget actor.coreState.planned
        Nothing -> blank

      -- Hand Section (Right)
      let handDyn = ffor actorDyn $ \case
            Just actor -> actor.coreState.hand
            Nothing -> []

      divStyle [flex, itemsEnd, "transition-opacity", "duration-300"] $ do
        void $ simpleList handDyn $ \cardDyn -> do
          divStyle [relative, pointerEventsAuto, group, cardHandWidth] $ do
            divStyle cardHover $ do
              dyn_ $ ffor cardDyn $ renderWith (CardSettings CardFull)
