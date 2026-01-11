{-# LANGUAGE OverloadedRecordDot #-}

module Frontend.Game.ActorLogic
  ( actorDefense
  , actorResilience
  , actorNextSeverity
  ) where

import Prelude hiding (filter, id, map, (.))

import Reflex.Dom.Core

import Core.Logic.Combat (computeDefense, computeNextSeverity, computeResilience)
import Core.State (ActorState (..))

actorDefense :: (Reflex t) => Dynamic t ActorState -> Dynamic t Int
actorDefense actorState = do
  as <- actorState
  return $ computeDefense as.tableState

actorResilience :: (Reflex t) => Dynamic t ActorState -> Dynamic t Int
actorResilience actorState = do
  as <- actorState
  return $ computeResilience as.tableState

actorNextSeverity :: (Reflex t) => Dynamic t ActorState -> Dynamic t Int
actorNextSeverity actorState = do
  as <- actorState
  return $ computeNextSeverity as.tableState
