{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE RecursiveDo #-}

module ChronometerBarTest (tests) where

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
  ( ClockDeckId (..)
  , ClockEffect (..)
  , ClockEventCard (..)
  , ClockEventId (..)
  , ClockNarrative (..)
  , ClockUrgency (..)
  , ExitStatus (..)
  , LocationId (..)
  , SetExitStatus (..)
  )
import Core.NonEmptyText (unsafeNonEmptyText)
import Core.RichText ()
import Core.State
  ( ClockDeckState (..)
  , ExplorationFocus (..)
  , LightSourceState (..)
  , WorldState (..)
  )
import Core.Time (Duration (..), ExpeditionTime (..), TimeUnit (..))
import Frontend.Game.ChronometerBar (clockEventRevealModal, renderBar)
import Frontend.Game.Class (SessionState (..), runGameT)

sampleClockCard :: ClockEventCard
sampleClockCard =
  ClockEventCard
    { id = ClockEventId "event_howling_wind"
    , name = unsafeNonEmptyText "Howling Mountain Gale"
    , cardType = "ClockEvent"
    , clockDeck = ClockDeckId "site"
    , urgency = Immediate
    , tags = Just (NE.fromList ["Weather", "Wind", "Hazard"])
    , narrative =
        ClockNarrative
          { summary = "A ferocious gust shrieks down the ravine, threatening exposed lanterns."
          , sensoryCue = Just "A piercing howl echoes through the crags before the sudden blast."
          }
    , effects =
        [ ClockEffect
            { target = "Ravine Crossing"
            , text = "Snuffs out unguarded flames."
            , duration = Just (Duration 10 Minute)
            , hazard = Nothing
            , setExitStatus = Just (SetExitStatus (LocationId "gallows_ledge") ExitBlocked)
            , unguarded = Nothing
            , challengeModifier = Nothing
            , extinguishesLight = True
            , spawnActors = Just ["Gargoyle Scout"]
            }
        ]
    }

sampleWorldState :: WorldState
sampleWorldState =
  WorldState
    { moduleId = Nothing
    , time = ExpeditionTime 525 -- Day 1, 08:45
    , focus = AtLocation (LocationId "mountain_pass")
    , locations = Map.empty
    , travelCards = Map.empty
    , locationStates = Map.empty
    , clockDecks =
        Map.fromList
          [
            ( ClockDeckId "site"
            , ClockDeckState
                { drawPile = [sampleClockCard]
                , discardPile = []
                , tickInterval = Duration 30 Minute
                , accumulatedMinutes = 15
                }
            )
          ,
            ( ClockDeckId "wilderness"
            , ClockDeckState
                { drawPile = []
                , discardPile = [sampleClockCard]
                , tickInterval = Duration 60 Minute
                , accumulatedMinutes = 45
                }
            )
          ]
    , lightState = LightSourceState (Just ("Bullseye Lantern", 45))
    , activeTeamworkChallenge = Nothing
    , locationEncounters = Map.empty
    , actorTemplates = Map.empty
    }

tests :: TestTree
tests =
  testGroup
    "Frontend.Game.ChronometerBar"
    [ testGroup
        "Clock Event Reveal Modal"
        [ testCase "renders modal backdrop and panel with data-testids" $ do
            (_, htmlBytes) <- renderStatic (clockEventRevealModal sampleClockCard)
            let html = decodeUtf8 htmlBytes
            assertBool "Has clock-modal-backdrop" ("data-testid=\"clock-modal-backdrop\"" `T.isInfixOf` html)
            assertBool "Has clock-modal-panel" ("data-testid=\"clock-modal-panel\"" `T.isInfixOf` html)
            assertBool "Has obsidian-panel class" ("obsidian-panel" `T.isInfixOf` html)
            assertBool "Has acknowledge button" ("data-testid=\"clock-modal-ack-btn\"" `T.isInfixOf` html)
            assertBool "Has close icon" ("data-testid=\"clock-modal-close-icon\"" `T.isInfixOf` html)
        , testCase "renders urgency, title, tags, and narrative correctly" $ do
            (_, htmlBytes) <- renderStatic (clockEventRevealModal sampleClockCard)
            let html = decodeUtf8 htmlBytes
            assertBool "Displays Urgency text" ("Immediate" `T.isInfixOf` html)
            assertBool "Displays Deck origin" ("[site CLOCK]" `T.isInfixOf` html)
            assertBool "Displays Card Title" ("Howling Mountain Gale" `T.isInfixOf` html)
            assertBool "Displays Tag" ("#Weather" `T.isInfixOf` html)
            assertBool "Displays Sensory Cue" ("piercing howl echoes" `T.isInfixOf` html)
            assertBool "Displays Summary" ("ferocious gust shrieks" `T.isInfixOf` html)
        , testCase "renders applied world effects breakdown" $ do
            (_, htmlBytes) <- renderStatic (clockEventRevealModal sampleClockCard)
            let html = decodeUtf8 htmlBytes
            assertBool "Displays Applied World Effects header" ("Applied World Effects" `T.isInfixOf` html)
            assertBool "Displays Target" ("Target: Ravine Crossing" `T.isInfixOf` html)
            assertBool "Displays Duration" ("Duration: 10 Minute" `T.isInfixOf` html)
            assertBool
              "Displays Extinguishes Light warning"
              ("Extinguishes active light source!" `T.isInfixOf` html)
            assertBool
              "Displays Spawn Actors warning"
              ("Spawns hostile actors: Gargoyle Scout" `T.isInfixOf` html)
            assertBool
              "Displays Exit Status change"
              ("Exit gallows_ledge status changed to ExitBlocked" `T.isInfixOf` html)
        ]
    , testGroup
        "Chronometer Bar Header & Pills"
        [ testCase "renders expedition time, light fuel, clock progress pills, and GM controls" $ do
            let sessionState =
                  SessionState
                    (constDyn Map.empty)
                    (constDyn [])
                    (constDyn undefined)
                    (constDyn undefined)
                    (constDyn Map.empty)
                    (constDyn (Just ("GameMaster", RoleGM)))
                    (constDyn False)
                    (constDyn ModeExploration)
                    (constDyn (Just sampleWorldState))

            (_, htmlBytes) <- renderStatic $ do
              rec (_, _) <-
                    runRequesterT
                      ( runGameT sessionState $
                          renderBar
                            (constDyn sampleWorldState)
                            (constDyn (Just ("GameMaster", RoleGM)))
                            (constDyn ModeExploration)
                            (constDyn True) -- GM controls drawer open
                      )
                      never
              pure ()

            let html = decodeUtf8 htmlBytes
            assertBool "Displays Day 1, 08:45" ("Day 1, 08:45" `T.isInfixOf` html)
            assertBool "Displays Active Light source" ("Bullseye Lantern" `T.isInfixOf` html)
            assertBool "Displays Light Fuel remaining" ("(45m)" `T.isInfixOf` html)
            assertBool "Displays Site clock pill" ("data-testid=\"clock-pill-site\"" `T.isInfixOf` html)
            assertBool "Displays Site clock progress fraction" ("15/30m" `T.isInfixOf` html)
            assertBool
              "Displays Wilderness clock pill"
              ("data-testid=\"clock-pill-wilderness\"" `T.isInfixOf` html)
            assertBool "Displays Wilderness clock progress fraction" ("45/60m" `T.isInfixOf` html)
            assertBool "Displays PlayMode badge" ("ModeExploration" `T.isInfixOf` html)
            assertBool "Displays GM Time button" ("data-testid=\"gm-time-controls-btn\"" `T.isInfixOf` html)
            assertBool "Displays GM Advance +1m button" ("data-testid=\"btn-advance-+1m\"" `T.isInfixOf` html)
            assertBool "Displays GM Advance +30m button" ("data-testid=\"btn-advance-+30m\"" `T.isInfixOf` html)
            assertBool "Displays GM Draw Site button" ("data-testid=\"btn-draw-clock-site\"" `T.isInfixOf` html)
        ]
    ]
