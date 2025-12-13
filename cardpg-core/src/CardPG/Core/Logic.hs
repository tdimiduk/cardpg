{-# LANGUAGE DuplicateRecordFields #-}
{-# LANGUAGE OverloadedRecordDot #-}

module CardPG.Core.Logic
  ( GameM (..)
  , runGameM
  , performFatigueCycle
  , drawCard
  , flipCardToDefense
  , planMove
  , applyPlannedMove
  , planAction
  , cancelPlan
  , revealPlannedActions
  , discardPlannedActions
  , attackAction
  , endDefense
  ) where

import Control.Monad (replicateM)
import Control.Monad.RWS (MonadReader, MonadWriter, RWST, ask, tell)
import Control.Monad.State (MonadState, State, modify, state)
import Control.Monad.Trans.Class (lift)
import Data.List (partition)
import Data.Map.Strict qualified as Map
import Data.Text (Text)
import Optics
import System.Random (RandomGen, uniform)

import CardPG.Core.Card (CoreCard, CoreCardT (..), ItemCardT (..), Stats (..))
import CardPG.Core.Primitives (CardInstanceId, ResourceType (..), StackPower (..))
import CardPG.Core.RichText (RichString)
import CardPG.Core.RuleDefs (AttackDefT (..), DSLRule (..), RuleT (RuleAttack))
import CardPG.Core.State
  ( ActionStack (..)
  , ActionStackMaterialized (..)
  , ActorState (..)
  , AssetState (..)
  , RealizedAttack (..)
  , CoreCardState (..)
  , GameEnv (..)
  , GameEvent (..)
  , SpatialState (..)
  , TableCard (..)
  , TableState (..)
  , actionStack
  )
import CardPG.Core.Util (shuffleListM)
import Data.List.NonEmpty (toList)

-- | The Game Monad
-- Stack:
--   Reader: GameEnv (static context)
--   Writer: [GameEvent] (log of events)
--   State: ActorState (game state)
--   Base: State g (random number generator state)
newtype GameM g a = GameM
  { runGameM :: RWST GameEnv [GameEvent] ActorState (State g) a
  }
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

calculateTotalBurden :: GameM g Int
calculateTotalBurden = do
  tblSt <- use #tableState
  let equippedItems =
        [ item
        | (cid, Equipped _) <- Map.toList (tblSt ^. #assets)
        , Just (TCItem item) <- [Map.lookup cid (tblSt ^. #registry)]
        ]
  let burden = sum [b | item <- equippedItems, let b = maybe 0 id (item ^. #burden)]
  return burden

createCards :: (RandomGen g) => CoreCard -> Int -> GameM g [CardInstanceId]
createCards template n = do
  newIds <- replicateM n $ liftRandom uniform
  modify $ #coreState % #registry %~ (`Map.union` Map.fromList [(cid, template) | cid <- newIds])
  tell [CardsCreated newIds]
  return newIds

performFatigueCycle :: (RandomGen g) => GameM g ()
performFatigueCycle = do
  env <- ask
  burden <- calculateTotalBurden

  newFatigueIds <- createCards (env ^. #fatigueCardTemplate) (2 + burden)

  currentDiscard <- use (#coreState % #discard)
  modify $ #coreState % #discard .~ []

  newDeck <- GameM . lift $ shuffleListM (newFatigueIds ++ currentDiscard)

  modify $ #coreState % #deck .~ newDeck
  tell [DeckShuffled]

deckCardTo ::
  (RandomGen g) =>
  Lens' CoreCardState [CardInstanceId] -> (CardInstanceId -> GameEvent) -> GameM g ()
deckCardTo dst gameLog = do
  currentDeck <- use (#coreState % #deck)
  case currentDeck of
    [] -> do
      performFatigueCycle
      deckCardTo dst gameLog
    (top : rest) -> do
      modify $ #coreState % #deck .~ rest
      modify $ #coreState % dst %~ (top :)
      tell [gameLog top]

drawCard :: (RandomGen g) => GameM g ()
drawCard = deckCardTo #hand CardDrawn

flipCardToDefense :: (RandomGen g) => GameM g ()
flipCardToDefense = deckCardTo #defending CardDefended

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
      plan = ActionStack actionCardId resourceIds

  -- Validate all cards are in hand
  if length found == length allIds
    then do
      modify $ #coreState % #hand .~ remaining
      modify $ #coreState % #planned ?~ plan
      tell [ActionPlanned plan]
    else tell [IllegalAction plan (Just "cards not in hand")]

plannedActionTo ::
  Lens' CoreCardState [CardInstanceId] -> (ActionStack -> GameEvent) -> GameM g ()
plannedActionTo dst gameLog = do
  maybePlan <- use (#coreState % #planned)
  case maybePlan of
    Nothing -> return ()
    Just plan -> do
      modify $ #coreState % #planned .~ Nothing
      modify $ #coreState % dst %~ ((actionStack plan) ++)
      tell [gameLog plan]

cancelPlan :: GameM g ()
cancelPlan = plannedActionTo #hand PlanCanceled

revealPlannedActions :: GameM g ()
revealPlannedActions = do
  maybePlan <- use (#coreState % #planned)
  case maybePlan of
    Nothing -> return ()
    Just plan -> tell [ActionRevealed plan]

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

getAttackRule :: CoreCard -> Either Text (AttackDefT RichString)
getAttackRule card = case card.rules of
  Nothing -> Left "no attack rule"
  Just rules -> case [r | RuleAttack r <- map (.unDSLRule) (toList rules)] of
    [] -> Left "no attack rule"
    [r] -> Right r
    _ -> Left "cards with multiple attack rules are not implemented yet"

stackPower :: ActionStackMaterialized -> StackPower -> Int
stackPower stack power =
  let
    allCards = stack.actionCard : stack.resources
    relevantStat c = case power.source of
      Red -> c.stats.red
      Yellow -> c.stats.yellow
      Blue -> c.stats.blue
    rawTotal = sum (map relevantStat allCards)
   in
    rawTotal + power.modifier

attackAction :: ActionStackMaterialized -> Either Text RealizedAttack
attackAction stack = case getAttackRule (stack.actionCard) of
  Left err -> Left err
  Right attackRule ->
    Right $
      RealizedAttack
        { attackCard = stack.actionCardId
        , attackStrength = stackPower stack attackRule.power
        , defenseColor = attackRule.resistedBy
        }
