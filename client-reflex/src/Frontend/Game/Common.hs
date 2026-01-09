{-# LANGUAGE OverloadedStrings #-}

module Frontend.Game.Common where

import Reflex.Dom.Core

import Frontend.Style hiding (classes)

-- | Reusable widget for rendering a stack of cards (Resources behind Action)
-- Uses the same layout logic as PlannedAction to ensure visual consistency.
cardStackWidget
  :: (DomBuilder t m)
  => (res -> m (Event t a))
  -- ^ Renderer for resource cards
  -> (act -> m (Event t b))
  -- ^ Renderer for the action card
  -> [res]
  -- ^ List of resource cards
  -> act
  -- ^ Action card
  -> m (Event t a, Event t b)
  -- ^ (Resource Click Event, Action Click Event)
cardStackWidget renderResource renderAction resources action = do
  rowWith ["items-stretch", plannedCardOverlap] $ do
    -- Resources (vertical strips)
    resourceEvts <- traverse renderResource resources

    -- Action card (top)
    actionEvt <- renderAction action

    return (leftmost resourceEvts, actionEvt)
