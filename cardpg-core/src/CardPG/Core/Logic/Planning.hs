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
import Control.Monad.State (get, modify, state)
import Data.List (find, partition)
import Data.List.NonEmpty (NonEmpty (..), nonEmpty)

import Data.Maybe (fromMaybe)
import Data.UUID.Types (nil)
import Optics
import System.Random (RandomGen, uniform)

import CardPG.Core.Card (CardInstance, CoreCard (..), Identified (..))
import CardPG.Core.Logic.Combat (attackAction, computeDefenseDetails)
import CardPG.Core.Logic.Monad (GameM (..), liftRandom)
import CardPG.Core.Primitives (CardInstanceId (..), ChallengeId, ResourceType (..))
import CardPG.Core.State
  ( ActionStack (..)
  , ActiveDefense (..)
  , ActorState (..)
  , CoreCardState (..)
  , DefenseDetails (..)
  , GameEvent (..)
  , IllegalActionDetails (..)
  , NarrativeStack (..)
  , PlannedAction (..)
  , RevealedEffect (..)
  , SpatialState (..)
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
      (found, remaining) = partition (\c -> c.id `elem` allIds) currentHand

      maybeActionCard = find (\c -> c.id == actionCardId) found
      resourceCards = filter (\c -> c.id `elem` resourceIds) found

  case maybeActionCard of
    Nothing ->
      tell
        [IllegalAction (IllegalActionDetails Nothing (Just "action card not in hand"))]
    Just ac -> do
      let plan = PStandard (ActionStack ac resourceCards)
          cost = maybe 0 (\c -> fromMaybe 0 c.cost) (Just ac.content)
          correctCost = length resourceCards == cost

      -- Validate all cards are in hand AND cost is correct
      if length found == length allIds
        then
          if correctCost
            then do
              modify $ #coreState % #hand .~ remaining
              modify $ #coreState % #planned ?~ plan
              tell [ActionPlanned plan]
            else tell [IllegalAction (IllegalActionDetails (Just plan) (Just "incorrect resource cost"))]
        else tell [IllegalAction (IllegalActionDetails (Just plan) (Just "cards not in hand"))]

planNarrative :: [CardInstanceId] -> ResourceType -> GameM g ()
planNarrative cardIds color = do
  currentHand <- use (#coreState % #hand)
  let (found, remaining) = partition (\c -> c.id `elem` cardIds) currentHand
      maybeNeCards = nonEmpty found

  case maybeNeCards of
    Nothing ->
      tell
        [ IllegalAction
            (IllegalActionDetails Nothing (Just "no cards selected"))
        ]
    Just neCards -> do
      let plan = PNarrative (NarrativeStack neCards color)
      if length found == length cardIds
        then do
          modify $ #coreState % #hand .~ remaining
          modify $ #coreState % #planned ?~ plan
          tell [ActionPlanned plan]
        else tell [IllegalAction (IllegalActionDetails (Just plan) (Just "cards not in hand"))]

plannedActionTo ::
  Lens' CoreCardState [CardInstance CoreCard] -> (PlannedAction -> GameEvent) -> GameM g ()
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

revealPlannedActions :: (RandomGen g) => GameM g ()
revealPlannedActions = do
  maybePlan <- use (#coreState % #planned)
  case maybePlan of
    Nothing -> return ()
    Just plan -> do
      cid <- liftRandom uniform
      let revealedEffect = case plan of
            PPass -> REPass
            _ -> case attackAction cid plan of
              Right challenge -> REChallenge challenge
              Left err -> REInvalid err

      tell [ActionRevealed plan revealedEffect]
      modify $ #coreState % #revealed ?~ revealedEffect

discardPlannedActions :: GameM g ()
discardPlannedActions = plannedActionTo #discard PlanCanceled

endDefense :: GameM g ()
endDefense = do
  maybeDefense <- use (#coreState % #defending)
  case maybeDefense of
    Nothing -> return ()
    Just (ActiveDefense _ stack) -> do
      state <- get -- Capture state while defending is still active to read defense cards
      let defenseDetails = computeDefenseDetails state

      modify $ #coreState % #defending .~ Nothing
      modify $ #coreState % #discard %~ (stack ++)

      -- We need to reconstruct ActiveDefense from state or use what we matched
      -- 'stack' is just cards. 'defending' in state is 'Maybe ActiveDefense'
      -- The 'ActiveDefense' we matched is what we want.
      let activeDef = fromMaybe (error "Defense state inconsistent") $ state ^. (#coreState % #defending)

      tell [DefenseEnded activeDef defenseDetails]

passAction :: GameM g ()
passAction = do
  modify $ #coreState % #planned ?~ PPass
  tell [ActionPlanned PPass]
