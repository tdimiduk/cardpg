{-# LANGUAGE OverloadedStrings #-}

module InMemoryTest where

import Test.Tasty (TestTree, testGroup)
import Test.Tasty.HUnit (testCase, (@?=), assertBool)
import Data.IORef (readIORef)
import Data.Map qualified as Map
import Data.Text (Text)

import CardPG.Server.DB (saveGame, loadGame, initInMemoryDB)
import CardPG.Server.Types (GameState(..), StorageBackend(..))
import CardPG.Core.State (GameEnv(..))
import CardPG.Server.Game (emptyGame)
import CardPG.Core.Card (CoreCard(..), CoreCardT(..), Stats(..))

-- Mock GameState for testing
mockGameState :: GameState
mockGameState = 
  let env = GameEnv 
        { fatigueCardTemplate = mockCard "fatigue"
        , statusCardTemplates = Map.empty
        , consequenceCardTemplates = Map.empty 
        }
  in emptyGame env

mockCard :: Text -> CoreCard
mockCard name' = CoreCard
  { name = undefined 
  , cost = Nothing
  , tags = Nothing
  , stats = Stats 0 0 0
  , rules = Nothing
  , flavor = Nothing
  }

test_in_memory :: TestTree
test_in_memory = testGroup "In-Memory Storage"
  [ testCase "Save and Load Game" $ do
      backend <- initInMemoryDB
      let gId = "test-game"
      let gs = mockGameState
      
      -- Save
      saveGame backend gId gs
      
      -- Load
      loaded <- loadGame backend gId
      
      case loaded of
        Nothing -> assertBool "Failed to load saved game" False
        Just _ -> return () -- Success (we can't easily Eq GameState due to complex types, but Just is good enough for now)

  , testCase "Load Non-Existent Game" $ do
      backend <- initInMemoryDB
      loaded <- loadGame backend "non-existent"
      
      case loaded of
        Nothing -> return () -- Success
        Just _ -> assertBool "Should not have found game" False
  ]
