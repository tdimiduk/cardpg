{-# LANGUAGE DuplicateRecordFields #-}
{-# LANGUAGE OverloadedRecordDot #-}

module CardPG.Core.Logic.Planning
  ( planMove
  , applyPlannedMove
  , planAction
  , planNarrative
  , cancelPlan
  , discardPlannedActions
  , revealPlannedActions
  , endDefense
  , passAction
  ) where

import Control.Monad.RWS (tell)
import Control.Monad.State (modify)
import Data.List (partition)
import Data.List.NonEmpty (NonEmpty (..), nonEmpty)
import Data.Map.Strict qualified as Map
import Data.Maybe (fromMaybe)
import Data.UUID (nil)
import Optics

import CardPG.Core.Card (CoreCardT (..))
import CardPG.Core.Logic.Combat (attackAction)
import CardPG.Core.Logic.Monad (GameM (..))
import CardPG.Core.Primitives (CardInstanceId (..), ResourceType (..))
import CardPG.Core.State
  ( ActionStack (..)
  , ActorState (..)
  , CoreCardState (..)
  , GameEvent (..)
  , NarrativeStack (..)
  , PlannedAction (..)
  , PlannedActionMaterialized (..)
  , RevealedEffect (..)
  , SpatialState (..)
  , materializePlannedAction
  , plannedActionCards
  )

planMove :: Int -> Int -> GameM g ()
planMove x y = do
  modify $ #plannedMove ?~ (x, y)
  tell [MovePlanned (x, y)]

applyPlannedMove :: GameM g ()
applyPlannedMove = do
  maybePlan <- use #plannedMove
  case maybePlan of
    Nothing -> return ()
    Just (newX, newY) -> do
      modify $ #spatial % lens (.posX) (\s v -> s{posX = v}) .~ newX
      modify $ #spatial % lens (.posY) (\s v -> s{posY = v}) .~ newY
      modify $ #plannedMove .~ Nothing
      tell [ActorMoved (newX, newY)]

planAction :: CardInstanceId -> [CardInstanceId] -> GameM g ()
planAction actionCardId resourceIds = do
  currentHand <- use (#coreState % #hand)
  let allIds = actionCardId : resourceIds
      (found, remaining) = partition (`elem` allIds) currentHand
      plan = PStandard (ActionStack actionCardId resourceIds)

  core <- use (#coreState % #registry)
  let maybeActionCard = Map.lookup actionCardId core
  let cost = maybe 0 (\c -> fromMaybe 0 c.cost) maybeActionCard
  let correctCost = length resourceIds == cost

  -- Validate all cards are in hand AND cost is correct
  if length found == length allIds
    then
      if correctCost
        then do
          modify $ #coreState % #hand .~ remaining
          modify $ #coreState % #planned ?~ plan
          tell [ActionPlanned plan]
        else tell [IllegalAction plan (Just "incorrect resource cost")]
    else tell [IllegalAction plan (Just "cards not in hand")]

planNarrative :: [CardInstanceId] -> ResourceType -> GameM g ()
planNarrative cardIds color = do
  currentHand <- use (#coreState % #hand)
  let (found, remaining) = partition (`elem` cardIds) currentHand
      maybeNeIds = nonEmpty cardIds

  case maybeNeIds of
    Nothing ->
      tell
        [ IllegalAction
            (PNarrative (NarrativeStack (CardInstanceId nil :| []) color))
            (Just "no cards selected")
        ]
    Just neIds -> do
      let plan = PNarrative (NarrativeStack neIds color)
      if length found == length cardIds
        then do
          modify $ #coreState % #hand .~ remaining
          modify $ #coreState % #planned ?~ plan
          tell [ActionPlanned plan]
        else tell [IllegalAction plan (Just "cards not in hand")]

plannedActionTo ::
  Lens' CoreCardState [CardInstanceId] -> (PlannedAction -> GameEvent) -> GameM g ()
plannedActionTo dst gameLog = do
  maybePlan <- use (#coreState % #planned)
  case maybePlan of
    Nothing -> return ()
    Just plan -> do
      modify $ #coreState % #planned .~ Nothing
      modify $ #coreState % #revealed .~ Nothing
      modify $ #coreState % dst %~ (plannedActionCards plan ++)
      tell [gameLog plan]

cancelPlan :: GameM g ()
cancelPlan = plannedActionTo #hand PlanCanceled

revealPlannedActions :: GameM g ()
revealPlannedActions = do
  maybePlan <- use (#coreState % #planned)
  case maybePlan of
    Nothing -> return ()
    Just plan -> do
      registry <- use (#coreState % #registry)
      let revealedEffect = case materializePlannedAction registry plan of
            Nothing -> REInvalid "you don't have all these cards"
            Just matPlan -> case matPlan of
              PMPass -> REPass
              _ -> case attackAction matPlan of
                Right challenge -> REChallenge challenge
                Left err -> REInvalid err

      tell [ActionRevealed plan revealedEffect]
      modify $ #coreState % #revealed ?~ revealedEffect

discardPlannedActions :: GameM g ()
discardPlannedActions = plannedActionTo #discard PlanCanceled

endDefense :: GameM g ()
endDefense = do
  stack <- use (#coreState % #defending)
  case stack of
    [] -> return ()
    _ -> do
      modify $ #coreState % #defending .~ []
      modify $ #coreState % #discard %~ (stack ++)
      tell [DefenseEnded stack]

passAction :: GameM g ()
passAction = do
  modify $ #coreState % #planned ?~ PPass
  tell [ActionPlanned PPass]
