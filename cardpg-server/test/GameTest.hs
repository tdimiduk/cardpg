{-# LANGUAGE OverloadedLabels #-}
{-# LANGUAGE OverloadedStrings #-}

module GameTest where

import Control.Monad.State (runState)
import qualified Data.Map.Strict as Map
import Data.Text (Text)
import Optics
import System.Random (mkStdGen)
import Test.Tasty (TestTree, testGroup)
import Test.Tasty.HUnit (testCase, (@?=), assertBool)

import CardPG.Core.Logic (drawCard)
import CardPG.Core.Primitives (CardInstanceId(..), TargetId(..))
import CardPG.Core.State (ActorState(..), CoreCardState(..), GameEnv(..), TableState(..), GameEvent(..), CorePlayState(..))
import CardPG.Core.Card (CoreCard(..), CoreCardT(..))

import CardPG.Server.Game (GameState(..), emptyGame, addActor, runActorAction)

test_game :: TestTree
test_game = testGroup "Server Game Engine"
  [ testCase "Add Actor and Run Action" $ do
      let env = GameEnv { fatigueCardTemplate = mockCard "fatigue" }
      let gen = mkStdGen 0
      let game0 = emptyGame env gen
      
      let actorId = TargetId (read "00000000-0000-0000-0000-000000000001")
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

  ]

-- Helpers

mockCard :: Text -> CoreCard
mockCard id' = CoreCard
  { id = Just id'
  , name = undefined -- Safe for this test
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
      }
  , tableState = TableState
      { assets = Map.empty
      , registry = Map.empty
      }
  }
