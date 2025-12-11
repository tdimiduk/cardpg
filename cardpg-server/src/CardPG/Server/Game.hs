{-# LANGUAGE DuplicateRecordFields #-}
{-# LANGUAGE OverloadedLabels #-}
{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE ScopedTypeVariables #-}
{-# LANGUAGE TemplateHaskell #-}
{-# LANGUAGE DeriveGeneric #-}

module CardPG.Server.Game
  ( GameState (..)
  , emptyGame
  , addActor
  , runActorAction
  ) where

import Control.Monad.RWS (runRWST)
import Control.Monad.State (runState)
import Data.Map.Strict (Map)
import qualified Data.Map.Strict as Map
import Data.Text (Text)
import Optics
import System.Random (StdGen)

import GHC.Generics (Generic)

import CardPG.Core.Logic (GameM, runGameM)
import CardPG.Core.Primitives (TargetId)
import CardPG.Core.State (ActorState, GameEnv(..), GameEvent)

-- | The authoritative state for a game session
data GameState = GameState
  { actors :: Map TargetId ActorState
  , rng :: StdGen
  , env :: GameEnv
  }
  deriving (Show, Generic)

emptyGame :: GameEnv -> StdGen -> GameState
emptyGame env gen = GameState
  { actors = Map.empty
  , rng = gen
  , env = env
  }

addActor :: TargetId -> ActorState -> GameState -> GameState
addActor tid state game = game & #actors % at tid ?~ state

-- | Run a GameM action for a specific actor
-- Returns the list of events generated, or Nothing if the actor doesn't exist.
-- Updates the GameState with the new ActorState and new RNG.
runActorAction :: TargetId -> GameM StdGen a -> GameState -> (Maybe [GameEvent], GameState)
runActorAction tid action game =
  case game ^. #actors % at tid of
    Nothing -> (Nothing, game)
    Just actorSt ->
      let 
        env = game ^. #env
        rng = game ^. #rng
        
        -- Run the RWS monad: RWST GameEnv [GameEvent] ActorState (State StdGen) a
        -- Unwrap GameM
        rwst = runGameM action
        
        -- 1. Unpeel RWS: IO/Base monad is (State StdGen)
        -- runRWST :: RWST r w s m a -> r -> s -> m (a, s, w)
        stateAction = runRWST rwst env actorSt
        
        -- 2. Run the inner State monad with the global RNG
        -- runState :: State s a -> s -> (a, s)
        ((_, newActorSt, events), newRng) = runState stateAction rng
        
        -- 3. Update the global game state
        newGame = game 
          & #actors % at tid ?~ newActorSt
          & #rng .~ newRng
      in
        (Just events, newGame)
