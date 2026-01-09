{-# LANGUAGE DuplicateRecordFields #-}
{-# LANGUAGE OverloadedRecordDot #-}

module Core.Logic.Planning
  ( planMove
  , applyPlannedMove
  , planAction
  , planNarrative
  , cancelPlan
  , discardPlannedActions
  , revealPlannedActions
  , endDefense
  , passAction
  , PlanValidation (..)
  , validateStandardPlan
  , validateNarrativePlan
  ) where

import Control.Monad.RWS (tell)
import Control.Monad.State (get, modify)
import Data.List (find, partition)
import Data.List.NonEmpty (nonEmpty)

import Data.Maybe (fromMaybe)
import Data.Text (Text)
import Data.Text qualified as Text
import Optics
import System.Random (RandomGen, uniform)

import Core.Card (CardInstance, CoreCard (..), Identified (..))
import Core.Logic.Combat (attackAction, computeDefenseDetails)
import Core.Logic.Monad (GameM (..), liftRandom)
import Core.Primitives (CardInstanceId (..))
import Core.State
  ( ActionStack (..)
  , ActiveDefense (..)
  , ActorState (..)
  , CoreCardState (..)
  , GameEvent (..)
  , IllegalActionDetails (..)
  , NarrativeStack (..)
  , PlannedAction (..)
  , RevealedEffect (..)
  , SpatialState (..)
  , plannedActionCards
  )
import Core.Stats (ResourceType (..))

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

data PlanValidation
  = PlanValid PlannedAction
  | PlanIncomplete {cost :: Int, provided :: Int}
  | PlanInvalid Text
  deriving (Show, Eq)

validateStandardPlan :: CardInstance CoreCard -> [CardInstance CoreCard] -> PlanValidation
validateStandardPlan actionCard resourceCards =
  let plan = PStandard (ActionStack actionCard resourceCards)
      cost = maybe 0 (\c -> fromMaybe 0 c.cost) (Just actionCard.content)
      provided = length resourceCards
   in if provided == cost
        then PlanValid plan
        else PlanIncomplete cost provided

validateNarrativePlan :: [CardInstance CoreCard] -> ResourceType -> PlanValidation
validateNarrativePlan cardIds color =
  case nonEmpty cardIds of
    Nothing -> PlanInvalid "no cards selected"
    Just neCards -> PlanValid $ PNarrative (NarrativeStack neCards color)

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
      -- Validate cost locally first
      if length found /= length allIds
        then
          tell
            [ IllegalAction
                (IllegalActionDetails Nothing (Just "cards not in hand"))
            ]
        else do
          let validation = validateStandardPlan ac resourceCards
          case validation of
            PlanValid plan -> do
              modify $ #coreState % #hand .~ remaining
              modify $ #coreState % #planned ?~ plan
              tell [ActionPlanned plan]
            PlanIncomplete cost provided ->
              tell
                [ IllegalAction
                    ( IllegalActionDetails
                        Nothing
                        (Just $ "incorrect resource cost: " <> showT provided <> "/" <> showT cost)
                    )
                ]
            PlanInvalid reason ->
              tell [IllegalAction (IllegalActionDetails Nothing (Just reason))]

planNarrative :: [CardInstanceId] -> ResourceType -> GameM g ()
planNarrative cardIds color = do
  currentHand <- use (#coreState % #hand)
  let (found, remaining) = partition (\c -> c.id `elem` cardIds) currentHand

  if length found /= length cardIds
    then
      tell
        [ IllegalAction
            (IllegalActionDetails Nothing (Just "cards not in hand"))
        ]
    else do
      let validation = validateNarrativePlan found color
      case validation of
        PlanValid plan -> do
          modify $ #coreState % #hand .~ remaining
          modify $ #coreState % #planned ?~ plan
          tell [ActionPlanned plan]
        PlanIncomplete _ _ ->
          -- Narrative plans shouldn't be incomplete based on count in this logic, but handle exhaustive case
          tell [IllegalAction (IllegalActionDetails Nothing (Just "narrative plan incomplete"))]
        PlanInvalid reason ->
          tell [IllegalAction (IllegalActionDetails Nothing (Just reason))]

showT :: (Show a) => a -> Text.Text
showT = Text.pack . show

plannedActionTo
  :: Lens' CoreCardState [CardInstance CoreCard] -> (PlannedAction -> GameEvent) -> GameM g ()
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
