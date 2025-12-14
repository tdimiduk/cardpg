{-# LANGUAGE DuplicateRecordFields #-}
{-# LANGUAGE LambdaCase #-}
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
  , planNarrative
  , cancelPlan
  , revealPlannedActions
  , discardPlannedActions
  , attackAction
  , endDefense
  , reshuffleDeck
  , addStatus
  , removeStatus
  , addConsequence
  , removeConsequence
  , discardCards
  , returnCardsToDeck
  , passAction
  ) where

import Control.Monad (replicateM)
import Control.Monad.RWS (MonadReader, MonadWriter, RWST, ask, tell)
import Control.Monad.State (MonadState, State, get, modify, put, state)
import Control.Monad.Trans.Class (lift)
import Data.List (partition)
import Data.Map.Strict qualified as Map
import Data.Text (Text, unpack)
import Data.UUID (nil)
import Optics
import System.Random (RandomGen, uniform, uniformR)

import CardPG.Core.Card
  ( ConsequenceCardT (..)
  , CoreCard
  , CoreCardT (..)
  , ItemCardT (..)
  , Stats (..)
  )
import CardPG.Core.NonEmptyText (getRawText, unsafeNonEmptyText)
import CardPG.Core.Primitives (CardInstanceId (..), ResourceType (..), StackPower (..))
import CardPG.Core.RichText (RichText)
import CardPG.Core.RuleDefs (AttackDefT (..), RuleT (RuleAttack))
import CardPG.Core.State
  ( ActionStack (..)
  , ActionStackMaterialized (..)
  , ActorState (..)
  , AssetState (..)
  , CoreCardState (..)
  , GameEnv (..)
  , GameEvent (..)
  , NarrativeStack (..)
  , NarrativeStackMaterialized (..)
  , PlannedAction (..)
  , PlannedActionMaterialized (..)
  , RealizedAttack (..)
  , SpatialState (..)
  , TableCard (..)
  , TableState (..)
  , plannedActionCards
  )
import CardPG.Core.Util (shuffleListM)
import Data.List.NonEmpty (NonEmpty (..), nonEmpty, toList)

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
      plan = PStandard (ActionStack actionCardId resourceIds)

  core <- use (#coreState % #registry)
  let maybeActionCard = Map.lookup actionCardId core
  let cost = maybe 0 (\c -> maybe 0 id (c.cost)) maybeActionCard
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
            (Just "no cards selected") -- Dummy empty stack for error? Or separate error?
            -- Creating a dummy NonEmpty is ugly.
            -- Maybe IllegalAction should just take Maybe PlannedAction?
            -- Or just don't emit ActionPlanned/IllegalAction with a stack if we can't build one.
            -- Just tell "IllegalAction" generic?
            -- IllegalAction takes PlannedAction.
            -- If we can't build a PlannedAction, we can't emit IllegalAction with it.
            -- Let's just return early or emit a different error?
            -- For now effectively ignore or log error?
            -- Let's assume frontend prevents empty selection.
            -- If empty, ignore.
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
      modify $ #coreState % dst %~ ((plannedActionCards plan) ++)
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

getAttackRule :: CoreCard -> Either Text (AttackDefT RichText)
getAttackRule card = case card.rules of
  Nothing -> Left "no attack rule"
  Just rules -> case [r | RuleAttack r <- toList rules] of
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

attackAction :: PlannedActionMaterialized -> Either Text RealizedAttack
attackAction matPlan = case matPlan of
  PMStandard stack -> case getAttackRule (stack.actionCard) of
    Left err -> Left err
    Right attackRule ->
      Right $
        RealizedAttack
          { attackCard = stack.actionCardId
          , attackStrength = stackPower stack attackRule.power
          , defenseColor = attackRule.resistedBy
          }
  PMPass -> Left "pass action"
  PMNarrative (NarrativeStackMaterialized{cards = cs, cardIds = cIds, color = col}) ->
    -- Narrative Action Logic
    let
      -- Helper to get stat based on color
      getStat :: ResourceType -> Stats -> Int
      getStat Red s = s.red
      getStat Yellow s = s.yellow
      getStat Blue s = s.blue

      rawTotal = sum [getStat col c.stats | c <- toList cs]
     in
      Right $
        RealizedAttack
          { attackCard = let (h :| _) = cIds in h -- Safe as narrative stack must have cards
          , attackStrength = rawTotal -- Modifier 0 for now
          , defenseColor = col -- Defense matches Action Color
          }

reshuffleDeck :: (RandomGen g) => GameM g ()
reshuffleDeck = do
  discarded <- use (#coreState % #discard)
  currentDeck <- use (#coreState % #deck)
  newDeck <- GameM . lift $ shuffleListM (discarded ++ currentDeck)
  modify $ #coreState % #discard .~ []
  modify $ #coreState % #deck .~ newDeck
  tell [DeckShuffled]

addStatus :: (RandomGen g) => Text -> Text -> GameM g ()
addStatus statusType destination = do
  env <- ask
  let maybeTemplate = Map.lookup statusType (env ^. #statusCardTemplates)
  case maybeTemplate of
    Nothing -> return () -- Invalid status type?
    Just template -> do
      ids <- createCards template 1
      case ids of
        [cid] -> do
          case destination of
            "hand" -> modify $ #coreState % #hand %~ (cid :)
            "discard" -> modify $ #coreState % #discard %~ (cid :)
            "deck" -> modify $ #coreState % #deck %~ (cid :)
            _ -> modify $ #coreState % #discard %~ (cid :)
          tell [ActionPlanned (PStandard (ActionStack cid []))]
        _ -> return ()

removeStatus :: Text -> Maybe Text -> GameM g ()
removeStatus statusType maybeCardId = do
  registry <- use (#coreState % #registry)

  let matchFunc cid c =
        case maybeCardId of
          Just specificId -> unpack specificId == show cid
          Nothing -> getRawText c.name == statusType

  let findAndRemove :: Lens' CoreCardState [CardInstanceId] -> GameM g Bool
      findAndRemove lens = do
        currentList <- use (#coreState % lens)
        let (before, foundAndAfter) =
              break
                ( \cid -> case Map.lookup cid registry of
                    Just c -> matchFunc cid c
                    Nothing -> False
                )
                currentList
        case foundAndAfter of
          (x : xs) -> do
            -- Found one element 'x'
            modify $ #coreState % lens .~ (before ++ xs)
            return True
          [] -> return False

  -- Search order: Hand, Discard, Deck
  removedFromHand <- findAndRemove #hand
  if removedFromHand
    then return ()
    else do
      removedFromDiscard <- findAndRemove #discard
      if removedFromDiscard
        then return ()
        else do
          _ <- findAndRemove #deck -- No need to check result, it's the last one
          return ()

addConsequence :: (RandomGen g) => Int -> GameM g ()
addConsequence severityVal = do
  env <- ask
  let candidates = filter (\c -> c.severity == severityVal) (Map.elems (env ^. #consequenceCardTemplates))

  case candidates of
    [] -> return ()
    _ -> do
      -- Pick random index
      g <- GameM . lift $ get
      let (idx, g') = uniformR (0, length candidates - 1) g
      GameM . lift $ put g'
      let template = candidates !! idx

      -- Create a new ID
      let (cid, g'') = uniform g'
      GameM . lift $ put g''

      -- Add to TableState registry and list
      modify $ #tableState % #consequenceRegistry %~ Map.insert cid template
      modify $ #tableState % #consequences %~ (cid :)

      -- We might need a generic event for "AssetCreated" or reused CardsCreated?
      -- CardsCreated takes [CardInstanceId]. It doesn't imply CoreCard necessarily.
      tell [CardsCreated [cid]]
      return ()

passAction :: (RandomGen g) => GameM g ()
passAction = do
  modify $ #coreState % #planned ?~ PPass
  tell [ActionPlanned PPass]

removeConsequence :: Text -> GameM g ()
removeConsequence cardIdStr = do
  let cid = CardInstanceId (read (unpack cardIdStr))
  -- Remove from TableState
  modify $ #tableState % #consequences %~ filter (/= cid)
  modify $ #tableState % #consequenceRegistry %~ Map.delete cid

discardCards :: [Text] -> GameM g ()
discardCards cardIdStrs = do
  let cids = map (CardInstanceId . read . unpack) cardIdStrs
  currentHand <- use (#coreState % #hand)
  let (toDiscard, keep) = partition (`elem` cids) currentHand
  modify $ #coreState % #hand .~ keep
  modify $ #coreState % #discard %~ (toDiscard ++)

-- Generic 'CardsMoved' event? Or just state update.

returnCardsToDeck :: (RandomGen g) => [Text] -> GameM g ()
returnCardsToDeck cardIdStrs = do
  let cids = map (CardInstanceId . read . unpack) cardIdStrs
  currentHand <- use (#coreState % #hand)
  let (toReturn, keep) = partition (`elem` cids) currentHand
  modify $ #coreState % #hand .~ keep

  -- Shuffle into deck? Or put on top? "ReturnToDeck" often implies top or shuffle.
  -- Let's shuffle them in for now or top?
  -- Usually "Return to Deck" -> Shuffle.
  currentDeck <- use (#coreState % #deck)
  newDeck <- GameM . lift $ shuffleListM (toReturn ++ currentDeck)
  modify $ #coreState % #deck .~ newDeck
  tell [DeckShuffled]
