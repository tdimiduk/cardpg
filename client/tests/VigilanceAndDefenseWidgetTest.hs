{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE RecursiveDo #-}

module VigilanceAndDefenseWidgetTest (tests) where

import Data.List.NonEmpty qualified as NE
import Data.Map.Strict qualified as Map
import Data.Text qualified as T
import Data.Text.Encoding (decodeUtf8)
import Data.UUID.Types qualified as UUID
import Reflex.Dom.Core hiding (button)
import Test.Tasty
import Test.Tasty.HUnit

import Api.Types (ClientRole (..), PlayMode (..))
import Core.Card (CoreCard (..), DefenseProfile (..), Identified (..), ItemCard (..), emptyCoreCard)
import Core.Keyword (Keyword)
import Core.NonEmptyText (unsafeNonEmptyText)
import Core.Primitives (ActorId (..), CardInstanceId (..), ChallengeId (..), EquipSlot (..))
import Core.State
  ( ActiveChallenge (..)
  , ActorState (..)
  , AssetState (..)
  , ChallengeDomain (..)
  , ChallengeSource (..)
  , CoreCardState (..)
  , SpatialState (..)
  , TableCard (..)
  , TableState (..)
  , emptyCoreCardState
  )
import Core.Stats (ResourceType (..), Stats (..))
import Core.Time (Duration (..), TimeUnit (..))

import Frontend.Game.Class (SessionState (..), runGameT)
import Frontend.Game.Defense (DefenseTarget (..))
import Frontend.Game.DefenseWidget (defenseWidget)
import Frontend.Game.VigilanceTableau (renderVigilanceTableau)

sampleActorId :: ActorId
sampleActorId = ActorId (UUID.fromWords 1 1 1 1)

sampleCard1 :: Identified CardInstanceId CoreCard
sampleCard1 =
  Identified
    (CardInstanceId (UUID.fromWords 2 2 2 1))
    (emptyCoreCard (unsafeNonEmptyText "Mountain Trek") (Stats 1 1 0))

sampleCard2 :: Identified CardInstanceId CoreCard
sampleCard2 =
  Identified
    (CardInstanceId (UUID.fromWords 2 2 2 2))
    (emptyCoreCard (unsafeNonEmptyText "Iron Grip") (Stats 2 0 1))

sampleCrowbar :: TableCard
sampleCrowbar =
  TCItem
    ItemCard
      { name = unsafeNonEmptyText "Iron Crowbar"
      , tags = Just (NE.fromList ["Leverage" :: Keyword, "Tool"])
      , defenses = DefenseProfile (Just 2) (Just 1) Nothing
      , portions = Nothing
      , passive = Nothing
      , rules = Nothing
      , flavor = Nothing
      }

mkSampleActor
  :: Int
  -> [Identified CardInstanceId CoreCard]
  -> Maybe (Identified CardInstanceId CoreCard)
  -> ActorState
mkSampleActor dial pool readied =
  ActorState
    { name = "Garrick"
    , actorType = "PC"
    , coreState =
        emptyCoreCardState
          { vigilanceDial = dial
          , vigilancePool = pool
          , readiedCard = readied
          , deck = [sampleCard2]
          }
    , tableState =
        TableState
          { assets =
              Map.singleton
                (CardInstanceId (UUID.fromWords 9 9 9 1))
                (Identified (CardInstanceId (UUID.fromWords 9 9 9 1)) sampleCrowbar, Equipped SlotMainHand)
          , consequences = []
          }
    , spatial = SpatialState 0 0 1 Nothing Nothing
    , plannedMove = Nothing
    , plannedRank = Nothing
    }

mkMockSession :: (Reflex t) => PlayMode -> SessionState t
mkMockSession pm =
  SessionState
    (constDyn Map.empty)
    (constDyn [])
    (constDyn undefined)
    (constDyn undefined)
    (constDyn Map.empty)
    (constDyn (Just ("Garrick", RolePlayer sampleActorId)))
    (constDyn False)
    (constDyn pm)
    (constDyn Nothing)

tests :: TestTree
tests =
  testGroup
    "VigilanceTableau and Exploration DefenseWidget Tests"
    [ testGroup
        "Frontend.Game.VigilanceTableau"
        [ testCase "renders vigilance dial (0-4), face-down pool card backs, and empty readied slot" $ do
            let actor = mkSampleActor 3 [sampleCard1, sampleCard2] Nothing
                session = mkMockSession ModeExploration

            (_, htmlBytes) <- renderStatic $ do
              rec (_, _) <-
                    runRequesterT
                      ( runGameT session $
                          renderVigilanceTableau (constDyn (Identified sampleActorId actor))
                      )
                      never
              pure ()

            let html = decodeUtf8 htmlBytes
            assertBool "Has vigilance-tableau" ("data-testid=\"vigilance-tableau\"" `T.isInfixOf` html)
            assertBool "Has dial label" ("Vigilance Dial" `T.isInfixOf` html)
            assertBool "Has dial target indicator" ("3 card target" `T.isInfixOf` html)
            assertBool "Has vigilance pool card 1" ("data-testid=\"vigilance-card-1\"" `T.isInfixOf` html)
            assertBool "Has vigilance pool card 2" ("data-testid=\"vigilance-card-2\"" `T.isInfixOf` html)
            assertBool "Has empty readied slot" ("data-testid=\"ready-card-slot-empty\"" `T.isInfixOf` html)
        , testCase "renders face-up readied card and swap button when a card is readied" $ do
            let actor = mkSampleActor 2 [] (Just sampleCard1)
                session = mkMockSession ModeExploration

            (_, htmlBytes) <- renderStatic $ do
              rec (_, _) <-
                    runRequesterT
                      ( runGameT session $
                          renderVigilanceTableau (constDyn (Identified sampleActorId actor))
                      )
                      never
              pure ()

            let html = decodeUtf8 htmlBytes
            assertBool
              "Has readied card filled slot"
              ("data-testid=\"readied-card-slot-filled\"" `T.isInfixOf` html)
            assertBool "Renders readied card name" ("Mountain Trek" `T.isInfixOf` html)
            assertBool "Has swap button" ("Swap Card" `T.isInfixOf` html)
        ]
    , testGroup
        "Frontend.Game.DefenseWidget (Exploration Mode)"
        [ testCase
            "renders obstacle challenge with tag breakdown, time cost, and commit vigilance in exploration"
            $ do
              let actor = mkSampleActor 2 [sampleCard1] Nothing
                  session = mkMockSession ModeExploration
                  chal =
                    ActiveChallenge
                      { id = ChallengeId (UUID.fromWords 7 7 7 1)
                      , source = CSAdHoc "Heave Stone" (Just "Clear the collapsed entrance.")
                      , challengeStrength = 3
                      , challengeColor = Red
                      , challengeDomain = PhysicalLabor ["Leverage"]
                      , consequencePool = Just (NE.fromList ["Fatigue"])
                      , timePerImpact = Just (Duration 10 Minute)
                      }
                  target =
                    DefenseTarget
                      { challenge = chal
                      , attackStack = []
                      , attackerName = "Garrick"
                      }

              (_, htmlBytes) <- renderStatic $ do
                rec (_, _) <-
                      runRequesterT
                        ( runGameT session $
                            defenseWidget (constDyn target) (constDyn actor)
                        )
                        never
                pure ()

              let html = decodeUtf8 htmlBytes
              assertBool "Displays Obstacle Challenge header" ("Obstacle Challenge" `T.isInfixOf` html)
              assertBool "Displays required tag [Leverage]" ("[Leverage]" `T.isInfixOf` html)
              assertBool "Displays Tool/Gear defense breakdown" ("Tool/Gear: Iron Crowbar" `T.isInfixOf` html)
              assertBool "Displays Accumulated Time header" ("Accumulated Time" `T.isInfixOf` html)
              assertBool "Displays rate per flip" ("(10 min / flip)" `T.isInfixOf` html)
              assertBool "Has Commit Vigilance button" ("Commit Vigilance" `T.isInfixOf` html)
              assertBool "Has Abort Action button" ("Abort Action" `T.isInfixOf` html)
              assertBool "Has Clear / End Defense button" ("Clear / End Defense" `T.isInfixOf` html)
        , testCase "renders travel pace challenge with Travel Pace label and abort button" $ do
            let actor = mkSampleActor 0 [] Nothing
                session = mkMockSession ModeExploration
                chal =
                  ActiveChallenge
                    { id = ChallengeId (UUID.fromWords 7 7 7 2)
                    , source = CSAdHoc "Measured Mountain March" Nothing
                    , challengeStrength = 2
                    , challengeColor = Yellow
                    , challengeDomain = PhysicalLabor ["Travel"]
                    , consequencePool = Just (NE.fromList ["Fatigue"])
                    , timePerImpact = Nothing
                    }
                target =
                  DefenseTarget
                    { challenge = chal
                    , attackStack = []
                    , attackerName = "Garrick"
                    }

            (_, htmlBytes) <- renderStatic $ do
              rec (_, _) <-
                    runRequesterT
                      ( runGameT session $
                          defenseWidget (constDyn target) (constDyn actor)
                      )
                      never
              pure ()

            let html = decodeUtf8 htmlBytes
            assertBool "Displays Travel Pace label" ("Travel Pace" `T.isInfixOf` html)
            assertBool "Has Abort Action button" ("Abort Action" `T.isInfixOf` html)
        ]
    ]
