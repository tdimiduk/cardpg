module CardPG.Server.Game
  ( GameState (..)
  , emptyGame
  , addActor
  ) where

import Data.Map.Strict qualified as Map

import CardPG.Core.Primitives (ActorId)
import CardPG.Core.State (ActorState (..), GameEnv)
import CardPG.Server.Types (GameState (..), Phase (..))

emptyGame :: GameEnv -> GameState
emptyGame env =
  GameState
    { env = env
    , actors = Map.empty
    , phase = Planning
    , history = []
    }

addActor :: ActorId -> ActorState -> GameState -> GameState
addActor tid state game = game{actors = Map.insert tid state game.actors}
