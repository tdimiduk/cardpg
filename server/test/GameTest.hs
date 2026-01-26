{-# LANGUAGE OverloadedLabels #-}
{-# LANGUAGE OverloadedRecordDot #-}
{-# LANGUAGE OverloadedStrings #-}

module GameTest where

import Control.Lens
import Control.Monad.State (runState)
import Data.Generics.Labels ()
import Data.Map.Strict qualified as Map
import Data.Maybe (fromJust)
import Data.Text (Text)
import System.Random (mkStdGen)
import Test.Tasty (TestTree, testGroup)
import Test.Tasty.HUnit (assertBool, testCase, (@?=))

import Core.Card (CoreCard (..), Identified (..), Stats (..))
import Core.Logic.Deck (drawCard)
import Core.NonEmptyText (mkNonEmptyText)
import Core.Primitives
  ( ActorId (..)
  , CardInstanceId (..)
  , ChallengeId (..)
  )
import Core.RuleDefs (AttackDef (..), Rule (..))
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
import Data.List.NonEmpty (NonEmpty (..))

import Api.Request qualified as Req
import Server.Dispatch (processCommand)
import Server.Engine (runActorAction)
import Server.Game (GameState (..), addActor, emptyGame)
import Server.Types
  ( ActorGameEvent (..)
  , LogEntry (..)
  , LogId (..)
  , LogPayload (..)
  , LogSender (..)
  , StateUpdate (..)
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
            evt.actorId @?= actorId
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
            evt2.actorId @?= actorId
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

        -- Run concludeRound
        let ((game2, updatesResult, _, _), _) = runState (processCommand Req.EndRound game1) gen

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
    ]

-- Helpers

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
    , rules =
        Just $
          RuleAttack (AttackDef{power = StackPower color 0 Nothing, resistedBy = color, effect = Nothing})
            :| []
    , flavor = Nothing
    }

mockResCard :: Text -> CoreCard
mockResCard _name' =
  CoreCard
    { name = undefined
    , cost = Nothing
    , tags = Nothing
    , stats = Stats 5 5 5
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
    , spatial = SpatialState 0 0 1 Nothing
    , plannedMove = Nothing
    }
