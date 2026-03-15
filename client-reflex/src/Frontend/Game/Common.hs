{-# LANGUAGE OverloadedStrings #-}

module Frontend.Game.Common where

import Control.Monad.Fix (MonadFix)
import Reflex.Dom.Core

import Frontend.Style (plannedCardOverlap)
import Frontend.Style.DSL qualified as S
import Frontend.Style.Layout

-- | Reusable widget for rendering a stack of cards (Resources behind Action)
-- Uses the same layout logic as PlannedAction to ensure visual consistency.
cardStackWidget
  :: (DomBuilder t m, PostBuild t m, MonadHold t m, MonadFix m, Eq res)
  => (Dynamic t res -> m (Event t a))
  -- ^ Renderer for resource cards. Takes a Dynamic of the item.
  -> (Dynamic t act -> m (Event t b))
  -- ^ Renderer for the action card. Takes a Dynamic of the item.
  -> Dynamic t [res]
  -- ^ Dynamic List of resource cards
  -> Dynamic t act
  -- ^ Dynamic Action card
  -> m (Event t a, Event t b)
  -- ^ (Resource Click Event, Action Click Event)
cardStackWidget renderResource renderAction resources action = do
  rowWith (S.itemsCenter . plannedCardOverlap) $ do
    -- Resources (vertical strips)
    -- We use 'dyn' instead of 'simpleList' to avoid injecting a wrapper <div>,
    -- allowing the CSS immediate sibling selector (> * + *) in 'spaceXActionStackOverlap' to work properly.
    -- Reverse the list so the first resource is rendered last (visually on the right/bottom)
    resourceEvtsEvt <- dyn $ ffor (reverse <$> resources) $ \rs ->
      mapM (renderResource . constDyn) rs

    resClick <- switchHold never (leftmost <$> resourceEvtsEvt)

    -- Action card (top/right)
    actionEvt <- renderAction action

    return (resClick, actionEvt)

-- | A static version of 'cardStackWidget' for rendering an action stack that doesn't
-- have dynamically changing collections. Crucially, this uses 'mapM_' instead of
-- 'simpleList' to avoid injecting a wrapper <div>, allowing the CSS immediate sibling
-- selector (> * + *) in 'spaceXActionStackOverlap' to work properly.
staticActionStackWidget
  :: (DomBuilder t m, PostBuild t m)
  => (res -> m (Event t a))
  -- ^ Renderer for resource cards.
  -> (act -> m (Event t b))
  -- ^ Renderer for the action card.
  -> [res]
  -- ^ List of resource cards
  -> act
  -- ^ Action card
  -> m (Event t a, Event t b)
  -- ^ (Resource Click Event, Action Click Event)
staticActionStackWidget renderResource renderAction resources action = do
  rowWith (S.itemsCenter . plannedCardOverlap) $ do
    -- Resources
    -- Reverse the list so the first resource is rendered last (visually on the right/bottom)
    resourceEvts <- mapM renderResource (reverse resources)

    -- Action card
    actionEvt <- renderAction action

    return (leftmost resourceEvts, actionEvt)
