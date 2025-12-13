{-# LANGUAGE OverloadedLabels #-}
{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE OverloadedRecordDot #-}

module GameTest where

import Control.Monad.State (runState)
import qualified Data.Map.Strict as Map
import Data.Text (Text, pack)
import Optics
import System.Random (mkStdGen)
import Test.Tasty (TestTree, testGroup)
import Test.Tasty.HUnit (testCase, (@?=), assertBool)

import CardPG.Core.Logic (drawCard)
import CardPG.Core.Primitives (CardInstanceId(..), ActorId(..))
import CardPG.Core.State (ActorState(..), CoreCardState(..), GameEnv(..), TableState(..), GameEvent(..), CorePlayState(..), SpatialState(..))
import CardPG.Core.Card (CoreCard(..), CoreCardT(..))

import CardPG.Server.Game (GameState(..), emptyGame, addActor, runActorAction, processCommand, concludeRound)
import CardPG.Server.Types (Command(..), BroadcastAction(..), StateUpdate(..))

test_game :: TestTree
test_game = testGroup "Server Game Engine"
  [ testCase "Add Actor and Run Action" $ do
      let env = GameEnv { fatigueCardTemplate = mockCard "fatigue" }
      let gen = mkStdGen 0
      let game0 = emptyGame env gen
      
      let actorId = ActorId (read "00000000-0000-0000-0000-000000000001")
      let deck = [CardInstanceId (read "00000000-0000-0000-0000-000000000002")]
      let actorState = emptyActorState & #coreState % #deck .~ deck
      
      let game1 = addActor actorId actorState game0
      
      -- Run drawCard
      let (events, game2) = runActorAction actorId drawCard game1
      
      -- Verify Events
      fmap length events @?= Just 1
      case events of
        Just [CardDrawn cid] -> cid @?= head deck
        _ -> assertBool "Expected CardDrawn event" False
        
      -- Verify State Update
      let actorSt' = game2 ^. #actors % at actorId
      case actorSt' of
        Nothing -> assertBool "Actor state lost" False
        Just st -> do
           (st ^. #coreState % #hand) @?= deck
           (st ^. #coreState % #deck) @?= []

  , testCase "Gameplay Sequence (Command Processing)" $ do
      let env = GameEnv { fatigueCardTemplate = mockCard "fatigue" }
      let gen = mkStdGen 1
      let game0 = emptyGame env gen
      
      let actorId = ActorId (read "00000000-0000-0000-0000-000000000001")
      let card1 = CardInstanceId (read "00000000-0000-0000-0000-000000000002")
      let card2 = CardInstanceId (read "00000000-0000-0000-0000-000000000003")
      let deck = [card1, card2]
      
      let actorState = emptyActorState & #coreState % #deck .~ deck
      let game1 = addActor actorId actorState game0
      
      -- 1. Draw Command
      let (game2, res1) = processCommand (DrawIntent actorId) game1
      
      case res1 of
        Nothing -> assertBool "Draw command failed" False
        Just (tid, actions, st) -> do
          tid @?= actorId
          length actions @?= 1
          head actions @?= DrawCards actorId 1
          (st ^. #coreState % #hand) @?= [card1]
          (st ^. #coreState % #deck) @?= [card2]
      
      -- 2. Defend Command
      let (game3, res2) = processCommand (DefendIntent actorId) game2
      
      case res2 of
        Nothing -> assertBool "Defend command failed" False
        Just (tid, actions, st) -> do
          tid @?= actorId
          length actions @?= 1
          -- Note: Defend action doesn't carry card ID in broadcast currently, just notification
          -- But the state should show it in 'defending' stack
          (st ^. #coreState % #defending) @?= [card2]
          (st ^. #coreState % #deck) @?= []

  , testCase "Gameplay Sequence (Fatigue)" $ do
      let env = GameEnv { fatigueCardTemplate = mockCard "fatigue" }
      let gen = mkStdGen 2
      let game0 = emptyGame env gen
      
      let actorId = ActorId (read "00000000-0000-0000-0000-000000000001")
      let actorState = emptyActorState -- Empty deck, empty discard
      let game1 = addActor actorId actorState game0
      
      -- Draw Command on empty deck
      let (game2, res) = processCommand (DrawIntent actorId) game1
      
      case res of
        Nothing -> assertBool "Draw command failed" False
        Just (tid, actions, st) -> do
          tid @?= actorId
          -- Expect: Reshuffle (due to DeckShuffled) AND DrawCards
          -- Note: Logic.drawCard recursively calls itself after fatigue.
          -- Events: [CardsCreated, DeckShuffled, CardDrawn]
          -- Actions: [Reshuffle, DrawCards]
          -- Ordering might vary depending on list construction, likely Reshuffle first.
          
          let actionTypes = map toConstr actions
          actionTypes @?= ["Reshuffle", "DrawCards"]
          
          -- Verify Hand has 1 card (fatigue)
          length (st ^. #coreState % #hand) @?= 1
          
          -- Verify Deck has remaining cards (2 default - 1 drawn = 1)
          length (st ^. #coreState % #deck) @?= 1

  , testCase "Round Conclusion (concludeRound)" $ do
      let env = GameEnv { fatigueCardTemplate = mockCard "fatigue" }
      let gen = mkStdGen 3
      let game0 = emptyGame env gen
      
      let actorId = ActorId (read "00000000-0000-0000-0000-000000000001")
      let card1 = CardInstanceId (read "00000000-0000-0000-0000-000000000002")
      let deck = [] -- Empty deck
      let defending = [card1] -- Actor has active defense
      
      let actorState = emptyActorState 
            & #coreState % #defending .~ defending
            & #coreState % #discard .~ []
            
      let game1 = addActor actorId actorState game0
      
      -- Run concludeRound
      let (game2, updates) = concludeRound game1
      
      -- Verify Updates
      length updates @?= 1
      let StateUpdate { updateActorId = uid } = head updates
      uid @?= actorId
      
      -- Verify Actor State in Game
      let actorSt' = game2 ^. #actors % at actorId
      case actorSt' of
        Nothing -> assertBool "Actor state lost" False
        Just st -> do
           -- Defense should be cleared
           (st ^. #coreState % #defending) @?= []
           -- Card should be in discard
           (st ^. #coreState % #discard) @?= [card1]

  ]

-- Helpers

-- Helper to match constructor names for easier assertion
toConstr :: BroadcastAction -> String
toConstr (Reshuffle {}) = "Reshuffle"
toConstr (DrawCards {}) = "DrawCards"
toConstr (Defend {}) = "Defend"
toConstr _ = "Other"

mockCard :: Text -> CoreCard
mockCard name' = CoreCard
  { name = undefined -- Safe for this test
  , cost = Nothing
  , tags = Nothing
  , stats = undefined
  , rules = Nothing
  , flavor = Nothing
  }

emptyActorState :: ActorState
emptyActorState = ActorState
  { coreState = CoreCardState
      { deck = []
      , hand = []
      , discard = []
      , defending = []
      , inPlay = Map.empty
      , registry = Map.empty
      , planned = Nothing
      }
  , tableState = TableState
      { assets = Map.empty
      , registry = Map.empty
      }
  , name = "Tester"
  , actorType = "PC"
  , spatial = SpatialState 0 0 1 Nothing
  , plannedMove = Nothing
  }
