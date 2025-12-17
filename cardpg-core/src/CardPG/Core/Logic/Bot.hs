{-# LANGUAGE DuplicateRecordFields #-}
{-# LANGUAGE OverloadedRecordDot #-}

module CardPG.Core.Logic.Bot
  ( planBestAvailableAction
  ) where

import Data.List (sortOn)
import Data.Map.Strict qualified as Map
import Data.Ord (Down (..))
import Optics

import CardPG.Core.Card (CoreCardT (..), Stats (..))
import CardPG.Core.Logic.Combat (getAttackRule)
import CardPG.Core.Logic.Monad (GameM (..))
import CardPG.Core.Logic.Planning (passAction, planAction)
import CardPG.Core.Primitives (ResourceType (..), StackPower (..))
import CardPG.Core.RuleDefs (AttackDefT (..))
import CardPG.Core.State (ActorState (..), CoreCardState (..))

planBestAvailableAction :: GameM g ()
planBestAvailableAction = do
  handIds <- use (#coreState % #hand)
  registry <- use (#coreState % #registry)

  let cardsInHand = [(cid, c) | cid <- handIds, Just c <- [Map.lookup cid registry]]

  -- Find candidates: Cards with a cost and a valid attack rule
  let candidates =
        [ (cid, cost, attackRule)
        | (cid, c) <- cardsInHand
        , Just cost <- [c.cost] -- Must have cost (implies playable action)
        , cost <= length handIds - 1 -- Must have enough OTHER cards
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
