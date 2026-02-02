{-# LANGUAGE DuplicateRecordFields #-}
{-# LANGUAGE OverloadedRecordDot #-}

module Core.Logic.Bot
  ( planBestAvailableAction
  ) where

import Control.Lens
import Data.Generics.Labels ()
import Data.List (sortOn)
import Data.Ord (Down (..))

import Core.Card (CoreCard (..), Identified (..), Stats (..))
import Core.Logic.Combat (getAttackRule)
import Core.Logic.Monad (GameM (..))
import Core.Logic.Planning (passAction, planAction)
import Core.Rules (AttackDef (..))
import Core.Stats (ResourceType (..), StackPower (..))

planBestAvailableAction :: GameM g ()
planBestAvailableAction = do
  hand <- use (#coreState . #hand)

  let cardsInHand = [(c.id, c.content) | c <- hand]

  -- Find candidates: Cards with a cost and a valid attack rule
  let candidates =
        [ (cid, cost, attackRule)
        | (cid, c) <- cardsInHand
        , Just cost <- [c.cost] -- Must have cost (implies playable action)
        , cost <= length hand - 1 -- Must have enough OTHER cards
        , Right attackRule <- [getAttackRule c] -- Must be attack (for now)
        ]

  case candidates of
    [] -> passAction
    ((actionCid, cost, attackRule) : _) -> do
      -- Found an action to play
      -- Determine controlling color
      let color = attackRule.power.source

      -- Select resources from OTHER cards
      let otherCards = filter (\(cid, _) -> cid /= actionCid) cardsInHand

      -- Helper to get stat based on color
      let getValue c = case color of
            Red -> c.stats.red
            Yellow -> c.stats.yellow
            Blue -> c.stats.blue

      -- Sort by value in that color descending
      let sortedResources = sortOn (\(_, c) -> Down (getValue c)) otherCards
      let selectedResources = take cost sortedResources
      let resourceIds = map fst selectedResources

      planAction actionCid resourceIds
