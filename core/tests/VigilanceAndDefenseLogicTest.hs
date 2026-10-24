{-# LANGUAGE LambdaCase #-}
{-# LANGUAGE OverloadedRecordDot #-}
{-# LANGUAGE OverloadedStrings #-}

module VigilanceAndDefenseLogicTest (test_vigilanceAndDefenseLogic) where

import Control.Monad.RWS (runRWST)
import Control.Monad.State (runState)
import Data.List.NonEmpty (NonEmpty (..))
import Data.Map.Strict qualified as Map
import Data.Text (Text)
import System.Random (RandomGen, mkStdGen)
import Test.Tasty
import Test.Tasty.HUnit

import Core.Card
  ( CardInstance
  , ConsequenceCard (..)
  , CoreCard (..)
  , DefenseProfile (..)
  , Identified (..)
  , ItemCard (..)
  , emptyCoreCard
  , emptyDefenseProfile
  , emptyItemCard
  )
import Core.Keyword (Keyword, unsafeKeyword)
import Core.Logic.Combat
  ( computeDefense
  , computeDefenseDetails
  , computeDefenseForChallenge
  )
import Core.Logic.Deck
  ( commitVigilancePool
  , flushVigilanceCycle
  , searchDeckForReadiedCard
  , setVigilanceDial
  , syncVigilanceToDial
  )
import Core.Logic.Exploration
  ( clearTeamworkChallenge
  , contributeToTeamworkChallenge
  , startTeamworkChallenge
  )
import Core.Logic.Monad (GameM, runGameM)
import Core.Logic.Status (addConsequenceForChallenge)
import Core.NonEmptyText (getRawText, unsafeNonEmptyText)
import Core.Primitives
  ( CardInstanceId (..)
  , ChallengeId (..)
  , EquipSlot (..)
  )
import Core.State
  ( ActiveChallenge (..)
  , ActiveDefense (..)
  , ActorState (..)
  , AssetState (..)
  , ChallengeDomain (..)
  , ChallengeSource (..)
  , CoreCardState (..)
  , DefenseDetails (..)
  , ExplorationFocus (..)
  , GameEnv (..)
  , GameEvent (..)
  , LightSourceState (..)
  , SpatialState (..)
  , TableCard (..)
  , TableState (..)
  , TeamworkProgress (..)
  , WorldState (..)
  , emptyCoreCardState
  )
import Core.Stats (ResourceType (..), Stats (..))
import Core.Time (Duration (..), ExpeditionTime (..), TimeUnit (..))
import Data.UUID.Types qualified as UUID

-- Helper constructors
mkCard :: Int -> Text -> Stats Int -> CardInstance CoreCard
mkCard n name stats =
  let cid = CardInstanceId (UUID.fromWords 0 0 0 (fromIntegral n))
      card = emptyCoreCard (unsafeNonEmptyText name) stats
   in Identified cid card

mkItemCard :: Text -> Int -> [Keyword] -> ItemCard
mkItemCard name def kws =
  let base = emptyItemCard (unsafeNonEmptyText name)
      prof = emptyDefenseProfile{defense = Just def}
   in base{defenses = prof, tags = Just (unsafeKeyword "Equipment" :| kws)}

mkConsCard :: Text -> Int -> [Keyword] -> ConsequenceCard
mkConsCard name sev kws =
  ConsequenceCard
    { name = unsafeNonEmptyText name
    , tags = case kws of
        [] -> Nothing
        (k : ks) -> Just (k :| ks)
    , passive = Nothing
    , effects = Nothing
    , severity = sev
    , notes = Nothing
    , rules = Nothing
    }

mkTestEnv :: GameEnv
mkTestEnv =
  GameEnv
    { fatigueCardTemplate = emptyCoreCard (unsafeNonEmptyText "Fatigue") (Stats 0 0 0)
    , statusCardTemplates = Map.empty
    , consequenceCardTemplates =
        Map.fromList
          [ ("Aching Quads", mkConsCard "Aching Quads" 1 [unsafeKeyword "Legs", unsafeKeyword "Exertion"])
          , ("Lumbar Strain", mkConsCard "Lumbar Strain" 1 [unsafeKeyword "Torso", unsafeKeyword "Exertion"])
          , ("Concussion", mkConsCard "Concussion" 2 [unsafeKeyword "Head"])
          ]
    }

mkBaseActor :: [CardInstance CoreCard] -> ActorState
mkBaseActor deckCards =
  ActorState
    { name = "Galand"
    , actorType = "PC"
    , coreState = emptyCoreCardState{deck = deckCards, vigilanceDial = 2}
    , tableState = TableState Map.empty []
    , spatial = SpatialState 0 0 1 Nothing Nothing
    , plannedMove = Nothing
    , plannedRank = Nothing
    }

runActor
  :: GameEnv -> ActorState -> (forall g. (RandomGen g) => GameM g a) -> (a, ActorState, [GameEvent])
runActor env actor action =
  let gen = mkStdGen 42
      ((res, finalActor, events), _) = runState (runRWST (runGameM action) env actor) gen
   in (res, finalActor, events)

test_vigilanceAndDefenseLogic :: TestTree
test_vigilanceAndDefenseLogic =
  testGroup
    "Vigilance, Tag-Aware Defense & Consequence Routing Tests"
    [ testGroup
        "Vigilance Tableau Operations"
        [ testCase "setVigilanceDial clamps between 0 and 4" $ do
            let actor0 = mkBaseActor []
            let (_, actorLow, _) = runActor mkTestEnv actor0 (setVigilanceDial (-2))
            assertEqual "Clamps negative dial to 0" 0 actorLow.coreState.vigilanceDial

            let (_, actorHigh, _) = runActor mkTestEnv actor0 (setVigilanceDial 9)
            assertEqual "Clamps excessive dial to 4" 4 actorHigh.coreState.vigilanceDial

            let (_, actorValid, _) = runActor mkTestEnv actor0 (setVigilanceDial 3)
            assertEqual "Sets valid dial to 3" 3 actorValid.coreState.vigilanceDial
        , testCase "syncVigilanceToDial fills pool from deck and trims on reduction" $ do
            let c1 = mkCard 1 "Strike" (Stats 2 0 0)
                c2 = mkCard 2 "Parry" (Stats 0 2 0)
                c3 = mkCard 3 "Dash" (Stats 0 0 2)
                actor0 =
                  (mkBaseActor [c1, c2, c3]){coreState = emptyCoreCardState{deck = [c1, c2, c3], vigilanceDial = 2}}

            -- Sync draws 2 cards into vigilancePool
            let (_, actorSynced, _) = runActor mkTestEnv actor0 syncVigilanceToDial
            assertEqual "Pool filled to dial" 2 (length actorSynced.coreState.vigilancePool)
            assertEqual "Remaining deck size is 1" 1 (length actorSynced.coreState.deck)

            -- Lower dial to 1 and sync: trims excess card to discard
            let actorDial1 = actorSynced{coreState = actorSynced.coreState{vigilanceDial = 1}}
            let (_, actorTrimmed, _) = runActor mkTestEnv actorDial1 syncVigilanceToDial
            assertEqual "Pool trimmed to 1" 1 (length actorTrimmed.coreState.vigilancePool)
            assertEqual "Discard has trimmed card" 1 (length actorTrimmed.coreState.discard)
        , testCase "searchDeckForReadiedCard moves card to readiedCard slot and replaces prior" $ do
            let c1 = mkCard 1 "Careful Step" (Stats 1 1 0)
                c2 = mkCard 2 "Quick Reflexes" (Stats 0 2 0)
                actor0 = mkBaseActor [c1, c2]

            -- Search for c1
            let (res1, actor1, _) = runActor mkTestEnv actor0 (searchDeckForReadiedCard c1.id)
            assertEqual "Search successful" (Right c1) res1
            assertEqual "Readied card set to c1" (Just c1.id) (fmap (.id) actor1.coreState.readiedCard)
            assertEqual "Deck reduced to 1" 1 (length actor1.coreState.deck)

            -- Search for c2: prior readied card c1 moves to discard
            let (res2, actor2, _) = runActor mkTestEnv actor1 (searchDeckForReadiedCard c2.id)
            assertEqual "Search for second card successful" (Right c2) res2
            assertEqual "Readied card replaced by c2" (Just c2.id) (fmap (.id) actor2.coreState.readiedCard)
            assertEqual "Prior readied card moved to discard" [c1.id] (map (.id) actor2.coreState.discard)
        , testCase "commitVigilancePool moves pool and readied card into hand" $ do
            let c1 = mkCard 1 "A" (Stats 1 0 0)
                c2 = mkCard 2 "B" (Stats 0 1 0)
                cReady = mkCard 3 "Ready" (Stats 1 1 1)
                actor0 =
                  (mkBaseActor [])
                    { coreState =
                        emptyCoreCardState
                          { vigilancePool = [c1, c2]
                          , readiedCard = Just cReady
                          , hand = []
                          }
                    }

            let (_, actorCommitted, _) = runActor mkTestEnv actor0 commitVigilancePool
            assertEqual "Hand has pool and readied card" 3 (length actorCommitted.coreState.hand)
            assertEqual "Vigilance pool is cleared" 0 (length actorCommitted.coreState.vigilancePool)
            assertEqual "Readied card is cleared" Nothing actorCommitted.coreState.readiedCard
            assertEqual "committedVigilance flag set" True actorCommitted.coreState.committedVigilance
        , testCase "flushVigilanceCycle discards hand and pays 2 deck cards to retain readied card" $ do
            let c1 = mkCard 1 "A" (Stats 1 0 0)
                c2 = mkCard 2 "B" (Stats 0 1 0)
                cPay1 = mkCard 3 "Deck1" (Stats 1 0 0)
                cPay2 = mkCard 4 "Deck2" (Stats 0 1 0)
                cRefill1 = mkCard 5 "Deck3" (Stats 1 0 0)
                cRefill2 = mkCard 6 "Deck4" (Stats 0 1 0)
                cReady = mkCard 7 "Ready" (Stats 1 1 1)
                deckCards = [cPay1, cPay2, cRefill1, cRefill2]
                actor0 =
                  (mkBaseActor deckCards)
                    { coreState =
                        emptyCoreCardState
                          { deck = deckCards
                          , hand = [c1, c2]
                          , readiedCard = Just cReady
                          , committedVigilance = True
                          , vigilanceDial = 2
                          }
                    }

            -- Flush retaining readied card (pays 2 deck cards)
            let (_, actorFlushed, _) = runActor mkTestEnv actor0 (flushVigilanceCycle True)
            assertEqual "Hand discarded" 0 (length actorFlushed.coreState.hand)
            assertEqual "committedVigilance reset" False actorFlushed.coreState.committedVigilance
            assertEqual "Readied card retained" (Just cReady.id) (fmap (.id) actorFlushed.coreState.readiedCard)
            assertEqual "Pool refilled up to dial 2" 2 (length actorFlushed.coreState.vigilancePool)
            -- Discard contains: hand (2 cards) + payment to retain readied (2 cards) = 4 cards
            assertEqual
              "Discard contains flushed hand and 2-card payment"
              4
              (length actorFlushed.coreState.discard)
        ]
    , testGroup
        "Tag-Aware Defense Computation"
        [ testCase "Combat trauma uses armor defense, physical labor uses matching tag defense" $ do
            let crowbarItem = mkItemCard "Heavy Crowbar" 3 [unsafeKeyword "Leverage", unsafeKeyword "Tool"]
                shieldItem = mkItemCard "Tower Shield" 4 [unsafeKeyword "Armor", unsafeKeyword "Shield"]
                itemId1 = CardInstanceId (UUID.fromWords 0 0 1 1)
                itemId2 = CardInstanceId (UUID.fromWords 0 0 1 2)
                tblState =
                  TableState
                    { assets =
                        Map.fromList
                          [ (itemId1, (Identified itemId1 (TCItem crowbarItem), Equipped SlotMainHand))
                          , (itemId2, (Identified itemId2 (TCItem shieldItem), Equipped SlotOffHand))
                          ]
                    , consequences = []
                    }

            -- Baseline combat defense: maximum of all equipped defenses (Tower Shield = 4)
            assertEqual "Combat defense uses maximum armor/shield defense" 4 (computeDefense tblState)

            -- Physical Labor check requiring [Leverage]: matches Crowbar (3)
            let laborChallenge =
                  ActiveChallenge
                    { id = ChallengeId (UUID.fromWords 0 0 2 1)
                    , source = CSAdHoc "Obstacle" Nothing
                    , challengeStrength = 4
                    , challengeColor = Red
                    , challengeDomain = PhysicalLabor ["Leverage"]
                    , consequencePool = Nothing
                    , timePerImpact = Nothing
                    }
            assertEqual
              "Physical Labor with [Leverage] uses Crowbar defense 3"
              3
              (computeDefenseForChallenge (Just laborChallenge) tblState)

            -- Physical Labor check requiring [Timber]: no matching items, falls back to innate 1
            let timberChallenge =
                  laborChallenge{challengeDomain = PhysicalLabor ["Timber"]}
            assertEqual
              "Physical Labor with no matching tools falls back to baseline 1"
              1
              (computeDefenseForChallenge (Just timberChallenge) tblState)

            -- Environmental Hazard check with bracket-wrapped tag "[Tool]": matches Crowbar defense 3
            let envChallenge =
                  laborChallenge{challengeDomain = EnvironmentalHazard ["[Tool]"]}
            assertEqual
              "Environmental Hazard with '[Tool]' matches Crowbar defense 3"
              3
              (computeDefenseForChallenge (Just envChallenge) tblState)
        , testCase "computeDefenseDetails reflects tag-aware defense for active defense" $ do
            let crowbarItem = mkItemCard "Leverage Bar" 2 [unsafeKeyword "Leverage"]
                itemId = CardInstanceId (UUID.fromWords 0 0 1 1)
                tblState =
                  TableState
                    { assets = Map.singleton itemId (Identified itemId (TCItem crowbarItem), Equipped SlotMainHand)
                    , consequences = []
                    }
                laborChallenge =
                  ActiveChallenge
                    { id = ChallengeId (UUID.fromWords 0 0 2 1)
                    , source = CSAdHoc "Portcullis" Nothing
                    , challengeStrength = 3
                    , challengeColor = Red
                    , challengeDomain = PhysicalLabor ["Leverage"]
                    , consequencePool = Nothing
                    , timePerImpact = Nothing
                    }
                cFlip = mkCard 1 "Straining Lift" (Stats 2 0 0)
                actor =
                  ActorState
                    { name = "Worker"
                    , actorType = "PC"
                    , coreState =
                        emptyCoreCardState
                          { defending = Just (ActiveDefense laborChallenge [cFlip, cFlip])
                          }
                    , tableState = tblState
                    , spatial = SpatialState 0 0 1 Nothing Nothing
                    , plannedMove = Nothing
                    , plannedRank = Nothing
                    }

            let details = computeDefenseDetails actor
            -- Defense = 2 (Crowbar). 2 cards flipped -> impact = 2 -> consequencesFromDefense = 2 `div` 2 = 1
            assertEqual
              "Tag-aware defense correctly calculates consequences from defense"
              1
              details.consequencesFromDefense
            assertEqual "Impact is equal to flipped card count" 2 details.impact
        ]
    , testGroup
        "Consequence Pool Routing"
        [ testCase "Fatigue consequence pool routes Fatigue card to actor discard" $ do
            let actor0 = mkBaseActor []
            let fatigueChallenge =
                  ActiveChallenge
                    { id = ChallengeId (UUID.fromWords 0 0 3 1)
                    , source = CSAdHoc "Forced March" Nothing
                    , challengeStrength = 3
                    , challengeColor = Red
                    , challengeDomain = PhysicalLabor ["Travel"]
                    , consequencePool = Just ("Fatigue" :| [])
                    , timePerImpact = Nothing
                    }

            let (_, actorAfter, events) = runActor mkTestEnv actor0 (addConsequenceForChallenge (Just fatigueChallenge) Nothing)
            assertEqual "Discard pile receives Fatigue card" 1 (length actorAfter.coreState.discard)
            assertEqual "Table consequences remains empty" 0 (length actorAfter.tableState.consequences)
            assertBool
              "StatusAdded Fatigue event emitted"
              (any (\case StatusAdded "Fatigue" _ -> True; _ -> False) events)
        , testCase "Named consequence pool filters matching injuries by tag" $ do
            let actor0 = mkBaseActor []
            let legStrainChallenge =
                  ActiveChallenge
                    { id = ChallengeId (UUID.fromWords 0 0 3 2)
                    , source = CSAdHoc "Loose Slate Descent" Nothing
                    , challengeStrength = 4
                    , challengeColor = Yellow
                    , challengeDomain = EnvironmentalHazard ["Descent"]
                    , consequencePool = Just ("Legs" :| [])
                    , timePerImpact = Nothing
                    }

            let (_, actorAfter, events) = runActor mkTestEnv actor0 (addConsequenceForChallenge (Just legStrainChallenge) (Just 1))
            case actorAfter.tableState.consequences of
              [Identified _ consCard] -> do
                assertEqual
                  "Selected consequence is Aching Quads (Legs tag)"
                  ("Aching Quads" :: Text)
                  (getRawText consCard.name)
                assertBool
                  "ConsequenceAdded event emitted"
                  (any (\case ConsequenceAdded _ -> True; _ -> False) events)
              _ -> assertFailure "Expected exactly 1 consequence on table"
        ]
    , testGroup
        "Shared Teamwork Challenge Progress"
        [ testCase "Teamwork challenge accumulates strength and impact time across actors" $ do
            let teamworkChallenge =
                  ActiveChallenge
                    { id = ChallengeId (UUID.fromWords 0 0 4 1)
                    , source = CSAdHoc "Sledgehammer Breach" Nothing
                    , challengeStrength = 6
                    , challengeColor = Red
                    , challengeDomain = PhysicalLabor ["Timber", "Breach"]
                    , consequencePool = Just ("Fatigue" :| [])
                    , timePerImpact = Just (Duration 5 Minute)
                    }
                initWs =
                  WorldState
                    { moduleId = Nothing
                    , time = ExpeditionTime 0
                    , focus = AtLocation "loc_test"
                    , locations = Map.empty
                    , travelCards = Map.empty
                    , locationStates = Map.empty
                    , clockDecks = Map.empty
                    , lightState = LightSourceState Nothing
                    , activeTeamworkChallenge = Nothing
                    , locationEncounters = Map.empty
                    , actorTemplates = Map.empty
                    }

            -- 1. Start teamwork challenge
            let ws1 = startTeamworkChallenge teamworkChallenge initWs
            assertBool
              "Teamwork challenge initialized"
              (case ws1.activeTeamworkChallenge of Just _ -> True; Nothing -> False)

            -- 2. Actor A flips 1 card with 2 Red strength
            let cardA = mkCard 1 "Heavy Swing" (Stats 2 0 0)
            let (ws2, complete1, dur1) = contributeToTeamworkChallenge "Galand" [cardA] ws1
            assertEqual "First contribution does not complete challenge" False complete1
            assertEqual "Impact time added is 5 min" (Duration 5 Minute) dur1
            case ws2.activeTeamworkChallenge of
              Nothing -> assertFailure "Expected active teamwork challenge after contribution"
              Just tp1 -> do
                assertEqual "Contributed strength is 2" 2 tp1.totalStrengthContributed
                assertEqual "Cards flipped is 1" 1 tp1.totalCardsFlipped
                assertEqual "Actors include Galand" ["Galand"] tp1.participatingActors

            -- 3. Actor B flips 2 cards with total 4 Red strength (reaches target 6)
            let cardB1 = mkCard 2 "Crowbar Leverage" (Stats 2 0 0)
                cardB2 = mkCard 3 "Brute Force" (Stats 2 0 0)
            let (ws3, complete2, dur2) = contributeToTeamworkChallenge "Vesper" [cardB1, cardB2] ws2
            assertEqual "Second contribution completes challenge" True complete2
            assertEqual "Impact time added is 10 min (2 cards * 5 min)" (Duration 10 Minute) dur2
            case ws3.activeTeamworkChallenge of
              Nothing -> assertFailure "Expected active teamwork challenge after second contribution"
              Just tp2 -> do
                assertEqual "Contributed strength reaches 6" 6 tp2.totalStrengthContributed
                assertEqual "Total cards flipped is 3" 3 tp2.totalCardsFlipped
                assertEqual "Total accumulated impact time is 15 min" (Duration 15 Minute) tp2.totalImpactTimeAdded
                assertEqual "Both actors participated" ["Galand", "Vesper"] tp2.participatingActors

            -- 4. Clear challenge
            let wsFinal = clearTeamworkChallenge ws3
            assertEqual "Teamwork challenge cleared" Nothing wsFinal.activeTeamworkChallenge
        ]
    ]
