{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE RecursiveDo #-}

module ExplorationBoardTest (tests) where

import Data.List.NonEmpty (NonEmpty (..))
import Data.List.NonEmpty qualified as NE
import Data.Map.Strict qualified as Map
import Data.Text qualified as T
import Data.Text.Encoding (decodeUtf8)
import Reflex.Dom.Core hiding (button)
import Reflex.Host.Class ()
import Test.Tasty
import Test.Tasty.HUnit

import Api.Types (ClientRole (..), PlayMode (..))
import Core.Card.Exploration
  ( ActionScope (..)
  , ChallengeDef (..)
  , ClockDeckId (..)
  , ClockEffect (..)
  , ClockEventId (..)
  , ExitStatus (..)
  , ExplorationAction (..)
  , LocationCard (..)
  , LocationExit (..)
  , LocationId (..)
  , SetExitStatus (..)
  , TravelCard (..)
  , TravelExpedients (..)
  , TravelId (..)
  , TravelRoute (..)
  )
import Core.NonEmptyText (unsafeNonEmptyText)
import Core.Primitives (ActorId (..))
import Core.RichText (unsafeSimpleString)
import Core.State
  ( ActiveClockEffect (..)
  , ActorState (..)
  , CoreCardState (..)
  , Direction (..)
  , ExplorationFocus (..)
  , ExplorationIntent (..)
  , LightSourceState (..)
  , LocationRuntimeState (..)
  , PlannedAction (..)
  , SpatialState (..)
  , TableState (..)
  , WorldState (..)
  , emptyCoreCardState
  )
import Core.Stats (ResourceType (..))
import Core.Time (Duration (..), ExpeditionTime (..), TimeUnit (..))
import Data.UUID.Types qualified as UUID
import Frontend.Game.Class (SessionState (..), runGameT)
import Frontend.Game.ExplorationBoard (renderExplorationBoard)

sampleActorId :: ActorId
sampleActorId = ActorId (UUID.fromWords 1 2 3 4)

sampleActor :: ActorState
sampleActor =
  ActorState
    { name = "Valerius"
    , actorType = "PC"
    , coreState = emptyCoreCardState{planned = Just (PExploration (IntentAction 0))}
    , tableState = TableState Map.empty []
    , spatial = SpatialState 0 0 1 Nothing Nothing
    , plannedMove = Nothing
    , plannedRank = Nothing
    }

sampleLocationCard :: LocationCard
sampleLocationCard =
  LocationCard
    { id = LocationId "mountain_pass"
    , name = unsafeNonEmptyText "Crag Gallows - Mountain Pass"
    , cardType = "Location"
    , governingClock = Just (ClockDeckId "site")
    , baseTime = Duration 15 Minute
    , tags = Just (NE.fromList ["Chokepoint", "Dim", "Windblown"])
    , exits =
        Just
          [ LocationExit
              (LocationId "gallows_ledge")
              Nothing
              ExitOpen
              (Just (unsafeSimpleString "A crumbling stone stairway clings to the precipice."))
          ]
    , narrative =
        unsafeSimpleString
          "Frigid winds whistle through jagged limestone teeth. The path narrows to a sheer drop."
    , actions =
        Just
          [ ExplorationAction
              { name = unsafeNonEmptyText "Clear Rubble"
              , time = Duration 10 Minute
              , challenge = Just (ChallengeDef Red 3 (Just (NE.fromList ["Fatigue"])))
              , tags = Just (NE.fromList ["Labor", "LOUD"])
              , narrative = Just (unsafeSimpleString "Clear the rockfall blocking the crevasse.")
              , unblocks = Just (LocationId "gallows_ledge")
              , timePerImpact = Just (Duration 5 Minute)
              , interrupt = Just (ClockDeckId "site")
              , scope = ScopeTeamwork
              , enablesAction = Nothing
              , modifiesStrength = Nothing
              }
          ]
    }

sampleTravelCard :: TravelCard
sampleTravelCard =
  TravelCard
    { id = TravelId "ravine_traverse"
    , name = unsafeNonEmptyText "Ravine Traverse"
    , cardType = "Travel"
    , governingClock = Just (ClockDeckId "wilderness")
    , route =
        TravelRoute
          { from = LocationId "mountain_pass"
          , to = LocationId "haven_camp"
          , distanceLeagues = Just 2.5
          , baseTime = Duration 60 Minute
          , terrainTags = Just (NE.fromList ["Crags", "Alpine"])
          }
    , tags = Just (NE.fromList ["Exposed", "Dangerous"])
    , narrative = unsafeSimpleString "A treacherous traverse hugging the spine of the ravine."
    , paces =
        ExplorationAction
          { name = unsafeNonEmptyText "Measured Mountain March"
          , time = Duration 45 Minute
          , challenge = Just (ChallengeDef Yellow 2 (Just (NE.fromList ["Fatigue"])))
          , tags = Just (NE.fromList ["Travel"])
          , narrative = Just (unsafeSimpleString "Steady pace maintaining balance across ice-slick scree.")
          , unblocks = Nothing
          , timePerImpact = Nothing
          , interrupt = Nothing
          , scope = ScopeEveryone
          , enablesAction = Nothing
          , modifiesStrength = Nothing
          }
          :| []
    , expedients =
        Just
          ( TravelExpedients
              { campRestriction = Just "Loose scree prevents pitching tents."
              , actions = Nothing
              }
          )
    }

sampleWorldStateLoc :: WorldState
sampleWorldStateLoc =
  WorldState
    { moduleId = Nothing
    , time = ExpeditionTime 525 -- Day 1, 08:45
    , focus = AtLocation (LocationId "mountain_pass")
    , locations = Map.singleton (LocationId "mountain_pass") sampleLocationCard
    , travelCards = Map.empty
    , locationStates =
        Map.singleton
          (LocationId "mountain_pass")
          LocationRuntimeState
            { exitStatuses = Map.singleton (LocationId "gallows_ledge") ExitOpen
            , activeEffects =
                [ ActiveClockEffect
                    { effect =
                        ClockEffect
                          { target = "Ravine Crossing"
                          , text = unsafeSimpleString "Snuffs unguarded flames"
                          , duration = Just (Duration 10 Minute)
                          , hazard = Nothing
                          , setExitStatus = Just (SetExitStatus (LocationId "gallows_ledge") ExitBlocked)
                          , unguarded = Nothing
                          , challengeModifier = Nothing
                          , extinguishesLight = True
                          , spawnActors = Just ["Gargoyle Scout"]
                          }
                    , expiresAtMinute = Just 535
                    , sourceCard = Just (ClockEventId "event_gale")
                    }
                ]
            , enabledActions = []
            , modifiedStrengths = Map.empty
            , spawnedActors = []
            }
    , clockDecks = Map.empty
    , lightState = LightSourceState Nothing
    , activeTeamworkChallenge = Nothing
    , locationEncounters = Map.empty
    , actorTemplates = Map.empty
    }

sampleWorldStateTrv :: WorldState
sampleWorldStateTrv =
  WorldState
    { moduleId = Nothing
    , time = ExpeditionTime 525
    , focus = OnTravel (TravelId "ravine_traverse") Forward
    , locations = Map.empty
    , travelCards = Map.singleton (TravelId "ravine_traverse") sampleTravelCard
    , locationStates = Map.empty
    , clockDecks = Map.empty
    , lightState = LightSourceState Nothing
    , activeTeamworkChallenge = Nothing
    , locationEncounters = Map.empty
    , actorTemplates = Map.empty
    }

tests :: TestTree
tests =
  testGroup
    "Frontend.Game.ExplorationBoard"
    [ testCase "renders empty state when worldState is Nothing" $ do
        let sessionState =
              SessionState
                (constDyn Map.empty)
                (constDyn [])
                (constDyn undefined)
                (constDyn undefined)
                (constDyn Map.empty)
                (constDyn Nothing)
                (constDyn False)
                (constDyn ModeExploration)
                (constDyn Nothing)

        (_, htmlBytes) <- renderStatic $ do
          rec (_, _) <-
                runRequesterT
                  ( runGameT sessionState $
                      renderExplorationBoard
                        (constDyn Nothing)
                        (constDyn Map.empty)
                        (constDyn Nothing)
                        (constDyn Nothing)
                  )
                  never
          pure ()

        let html = decodeUtf8 htmlBytes
        assertBool "Has exploration-empty" ("data-testid=\"exploration-empty\"" `T.isInfixOf` html)
        assertBool "Shows no active module" ("No active exploration module loaded" `T.isInfixOf` html)
    , testCase "renders Location board with header, tags, clock effect, actions, and exits" $ do
        let actorsMap = Map.singleton sampleActorId sampleActor
            sessionState =
              SessionState
                (constDyn actorsMap)
                (constDyn [])
                (constDyn undefined)
                (constDyn undefined)
                (constDyn Map.empty)
                (constDyn (Just ("Valerius", RolePlayer sampleActorId)))
                (constDyn False)
                (constDyn ModeExploration)
                (constDyn (Just sampleWorldStateLoc))

        (_, htmlBytes) <- renderStatic $ do
          rec (_, _) <-
                runRequesterT
                  ( runGameT sessionState $
                      renderExplorationBoard
                        (constDyn (Just sampleWorldStateLoc))
                        (constDyn actorsMap)
                        (constDyn (Just ("Valerius", RolePlayer sampleActorId)))
                        (constDyn (Just sampleActorId))
                  )
                  never
          pure ()

        let html = decodeUtf8 htmlBytes
        assertBool "Has exploration-board" ("data-testid=\"exploration-board\"" `T.isInfixOf` html)
        assertBool "Displays Location Name" ("Crag Gallows - Mountain Pass" `T.isInfixOf` html)
        assertBool "Displays Tag Chokepoint" ("data-testid=\"tag-Chokepoint\"" `T.isInfixOf` html)
        assertBool "Displays Tag Dim" ("data-testid=\"tag-Dim\"" `T.isInfixOf` html)
        assertBool "Displays Active Clock Effect target" ("Ravine Crossing" `T.isInfixOf` html)
        assertBool "Displays Clock Effect countdown" ("(Expires in 10m)" `T.isInfixOf` html)
        assertBool "Displays Clock Effect light warning" ("Snuffs out unguarded flames!" `T.isInfixOf` html)
        assertBool "Displays Action Title" ("Clear Rubble" `T.isInfixOf` html)
        assertBool "Displays Scope Teamwork" ("Teamwork" `T.isInfixOf` html)
        assertBool "Displays Challenge Red 3" ("Red 3" `T.isInfixOf` html)
        assertBool "Displays Challenge consequence Fatigue" ("Fatigue" `T.isInfixOf` html)
        assertBool "Displays Action Time" ("⏱️ 10m" `T.isInfixOf` html)
        assertBool "Displays Caloric timePerImpact" ("+5m / flip" `T.isInfixOf` html)
        assertBool "Displays Loud Badge" ("[LOUD]" `T.isInfixOf` html)
        assertBool "Displays Planner Valerius" ("Valerius" `T.isInfixOf` html)
        assertBool "Displays Cancel Intent on planned action" ("Cancel Intent" `T.isInfixOf` html)
        assertBool "Displays Exit to gallows_ledge" ("gallows_ledge" `T.isInfixOf` html)
        assertBool "Displays Exit Status Open" ("🟢 Open" `T.isInfixOf` html)
        assertBool "Displays Pass Button" ("data-testid=\"exploration-pass-btn\"" `T.isInfixOf` html)
    , testCase "renders Travel board with route, heading, pace, and camp restriction" $ do
        let sessionState =
              SessionState
                (constDyn Map.empty)
                (constDyn [])
                (constDyn undefined)
                (constDyn undefined)
                (constDyn Map.empty)
                (constDyn Nothing)
                (constDyn False)
                (constDyn ModeExploration)
                (constDyn (Just sampleWorldStateTrv))

        (_, htmlBytes) <- renderStatic $ do
          rec (_, _) <-
                runRequesterT
                  ( runGameT sessionState $
                      renderExplorationBoard
                        (constDyn (Just sampleWorldStateTrv))
                        (constDyn Map.empty)
                        (constDyn Nothing)
                        (constDyn Nothing)
                  )
                  never
          pure ()

        let html = decodeUtf8 htmlBytes
        assertBool "Displays Travel Route Name" ("Ravine Traverse" `T.isInfixOf` html)
        assertBool "Displays Heading" ("mountain_pass ➔ haven_camp (Forward)" `T.isInfixOf` html)
        assertBool "Displays Distance" ("2.5 leagues" `T.isInfixOf` html)
        assertBool "Displays Pace Name" ("Measured Mountain March" `T.isInfixOf` html)
        assertBool "Displays Scope Everyone" ("Everyone" `T.isInfixOf` html)
        assertBool "Displays Camp Restriction" ("Loose scree prevents pitching tents." `T.isInfixOf` html)
    ]
