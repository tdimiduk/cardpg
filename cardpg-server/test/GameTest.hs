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
import CardPG.Core.Primitives (CardInstanceId(..), ActorId(..), StackPower(..), ResourceType(..))
import CardPG.Core.State (ActorState(..), CoreCardState(..), GameEnv(..), TableState(..), GameEvent(..), CorePlayState(..), SpatialState(..), PlannedAction(..), ActionStack(..))
import CardPG.Core.Card (CoreCard(..), CoreCardT(..), Stats(..))
import CardPG.Core.RuleDefs (RuleT(..), AttackDefT(..))
import Data.List.NonEmpty (NonEmpty(..))

import CardPG.Server.Game (GameState(..), emptyGame, addActor, runActorAction, processCommand, concludeRound)
import CardPG.Server.Types (Command(..), ActorGameEvent(..), StateUpdate(..))

test_game :: TestTree
test_game = testGroup "Server Game Engine"
  [ testCase "Add Actor and Run Action" $ do
      let env = GameEnv { fatigueCardTemplate = mockCard "fatigue", statusCardTemplates = Map.empty, consequenceCardTemplates = Map.empty }
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
      let env = GameEnv { fatigueCardTemplate = mockCard "fatigue", statusCardTemplates = Map.empty, consequenceCardTemplates = Map.empty }
      let gen = mkStdGen 1
      let game0 = emptyGame env gen
      
      let actorId = ActorId (read "00000000-0000-0000-0000-000000000001")
      let card1 = CardInstanceId (read "00000000-0000-0000-0000-000000000002")
      let card2 = CardInstanceId (read "00000000-0000-0000-0000-000000000003")
      let deck = [card1, card2]
      
      let actorState = emptyActorState & #coreState % #deck .~ deck
      let game1 = addActor actorId actorState game0
      
      -- 1. Draw Command
      let (game2, _updates, actions) = processCommand (DrawIntent actorId) game1
      
      length actions @?= 1
      let evt = head actions
      evt.actorId @?= actorId
      case evt.event of
        CardDrawn cid -> cid @?= card1
        _ -> assertBool "Expected CardDrawn event" False
      
      let actorSt2 = game2 ^. #actors % at actorId
      case actorSt2 of
        Nothing -> assertBool "Actor state lost" False
        Just st -> do
           (st ^. #coreState % #hand) @?= [card1]
           (st ^. #coreState % #deck) @?= [card2]
      
      -- 2. Defend Command
      let (game3, _updates2, actions2) = processCommand (DefendIntent actorId) game2
      
      length actions2 @?= 1
      let evt2 = head actions2
      evt2.actorId @?= actorId
      case evt2.event of
        CardDefended cid -> cid @?= card2 -- The card from deck
        _ -> assertBool "Expected CardDefended event" False

      -- Verify Actor State in Game
      let actorSt3 = game3 ^. #actors % at actorId
      case actorSt3 of
        Nothing -> assertBool "Actor state lost" False
        Just st -> do
           (st ^. #coreState % #defending) @?= [card2]
           (st ^. #coreState % #deck) @?= []

  , testCase "Gameplay Sequence (Fatigue)" $ do
      let env = GameEnv { fatigueCardTemplate = mockCard "fatigue", statusCardTemplates = Map.empty, consequenceCardTemplates = Map.empty }
      let gen = mkStdGen 2
      let game0 = emptyGame env gen
      
      let actorId = ActorId (read "00000000-0000-0000-0000-000000000001")
      let actorState = emptyActorState -- Empty deck, empty discard
      let game1 = addActor actorId actorState game0
      
      let (game2, _updates, actions) = processCommand (DrawIntent actorId) game1
      
      let actionTypes = map (toConstr . (.event)) actions
      actionTypes @?= ["CardsCreated", "DeckShuffled", "CardDrawn"]
      
      let actorSt2 = game2 ^. #actors % at actorId
      case actorSt2 of
        Nothing -> assertBool "Actor state lost" False
        Just st -> do
           length (st ^. #coreState % #hand) @?= 1
           length (st ^. #coreState % #deck) @?= 1

  , testCase "Round Conclusion (concludeRound)" $ do
      let env = GameEnv { fatigueCardTemplate = mockCard "fatigue", statusCardTemplates = Map.empty, consequenceCardTemplates = Map.empty }
      let gen = mkStdGen 3
      let game0 = emptyGame env gen
      
      let actorId = ActorId (read "00000000-0000-0000-0000-000000000001")
      let card1 = CardInstanceId (read "00000000-0000-0000-0000-000000000002")
      let card3 = CardInstanceId (read "00000000-0000-0000-0000-000000000003")
      let card4 = CardInstanceId (read "00000000-0000-0000-0000-000000000004")
      let deck = [card3, card4] -- Enough for 2 draws
      let defending = [card1] -- Actor has active defense
      
      let actorState = emptyActorState 
            & #coreState % #defending .~ defending
            & #coreState % #discard .~ []
            & #coreState % #deck .~ deck
            
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


  , testCase "NPC Auto-Planning" $ do
      let env = GameEnv { fatigueCardTemplate = mockCard "fatigue", statusCardTemplates = Map.empty, consequenceCardTemplates = Map.empty }
      let gen = mkStdGen 4
      let game0 = emptyGame env gen
      
      let npcId = ActorId (read "00000000-0000-0000-0000-000000000099")
      let actionCid = CardInstanceId (read "00000000-0000-0000-0000-000000000010")
      let resCid = CardInstanceId (read "00000000-0000-0000-0000-000000000011")
      
      let actionCard = mockAttackCard "Attack" Red 1 -- Cost 1, Red
      let resCard = mockResCard "Resource" -- High stats
      
      let hand = [actionCid, resCid]
      let registry = Map.fromList [(actionCid, actionCard), (resCid, resCard)]
      
      let npcState = emptyActorState 
             & #name .~ "Bad Guy"
             & #actorType .~ "Monster"
             & #coreState % #hand .~ hand
             & #coreState % #registry .~ registry
             
      let game1 = addActor npcId npcState game0
      
      -- Send EndRoundIntent to trigger auto-planning for next round
      let (game2, _, events) = processCommand (EndRoundIntent npcId) game1
      
      -- Expect ActionPlanned event (from auto-planning)
      let planEvents = [e | e <- events, case e.event of ActionPlanned _ -> True; _ -> False]
      length planEvents @?= 1
      
      -- Verify Plan
      let actorSt = game2 ^. #actors % at npcId
      case actorSt of
        Nothing -> assertBool "NPC state lost" False
        Just st -> do
           case st.coreState.planned of
             Just (PStandard stack) -> do
               stack.actionCard @?= actionCid
               length stack.resources @?= 1
               head stack.resources @?= resCid
             _ -> assertBool "Expected Standard Plan" False

  ]

-- Helpers

-- Helper to match constructor names for easier assertion
toConstr :: GameEvent -> String
toConstr (CardsCreated {}) = "CardsCreated"
toConstr (DeckShuffled {}) = "DeckShuffled"
toConstr (CardDrawn {}) = "CardDrawn"
toConstr (CardDefended {}) = "CardDefended"
toConstr _ = "Other"

mockCard :: Text -> CoreCard
mockCard name' = CoreCard
  { name = undefined -- Safe for this test
  , cost = Nothing
  , tags = Nothing
  , stats = Stats 0 0 0
  , rules = Nothing
  , flavor = Nothing
  }

mockAttackCard :: Text -> ResourceType -> Int -> CoreCard
mockAttackCard name' color cost' = CoreCard
  { name = undefined
  , cost = Just cost'
  , tags = Nothing
  , stats = Stats 1 1 1
  , rules = Just $ RuleAttack (AttackDef { power = StackPower color 0 Nothing, resistedBy = color, effect = Nothing }) :| []
  , flavor = Nothing
  }

mockResCard :: Text -> CoreCard
mockResCard name' = CoreCard
  { name = undefined
  , cost = Nothing
  , tags = Nothing
  , stats = Stats 5 5 5
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
      , consequences = []
      , consequenceRegistry = Map.empty
      }
  , name = "Tester"
  , actorType = "PC"
  , spatial = SpatialState 0 0 1 Nothing
  , plannedMove = Nothing
  }
