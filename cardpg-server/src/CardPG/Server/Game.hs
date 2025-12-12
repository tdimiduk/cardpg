module CardPG.Server.Game
  ( GameState (..)
  , emptyGame
  , addActor
  , runActorAction
  , processCommand
  , resolveRound
  , eventsToBroadcastActions
  ) where

import Control.Monad.RWS (runRWST)
import Control.Monad.State (runState)
import Data.Map.Strict (Map)
import Data.Map.Strict qualified as Map
import Data.Text (Text)
import Data.UUID (toText)
import System.Random (StdGen)

import CardPG.Core.Logic (GameM, runGameM)
import CardPG.Core.Logic qualified as Logic
import CardPG.Core.Primitives (TargetId (..))
import CardPG.Core.State (ActorState, GameEnv, GameEvent (..))
import CardPG.Server.Types (BroadcastAction (..), Command (..), GameState (..), StateUpdate (..))

emptyGame :: GameEnv -> StdGen -> GameState
emptyGame env rng =
  GameState
    { env = env
    , rng = rng
    , actors = Map.empty
    }

addActor :: TargetId -> ActorState -> GameState -> GameState
addActor tid state game = game{actors = Map.insert tid state (game.actors)}

runActorAction :: TargetId -> GameM StdGen a -> GameState -> (Maybe [GameEvent], GameState)
runActorAction tid action game =
  case Map.lookup tid (game.actors) of
    Nothing -> (Nothing, game)
    Just actorState ->
      let ((_, newState, events), newRng) = runState (runRWST (runGameM action) (game.env) actorState) (game.rng)
          newGame = game{rng = newRng, actors = Map.insert tid newState (game.actors)}
       in (Just events, newGame)

processCommand ::
  Command -> GameState -> (GameState, Maybe (TargetId, [BroadcastAction], ActorState))
processCommand cmd game =
  let (targetId, action) = case cmd of
        DrawIntent tid -> (tid, Logic.drawCard)
        DefendIntent tid -> (tid, Logic.flipCardToDefense)
        PlanMove tid x y -> (tid, Logic.planMove x y)

      (maybeEvents, newGame) = runActorAction targetId action game
   in case maybeEvents of
        Nothing -> (game, Nothing)
        Just events ->
          let TargetId uuid = targetId
              tidText = toText uuid
              broadcastActions = eventsToBroadcastActions tidText events

              -- Retrieve updated actor state safely
              updatedActorState = Map.lookup targetId (newGame.actors)
           in ( newGame
              , Just (targetId, broadcastActions, maybe (error "Actor missing after update") id updatedActorState)
              )

resolveRound :: GameState -> (GameState, [StateUpdate])
resolveRound game = foldl step (game, []) (Map.keys (game.actors))
  where
    step (g, updates) tid =
      let (maybeEvents, newG) = runActorAction tid Logic.applyPlannedMove g
       in case maybeEvents of
            Nothing -> (newG, updates)
            Just _ ->
              let updatedActor = Map.lookup tid (newG.actors)
               in case updatedActor of
                    Just actor -> (newG, updates ++ [StateUpdate tid actor])
                    Nothing -> (newG, updates)

-- | Helper to map internal GameEvents to Protocol BroadcastActions
eventsToBroadcastActions :: Text -> [GameEvent] -> [BroadcastAction]
eventsToBroadcastActions tid events = concatMap toAction events
  where
    toAction (CardDrawn _) = [DrawCards tid 1]
    toAction (CardDefended _) = [Defend tid]
    toAction DeckShuffled = [Reshuffle tid]
    toAction (CardsCreated _) = [] -- No visual action for creating cards
    toAction (MovePlanned _) = [] -- State update handles ghost
    toAction (ActorMoved _) = [] -- State update handles position
