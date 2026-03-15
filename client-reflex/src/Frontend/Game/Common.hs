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
  rowWith (S.itemsStretch . plannedCardOverlap) $ do
    -- Resources (vertical strips)
    -- simpleList efficiently handles list updates
    resourceEvts <- simpleList resources renderResource

    -- Action card (top)
    actionEvt <- renderAction action

    return (switchDyn $ fmap leftmost resourceEvts, actionEvt)
