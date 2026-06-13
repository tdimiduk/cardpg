module Server.Game
  ( GameState (..)
  , emptyGame
  , addActor
  ) where

import Data.Map.Strict qualified as Map

import Core.Primitives (ActorId)
import Core.State (ActorState (..), GameEnv, MapMode (..))
import Server.Types (GameState (..), Phase (..))

emptyGame :: GameEnv -> GameState
emptyGame env =
  GameState
    { env = env
    , actors = Map.empty
    , phase = Planning
    , history = []
    , mapMode = Just MapModeGrid
    }

addActor :: ActorId -> ActorState -> GameState -> GameState
addActor tid state game = game{actors = Map.insert tid state game.actors}
