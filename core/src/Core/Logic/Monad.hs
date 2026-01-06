module Core.Logic.Monad
  ( GameM (..)
  , runGameM
  , liftRandom
  ) where

import Control.Monad.RWS (MonadReader, MonadWriter, RWST)
import Control.Monad.State (MonadState, State, state)
import Control.Monad.Trans.Class (lift)

import Core.State (ActorState, GameEnv, GameEvent)

-- | The Game Monad
-- Stack:
--   Reader: GameEnv (static context)
--   Writer: [GameEvent] (log of events)
--   State: ActorState (game state)
--   Base: State g (random number generator state)
newtype GameM g a = GameM (RWST GameEnv [GameEvent] ActorState (State g) a)
  deriving newtype
    ( Functor
    , Applicative
    , Monad
    , MonadReader GameEnv
    , MonadWriter [GameEvent]
    , MonadState ActorState
    )

runGameM :: GameM g a -> RWST GameEnv [GameEvent] ActorState (State g) a
runGameM (GameM x) = x

-- | Helper to access the random generator from the base monad
liftRandom :: (g -> (a, g)) -> GameM g a
liftRandom f = GameM . lift $ state f
