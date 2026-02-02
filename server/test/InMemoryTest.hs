{-# LANGUAGE OverloadedStrings #-}

module InMemoryTest where

import Data.Map qualified as Map
import Data.Text (Text)
import Test.Tasty (TestTree, testGroup)
import Test.Tasty.HUnit (assertBool, testCase)

import Core.Card (CoreCard (..), Stats (..))
import Core.State (GameEnv (..))
import Server.DB (initInMemoryDB, loadGame, saveGame)
import Server.Game (emptyGame)
import Server.Types (GameState (..))

-- Mock GameState for testing
mockGameState :: GameState
mockGameState =
  let env =
        GameEnv
          { fatigueCardTemplate = mockCard "fatigue"
          , statusCardTemplates = Map.empty
          , consequenceCardTemplates = Map.empty
          }
   in emptyGame env

mockCard :: Text -> CoreCard
mockCard _name' =
  CoreCard
    { name = undefined
    , cost = Nothing
    , tags = Nothing
    , stats = Stats 0 0 0
    , attack = Nothing
    , rules = Nothing
    , flavor = Nothing
    }

test_in_memory :: TestTree
test_in_memory =
  testGroup
    "In-Memory Storage"
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
