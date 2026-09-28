{-# LANGUAGE OverloadedRecordDot #-}
{-# LANGUAGE OverloadedStrings #-}

module InMemoryTest where

import Data.Map qualified as Map
import Data.Text (Text)
import Test.Tasty (TestTree, testGroup)
import Test.Tasty.HUnit (assertBool, testCase, (@?=))

import Api.Types (ActorGameEvent (..))
import Core.Card (CoreCard (..), Stats (..))
import Core.State (GameEnv (..), GameEvent (..))
import Server.DB
  ( SqlSerial (..)
  , initInMemoryDB
  , listGames
  , loadGame
  , loadGameEvents
  , loadGameRecord
  , saveGame
  , saveGameEvents
  )
import Server.DB.Schema (GameEventRecordT (..), GameT (..))
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
    [ testCase "Save and Load Game with Metadata" $ do
        backend <- initInMemoryDB
        let gId = "test-game"
        let gs = mockGameState

        -- Save
        saveGame backend gId "starter.yaml" gs

        -- Load
        loaded <- loadGame backend gId

        case loaded of
          Nothing -> assertBool "Failed to load saved game" False
          Just _ -> return ()

        -- Load record metadata
        mRec <- loadGameRecord backend gId
        case mRec of
          Nothing -> assertBool "Failed to load game record" False
          Just gameRec -> do
            gameRec.gameId @?= gId
            gameRec.scenarioName @?= "starter.yaml"
            gameRec.gameStatus @?= "Active"
            gameRec.currentRound @?= 1

        -- List games
        allGames <- listGames backend
        length allGames @?= 1
    , testCase "Load Non-Existent Game" $ do
        backend <- initInMemoryDB
        loaded <- loadGame backend "non-existent"

        case loaded of
          Nothing -> return () -- Success
          Just _ -> assertBool "Should not have found game" False
    , testCase "Save and Load Game Events" $ do
        backend <- initInMemoryDB
        let gId = "test-session"

        let event1 = ActorGameEvent Nothing (RoundStarted 1)
        let event2 = ActorGameEvent Nothing (RoundStarted 2)

        saveGameEvents backend gId 1 [event1] []
        saveGameEvents backend gId 2 [event2] []

        evts <- loadGameEvents backend gId
        length evts @?= 2

        case evts of
          [r1, r2] -> do
            r1.eventId @?= SqlSerial 1
            r1.gameId @?= gId
            r1.roundNumber @?= 1
            r1.eventType @?= "RoundStarted"

            r2.eventId @?= SqlSerial 2
            r2.gameId @?= gId
            r2.roundNumber @?= 2
            r2.eventType @?= "RoundStarted"
          _ -> assertBool "Expected exactly 2 events" False
    ]
