{-# LANGUAGE LambdaCase #-}
{-# LANGUAGE OverloadedLabels #-}
{-# LANGUAGE OverloadedRecordDot #-}
{-# LANGUAGE OverloadedStrings #-}

module GameTest where

import Control.Lens
import Control.Monad.State (runState)
import Data.Aeson (encode)
import Data.Generics.Labels ()
import Data.List (isInfixOf)
import Data.Map.Strict qualified as Map
import Data.Maybe (fromJust)
import Data.Text (Text)
import System.Random (mkStdGen)
import Test.Tasty (TestTree, testGroup)
import Test.Tasty.HUnit (assertBool, testCase, (@?=))

import Core.Card (ConsequenceCard (..), CoreCard (..), Identified (..), Stats (..))
import Core.Logic.Deck (drawCard)
import Core.NonEmptyText (mkNonEmptyText)
import Core.Primitives
  ( ActorId (..)
  , CardInstanceId (..)
  , ChallengeId (..)
  )
import Core.Rules (AttackDef (..))
import Core.State
  ( ActionStack (..)
  , ActiveChallenge (..)
  , ActiveDefense (..)
  , ActorState (..)
  , ChallengeSource (..)
  , CoreCardState (..)
  , GameEnv (..)
  , GameEvent (..)
  , PlannedAction (..)
  , SpatialState (..)
  , TableState (..)
  )
import Core.Stats (ResourceType (..), StackPower (..))

import Api.Request qualified as Req
import Api.Types (ClientRole (..))
import Control.Concurrent (newMVar, readMVar)
import Server.Config (Config (..), DBConfig (..))
import Server.DB
  ( SqlSerial (..)
  , initInMemoryDB
  , loadGame
  , loadGameEvents
  , loadGameRecord
  , saveGame
  , saveGameEvents
  )
import Server.DB.Schema (GameEventRecordT (..), GameT (..))
import Server.Dispatch (processCommand)
import Server.Engine (runActorAction)
import Server.Game (GameState (..), addActor, emptyGame)
import Server.ReflexConnection (checkPermission, handleGameCommand)
import Server.Types
  ( ActorGameEvent (..)
  , Client (..)
  , LogEntry (..)
  , LogId (..)
  , LogPayload (..)
  , LogSender (..)
  , Phase (..)
  , ServerState (..)
  , StateUpdate (..)
  , newServerState
  )

test_game :: TestTree
test_game =
  testGroup
    "Server Game Engine"
    [ testCase "Add Actor and Run Action" $ do
        let env =
              GameEnv
                { fatigueCardTemplate = mockCard "fatigue"
                , statusCardTemplates = Map.empty
                , consequenceCardTemplates = Map.empty
                }
        let gen = mkStdGen 0
        let game0 = emptyGame env

        let actorId = ActorId (read "00000000-0000-0000-0000-000000000001")
        let cardId = CardInstanceId (read "00000000-0000-0000-0000-000000000002")
        let deck = [Identified cardId (mockCard "test")]
        let actorState = emptyActorState & #coreState . #deck .~ deck

        let game1 = addActor actorId actorState game0

        -- Run drawCard
        let ((events, game2), _) = runState (runActorAction actorId drawCard game1) gen

        -- Verify Events
        fmap length events @?= Just 1
        case events of
          Just [CardDrawn c] -> c.id @?= cardId
          _ -> assertBool "Expected CardDrawn event" False

        -- Verify State Update
        let actorSt' = game2 ^. #actors . at actorId
        case (actorSt' :: Maybe ActorState) of
          Nothing -> assertBool "Actor state lost" False
          Just st -> do
            (st ^. #coreState . #hand) @?= deck
            (st ^. #coreState . #deck) @?= []
    , testCase "Gameplay Sequence (Command Processing)" $ do
        let env =
              GameEnv
                { fatigueCardTemplate = mockCard "fatigue"
                , statusCardTemplates = Map.empty
                , consequenceCardTemplates = Map.empty
                }
        let gen = mkStdGen 1
        let game0 = emptyGame env

        let actorId = ActorId (read "00000000-0000-0000-0000-000000000001")
        let cid1 = CardInstanceId (read "00000000-0000-0000-0000-000000000002")
        let cid2 = CardInstanceId (read "00000000-0000-0000-0000-000000000003")
        let card1 = Identified cid1 (mockCard "c1")
        let card2 = Identified cid2 (mockCard "c2")
        let deck = [card1, card2]

        let actorState = emptyActorState & #coreState . #deck .~ deck
        let game1 = addActor actorId actorState game0

        -- 1. Draw Command
        let ((game2, _, actions, _), gen2) = runState (processCommand (Req.DrawCards actorId) game1) gen

        case actions of
          [evt] -> do
            evt.actorId @?= Just actorId
            case evt.event of
              CardDrawn c -> c.id @?= cid1
              _ -> assertBool "Expected CardDrawn event" False
          _ -> assertBool "Expected exactly one action" False

        let actorSt2 = game2 ^. #actors . at actorId
        case actorSt2 of
          Nothing -> assertBool "Actor state lost" False
          Just st -> do
            (st ^. #coreState . #hand) @?= [card1]
            (st ^. #coreState . #deck) @?= [card2]

        -- 2. Defend Command
        let cid = ChallengeId (read "00000000-0000-0000-0000-000000000001")

        -- We must inject a LogChallenge into history for the defense to work
        let challenge = ActiveChallenge cid (CSAdHoc "test" Nothing) 1 Red
        let logPayload = LogChallenge challenge PPass
        let logEntry = LogEntry (LogId (read "00000000-0000-0000-0000-000000000099")) SenderGM logPayload

        let game2WithHistory = game2{history = game2.history ++ [logEntry]}

        let ((game3, _, actions2, _), _) = runState (processCommand (Req.Defend actorId cid) game2WithHistory) gen2

        case actions2 of
          [evt2] -> do
            evt2.actorId @?= Just actorId
            case evt2.event of
              CardDefended _ c -> c.id @?= cid2
              _ -> assertBool "Expected CardDefended event" False
          _ -> assertBool "Expected exactly one action" False

        -- Verify Actor State in Game
        let actorSt3 = game3 ^. #actors . at actorId
        case actorSt3 of
          Nothing -> assertBool "Actor state lost" False
          Just st -> do
            case st ^. #coreState . #defending of
              Just (ActiveDefense c cards) -> do
                c.id @?= cid
                map (.id) cards @?= [cid2]
              Nothing -> assertBool "Expected defending state" False
            (st ^. #coreState . #deck) @?= []
    , testCase "Gameplay Sequence (Fatigue)" $ do
        let env =
              GameEnv
                { fatigueCardTemplate = mockCard "fatigue"
                , statusCardTemplates = Map.empty
                , consequenceCardTemplates = Map.empty
                }
        let gen = mkStdGen 2
        let game0 = emptyGame env

        let actorId = ActorId (read "00000000-0000-0000-0000-000000000001")
        let actorState = emptyActorState -- Empty deck, empty discard
        let game1 = addActor actorId actorState game0

        let ((game2, _, actions, _), _) = runState (processCommand (Req.DrawCards actorId) game1) gen

        let actionTypes = map (toConstr . (.event)) actions
        actionTypes @?= ["CardsCreated", "DeckShuffled", "CardDrawn"]

        let actorSt2 = game2 ^. #actors . at actorId
        case actorSt2 of
          Nothing -> assertBool "Actor state lost" False
          Just st -> do
            length (st ^. #coreState . #hand) @?= 1
            length (st ^. #coreState . #deck) @?= 1
    , testCase "Round Conclusion (concludeRound)" $ do
        let env =
              GameEnv
                { fatigueCardTemplate = mockCard "fatigue"
                , statusCardTemplates = Map.empty
                , consequenceCardTemplates = Map.empty
                }
        let gen = mkStdGen 3
        let game0 = emptyGame env

        let actorId = ActorId (read "00000000-0000-0000-0000-000000000001")
        let cid1 = CardInstanceId (read "00000000-0000-0000-0000-000000000002")
        let cid3 = CardInstanceId (read "00000000-0000-0000-0000-000000000003")
        let cid4 = CardInstanceId (read "00000000-0000-0000-0000-000000000004")

        let card1 = Identified cid1 (mockCard "c1")
        let card3 = Identified cid3 (mockCard "c3")
        let card4 = Identified cid4 (mockCard "c4")

        let deck = [card3, card4]
        let defId = ChallengeId (read "00000000-0000-0000-0000-000000000099")
        let defChallenge = ActiveChallenge defId (CSAdHoc "test" Nothing) 1 Red
        let defending = Just $ ActiveDefense defChallenge [card1]

        let actorState =
              emptyActorState
                & #coreState
                  . #defending
                  .~ defending
                & #coreState
                  . #discard
                  .~ []
                & #coreState
                  . #deck
                  .~ deck

        let game1 = addActor actorId actorState game0

        game1.roundNumber @?= 1

        -- Run concludeRound
        let ((game2, updatesResult, roundActions, _), gen2) = runState (processCommand Req.EndRound game1) gen

        -- Verify Round Number incremented and RoundStarted event was emitted
        game2.roundNumber @?= 2
        assertBool
          "Expected RoundStarted 2 event"
          (any (\case ActorGameEvent Nothing (RoundStarted 2) -> True; _ -> False) roundActions)

        -- Run next EndRound to verify sequential increment
        let ((game3, _, roundActions2, _), _) = runState (processCommand Req.EndRound game2) gen2
        game3.roundNumber @?= 3
        assertBool
          "Expected RoundStarted 3 event"
          (any (\case ActorGameEvent Nothing (RoundStarted 3) -> True; _ -> False) roundActions2)

        -- Verify Updates
        let updates = case updatesResult of
              Right u -> u
              Left _ -> []
        case updates of
          [StateUpdate{updateActorId = uid}] -> uid @?= actorId
          _ -> assertBool "Expected exactly one update" False

        -- Verify Actor State in Game
        let actorSt' = game2 ^. #actors . at actorId
        case actorSt' of
          Nothing -> assertBool "Actor state lost" False
          Just st -> do
            -- Defense should be cleared
            (st ^. #coreState . #defending) @?= Nothing
            -- Card should be in discard
            (st ^. #coreState . #discard) @?= [card1]
    , testCase "NPC Auto-Planning" $ do
        let env =
              GameEnv
                { fatigueCardTemplate = mockCard "fatigue"
                , statusCardTemplates = Map.empty
                , consequenceCardTemplates = Map.empty
                }
        let gen = mkStdGen 4
        let game0 = emptyGame env

        let npcId = ActorId (read "00000000-0000-0000-0000-000000000099")
        let actionCid = CardInstanceId (read "00000000-0000-0000-0000-000000000010")
        let resCid = CardInstanceId (read "00000000-0000-0000-0000-000000000011")

        let actionCard = Identified actionCid (mockAttackCard "Attack" Red 1)
        let resCard = Identified resCid (mockResCard "Resource")

        let hand = [actionCard, resCard]

        let npcState =
              emptyActorState
                & #name
                  .~ "Bad Guy"
                & #actorType
                  .~ "Monster"
                & #coreState
                  . #hand
                  .~ hand

        let game1 = addActor npcId npcState game0

        -- Send EndRoundIntent to trigger auto-planning for next round
        let ((game2, _, events, _), _) = runState (processCommand Req.EndRound game1) gen

        -- Expect ActionPlanned event (from auto-planning)
        let planEvents = [e | e <- events, case e.event of ActionPlanned _ -> True; _ -> False]
        length planEvents @?= 1

        -- Verify Plan
        let actorSt = game2 ^. #actors . at npcId
        case actorSt of
          Nothing -> assertBool "NPC state lost" False
          Just st -> do
            case st.coreState.planned of
              Just (PStandard stack) -> do
                stack.actionCard.id @?= actionCid
                length stack.resources @?= 1
                case stack.resources of
                  [res] -> res.id @?= resCid
                  _ -> assertBool "Expected one resource" False
              _ -> assertBool "Expected Standard Plan" False
    , testCase "Explicit Plan Action Command" $ do
        let env =
              GameEnv
                { fatigueCardTemplate = mockCard "fatigue"
                , statusCardTemplates = Map.empty
                , consequenceCardTemplates = Map.empty
                }
        let gen = mkStdGen 5
        let game0 = emptyGame env

        let actorId = ActorId (read "00000000-0000-0000-0000-000000000001")
        let actionCid = CardInstanceId (read "00000000-0000-0000-0000-000000000002")
        let resCid = CardInstanceId (read "00000000-0000-0000-0000-000000000003")

        let actionCard = Identified actionCid (mockAttackCard "Attack" Red 1)
        let resCard = Identified resCid (mockResCard "Resource")

        let hand = [actionCard, resCard]

        let actorState =
              emptyActorState
                & #coreState
                  . #hand
                  .~ hand

        let game1 = addActor actorId actorState game0

        -- Send PlanAction Intent with Strings wrapping UUIDs
        let cmd =
              Req.PlanAction
                actorId
                actionCid
                [resCid]

        let ((_game2, _, actions, _), _) = runState (processCommand cmd game1) gen

        case actions of
          [ActorGameEvent _ (ActionPlanned (PStandard stack))] -> do
            stack.actionCard.id @?= actionCid
            case stack.resources of
              [res] -> res.id @?= resCid
              _ -> assertBool "Expected one resource" False
          _ -> assertBool "Expected ActionPlanned event with one action" False
    , testCase "Lossless Consequence and Card Telemetry" $ do
        let consCard = mockConsCard "Bleeding" 1
        let env =
              GameEnv
                { fatigueCardTemplate = mockCard "fatigue"
                , statusCardTemplates = Map.empty
                , consequenceCardTemplates = Map.singleton "Bleeding" consCard
                }
        let gen = mkStdGen 42
        let game0 = emptyGame env

        let actorId = ActorId (read "00000000-0000-0000-0000-000000000001")
        let cardId = CardInstanceId (read "00000000-0000-0000-0000-000000000002")
        let drawCardItem = Identified cardId (mockCard "Strike")
        let actorState = emptyActorState & #coreState . #deck .~ [drawCardItem]
        let game1 = addActor actorId actorState game0

        let challengeId = ChallengeId (read "00000000-0000-0000-0000-000000000099")

        -- 1. AddConsequence carrying ChallengeId
        let ((game2, _, _, newLogs), gen2) =
              runState (processCommand (Req.AddConsequence actorId (Just 1) (Just challengeId)) game1) gen

        case filter (\l -> case l.payload of LogConsequence{} -> True; _ -> False) newLogs of
          [conseqLog] -> do
            case conseqLog.payload of
              LogConsequence aid mCid c -> do
                aid @?= actorId
                mCid @?= Just challengeId
                c.content.name @?= fromJust (mkNonEmptyText "Bleeding")
                c.content.severity @?= 1
                -- Verify JSON serialization includes structured fields
                assertBool "JSON contains challengeId" ("challengeId" `isInfixOf` show (encode conseqLog.payload))
                assertBool
                  "JSON contains logConsequence"
                  ("logConsequence" `isInfixOf` show (encode conseqLog.payload))
              _ -> assertBool "Expected LogConsequence" False
          _ -> assertBool "Expected LogConsequence in newLogs" False

        -- 2. DrawCards emits LogCardDrawn with actorId and full card
        let ((_, _, _, drawLogs), _) =
              runState (processCommand (Req.DrawCards actorId) game2) gen2

        case filter (\l -> case l.payload of LogCardDrawn{} -> True; _ -> False) drawLogs of
          [drawLog] -> do
            case drawLog.payload of
              LogCardDrawn aid c -> do
                aid @?= actorId
                c.id @?= cardId
                c.content.name @?= fromJust (mkNonEmptyText "Strike")
                assertBool "JSON contains logCardDrawn" ("logCardDrawn" `isInfixOf` show (encode drawLog.payload))
              _ -> assertBool "Expected LogCardDrawn" False
          _ -> assertBool "Expected LogCardDrawn in drawLogs" False
    , testCase "State Persistence and Append-Only Event Table" $ do
        let env =
              GameEnv
                { fatigueCardTemplate = mockCard "fatigue"
                , statusCardTemplates = Map.empty
                , consequenceCardTemplates = Map.empty
                }
        let gen = mkStdGen 100
        let game0 = emptyGame env

        let actorId = ActorId (read "00000000-0000-0000-0000-000000000001")
        let cardId = CardInstanceId (read "00000000-0000-0000-0000-000000000002")
        let card1 = Identified cardId (mockCard "c1")
        let actorState = emptyActorState & #coreState . #deck .~ [card1]
        let game1 = addActor actorId actorState game0

        backend <- initInMemoryDB
        let sessionId = "starter-20260926-0715"

        -- 1. Initial save at session boot
        saveGame backend sessionId "starter.yaml" game1

        -- 2. Process command (Draw)
        let ((game2, _, drawActions, drawLogs), gen2) = runState (processCommand (Req.DrawCards actorId) game1) gen
        saveGameEvents backend sessionId game2.roundNumber drawActions drawLogs
        saveGame backend sessionId "starter.yaml" game2

        -- 3. Process command (EndRound -> increments round to 2)
        let ((game3, _, roundActions, roundLogs), _) = runState (processCommand Req.EndRound game2) gen2
        saveGameEvents backend sessionId game3.roundNumber roundActions roundLogs
        saveGame backend sessionId "starter.yaml" game3

        -- 4. Verify Server Restart: load latest state from DB
        mLoaded <- loadGame backend sessionId
        case mLoaded of
          Nothing -> assertBool "Failed to load persisted game after restart" False
          Just loadedGs -> do
            loadedGs.roundNumber @?= 2
            let loadedActor = loadedGs ^. #actors . at actorId
            case loadedActor of
              Nothing -> assertBool "Actor not found in loaded game" False
              Just st -> do
                assertBool "Drawn card is present in hand" (any (\c -> c.id == cardId) (st ^. #coreState . #hand))
                length (st ^. #coreState . #hand) @?= 3

        -- 5. Verify Game Record Metadata
        mRec <- loadGameRecord backend sessionId
        case mRec of
          Nothing -> assertBool "Failed to load game record" False
          Just gameRec -> do
            gameRec.gameId @?= sessionId
            gameRec.scenarioName @?= "starter.yaml"
            gameRec.gameStatus @?= "Active"
            gameRec.currentRound @?= 2

        -- 6. Verify sequential events in append-only table
        evts <- loadGameEvents backend sessionId
        assertBool "Expected at least 2 events" (length evts >= 2)

        -- Check first event is from round 1 (CardDrawn)
        case evts of
          firstEvt : _ -> do
            firstEvt.eventId @?= SqlSerial 1
            firstEvt.gameId @?= sessionId
            firstEvt.roundNumber @?= 1
            firstEvt.eventType @?= "CardDrawn"
          [] -> assertBool "Expected events list to be non-empty" False

        -- Check round 2 event (RoundStarted)
        let round2Evts = filter (\e -> e.eventType == "RoundStarted") evts
        case round2Evts of
          [rEvt] -> do
            rEvt.roundNumber @?= 2
          _ -> assertBool "Expected exactly one RoundStarted event in round 2" False
    , testCase "Phase Transition Checkpointing and GM Undo" $ do
        backend <- initInMemoryDB
        let consCard = mockConsCard "Bleeding" 1
        let env =
              GameEnv
                { fatigueCardTemplate = mockCard "fatigue"
                , statusCardTemplates = Map.empty
                , consequenceCardTemplates = Map.singleton "Bleeding" consCard
                }
        let gen = mkStdGen 42
        let game0 = emptyGame env
        let actorId = ActorId (read "00000000-0000-0000-0000-000000000001")
        let cardId = CardInstanceId (read "00000000-0000-0000-0000-000000000002")
        let deck = [Identified cardId (mockCard "test")]
        let actorState = emptyActorState & #coreState . #deck .~ deck
        let game1 = addActor actorId actorState game0

        let gmCid = read "00000000-0000-0000-0000-000000000010"
        let playerCid = read "00000000-0000-0000-0000-000000000020"
        let gmClient = Client gmCid "GM" RoleGM []
        let playerClient = Client playerCid "Player" (RolePlayer actorId) []

        let cfg =
              Config
                { dbConfig = DBConfig "" "" "" ""
                , serverPort = 3004
                , cardsDir = "data/cards"
                , scenarioFile = "data/scenarios/starter.yaml"
                , savedGameFile = Nothing
                , useInMemoryDB = True
                , useGargoyle = False
                , seed = Just 42
                , gameId = "test-undo-game"
                }

        let initState =
              (newServerState backend game1 gen cfg [])
                { clients = Map.fromList [(gmCid, gmClient), (playerCid, playerClient)]
                }
        stateMVar <- newMVar initState

        -- 1. Test checkPermission
        checkPermission RoleGM Req.UndoPhase @?= True
        checkPermission (RolePlayer actorId) Req.UndoPhase @?= False
        checkPermission RoleUnassigned Req.UndoPhase @?= False

        -- 2. Non-GM calling UndoPhase receives Permission Denied
        nonGmRes <- handleGameCommand playerClient stateMVar Req.UndoPhase
        nonGmRes @?= Left "Permission denied"

        -- 3. GM calling UndoPhase with no checkpoints receives error
        emptyUndoRes <- handleGameCommand gmClient stateMVar Req.UndoPhase
        emptyUndoRes @?= Left "No phase checkpoint to undo."

        -- 4. GM transitions Planning -> Resolution
        res1 <- handleGameCommand gmClient stateMVar Req.StartResolution
        case res1 of
          Left err -> assertBool ("Failed StartResolution: " ++ show err) False
          Right _ -> return ()

        sAfterRes <- readMVar stateMVar
        sAfterRes.gameState.phase @?= Resolution
        length sAfterRes.checkpoints @?= 1
        (head sAfterRes.checkpoints).phase @?= Planning

        -- 5. Mutate state during Resolution (e.g. GM adds consequence)
        addConsRes <- handleGameCommand gmClient stateMVar (Req.AddConsequence actorId (Just 1) Nothing)
        case addConsRes of
          Left err -> assertBool ("Failed AddConsequence: " ++ show err) False
          Right _ -> return ()

        sWithCons <- readMVar stateMVar
        let mActorWithCons = Map.lookup actorId sWithCons.gameState.actors
        case mActorWithCons of
          Nothing -> assertBool "Actor missing" False
          Just a -> length a.tableState.consequences @?= 1

        -- 6. GM triggers UndoPhase
        undoRes <- handleGameCommand gmClient stateMVar Req.UndoPhase
        case undoRes of
          Left err -> assertBool ("Failed UndoPhase: " ++ show err) False
          Right stateUpdates -> do
            length stateUpdates @?= 1

        sAfterUndo <- readMVar stateMVar
        -- Restored back to Planning
        sAfterUndo.gameState.phase @?= Planning
        -- Checkpoints now empty
        length sAfterUndo.checkpoints @?= 0
        -- Consequence added during resolution is gone!
        let mActorRestored = Map.lookup actorId sAfterUndo.gameState.actors
        case mActorRestored of
          Nothing -> assertBool "Actor missing" False
          Just a -> length a.tableState.consequences @?= 0

        -- Last log is the rewound notice
        case reverse sAfterUndo.gameState.history of
          (lastLog : _) -> case lastLog.payload of
            LogInfo txt -> assertBool "Expected rewound log notice" ("rewound phase" `isInfixOf` show txt)
            _ -> assertBool "Expected LogInfo payload" False
          [] -> assertBool "Expected history" False

        -- 7. Transition Planning -> Resolution -> EndRound (Round 2 Planning) -> Undo to Round 1 Resolution
        _ <- handleGameCommand gmClient stateMVar Req.StartResolution
        _ <- handleGameCommand gmClient stateMVar Req.EndRound

        sRound2 <- readMVar stateMVar
        sRound2.gameState.roundNumber @?= 2
        sRound2.gameState.phase @?= Planning
        length sRound2.checkpoints @?= 2

        -- Undo back to Round 1 Resolution
        undoR2Res <- handleGameCommand gmClient stateMVar Req.UndoPhase
        case undoR2Res of
          Left err -> assertBool ("Failed undo round 2: " ++ show err) False
          Right _ -> return ()

        sRestoredR1 <- readMVar stateMVar
        sRestoredR1.gameState.roundNumber @?= 1
        sRestoredR1.gameState.phase @?= Resolution
        length sRestoredR1.checkpoints @?= 1
    ]

-- Helpers

mockConsCard :: Text -> Int -> ConsequenceCard
mockConsCard name' sev =
  ConsequenceCard
    { name = fromJust (mkNonEmptyText name')
    , tags = Nothing
    , passive = Nothing
    , effects = Nothing
    , severity = sev
    , notes = Nothing
    , rules = Nothing
    }

-- Helper to match constructor names for easier assertion
toConstr :: GameEvent -> String
toConstr (CardsCreated{}) = "CardsCreated"
toConstr (DeckShuffled{}) = "DeckShuffled"
toConstr (CardDrawn{}) = "CardDrawn"
toConstr (CardDefended{}) = "CardDefended"
toConstr _ = "Other"

mockCard :: Text -> CoreCard
mockCard name' =
  CoreCard
    { name = fromJust (mkNonEmptyText name')
    , cost = Nothing
    , tags = Nothing
    , attack = Nothing
    , stats = Stats 0 0 0
    , rules = Nothing
    , flavor = Nothing
    }

mockAttackCard :: Text -> ResourceType -> Int -> CoreCard
mockAttackCard _name' color cost' =
  CoreCard
    { name = undefined
    , cost = Just cost'
    , tags = Nothing
    , stats = Stats 1 1 1
    , attack =
        Just
          ( AttackDef
              { power = StackPower color 0 Nothing
              , resistedBy = color
              , consequences = Nothing
              , effect = Nothing
              }
          )
    , rules = Nothing
    , flavor = Nothing
    }

mockResCard :: Text -> CoreCard
mockResCard _name' =
  CoreCard
    { name = undefined
    , cost = Nothing
    , tags = Nothing
    , stats = Stats 5 5 5
    , attack = Nothing
    , rules = Nothing
    , flavor = Nothing
    }

emptyActorState :: ActorState
emptyActorState =
  ActorState
    { coreState =
        CoreCardState
          { deck = []
          , hand = []
          , discard = []
          , defending = Nothing
          , inPlay = Map.empty
          , planned = Nothing
          , revealed = Nothing
          }
    , tableState =
        TableState
          { assets = Map.empty
          , consequences = []
          }
    , name = "Tester"
    , actorType = "PC"
    , spatial = SpatialState 0 0 1 Nothing Nothing
    , plannedMove = Nothing
    , plannedRank = Nothing
    }
