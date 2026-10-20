{-# LANGUAGE DuplicateRecordFields #-}
{-# LANGUAGE OverloadedRecordDot #-}
{-# LANGUAGE OverloadedStrings #-}

module Core.Logic.Exploration
  ( -- * Initialization
    initLocationRuntimeState
  , initClockDeckState
  , initWorldState

    -- * Queries
  , getActiveGoverningClock
  , isLocationUnguarded
  , getLocationChallengeModifier
  , isActionEnabled
  , getActionStrengthModifier
  , resolveEffectTarget

    -- * State Transitions
  , advanceTimeAndTriggerClocks
  , advanceTimeWithInterrupt
  , drawClockCard
  , applyClockEffect
  , applyClockEventEffects
  , setExitStatus
  , unblockExit
  , unlockFollowUpAction
  , setLightSource
  , extinguishLight
  , transitionViaExit
  , completeTravel
  , startTeamworkChallenge
  , contributeToTeamworkChallenge
  , clearTeamworkChallenge
  ) where

import Control.Monad.State (State)
import Data.List (partition)
import Data.Map.Strict (Map)
import Data.Map.Strict qualified as Map
import Data.Maybe (fromMaybe)
import Data.Text (Text)
import System.Random (StdGen)

import Core.Card (CardInstance, CoreCard (..), Identified (..))
import Core.Card.Exploration
  ( ChallengeModifier (..)
  , ClockConfig (..)
  , ClockDeckId (..)
  , ClockEffect (..)
  , ClockEventCard (..)
  , ClockEventId (..)
  , ExitStatus (..)
  , LocationCard (..)
  , LocationExit (..)
  , LocationId (..)
  , ModuleManifest (..)
  , ScenarioActor (..)
  , SetExitStatus (..)
  , TravelCard (..)
  , TravelRoute (..)
  )
import Core.State
  ( ActiveChallenge (..)
  , ActiveClockEffect (..)
  , ClockDeckState (..)
  , Direction (..)
  , ExplorationEvent (..)
  , ExplorationFocus (..)
  , LightSourceState (..)
  , LocationRuntimeState (..)
  , TeamworkProgress (..)
  , WorldState (..)
  )
import Core.Stats (ResourceType, getStat)
import Core.Time
  ( Duration (..)
  , ExpeditionTime (..)
  , TimeUnit (..)
  , clockTicksCrossed
  , toMinutes
  )
import Core.Util (shuffleListM)

--------------------------------------------------------------------------------
-- Initialization
--------------------------------------------------------------------------------

-- | Construct initial runtime state for a location from its static definition.
initLocationRuntimeState :: LocationCard -> LocationRuntimeState
initLocationRuntimeState loc =
  LocationRuntimeState
    { exitStatuses = maybe Map.empty (\es -> Map.fromList [(e.to, e.status) | e <- es]) loc.exits
    , activeEffects = []
    , enabledActions = []
    , modifiedStrengths = Map.empty
    , spawnedActors = []
    }

-- | Construct initial clock deck runtime state from configuration and cards.
initClockDeckState :: ClockConfig -> [ClockEventCard] -> ClockDeckState
initClockDeckState cfg cards =
  ClockDeckState
    { drawPile = cards
    , discardPile = []
    , tickInterval = cfg.tickInterval
    , accumulatedMinutes = 0
    }

-- | Initialize the full WorldState from a module manifest and loaded card collections.
initWorldState
  :: ModuleManifest
  -> [LocationCard]
  -> [TravelCard]
  -> [ClockEventCard]
  -> WorldState
initWorldState manifest locCards travelCardsList clockCards =
  let locMap = Map.fromList [(loc.id, loc) | loc <- locCards]
      trvMap = Map.fromList [(trv.id, trv) | trv <- travelCardsList]
      locStates =
        Map.fromList
          [ ( loc.id
            , (initLocationRuntimeState loc)
                { spawnedActors =
                    maybe [] (map (\(a :: ScenarioActor) -> a.name)) (Map.lookup loc.id manifest.locationEncounters)
                }
            )
          | loc <- locCards
          ]
      clockDeckStates =
        Map.fromList
          [ ( deckId
            , initClockDeckState cfg [c | c <- clockCards, c.clockDeck == deckId]
            )
          | (deckId, cfg) <- Map.toList manifest.clockConfigs
          ]
   in WorldState
        { moduleId = Just manifest.id
        , time = manifest.startingTime
        , focus = AtLocation manifest.startingLocation
        , locations = locMap
        , travelCards = trvMap
        , locationStates = locStates
        , clockDecks = clockDeckStates
        , lightState = LightSourceState Nothing
        , activeTeamworkChallenge = Nothing
        }

--------------------------------------------------------------------------------
-- Queries
--------------------------------------------------------------------------------

-- | Look up the clock deck ID governing the party's current focus card.
getActiveGoverningClock :: WorldState -> Maybe ClockDeckId
getActiveGoverningClock ws = case ws.focus of
  AtLocation locId -> do
    loc <- Map.lookup locId ws.locations
    loc.governingClock
  OnTravel trvId _ -> do
    trv <- Map.lookup trvId ws.travelCards
    trv.governingClock

-- | Check if a location currently has an active "unguarded" clock effect.
isLocationUnguarded :: LocationId -> WorldState -> Bool
isLocationUnguarded locId ws =
  case Map.lookup locId ws.locationStates of
    Nothing -> False
    Just locSt -> any (\eff -> eff.effect.unguarded == Just True) locSt.activeEffects

-- | Calculate total active challenge strength modifiers on a location.
getLocationChallengeModifier :: LocationId -> Maybe ResourceType -> WorldState -> Int
getLocationChallengeModifier locId mColor ws =
  case Map.lookup locId ws.locationStates of
    Nothing -> 0
    Just locSt ->
      sum
        [ cm.strength
        | eff <- locSt.activeEffects
        , Just cm <- [eff.effect.challengeModifier]
        , case (cm.color, mColor) of
            (Nothing, _) -> True
            (Just c1, Just c2) -> c1 == c2
            (Just _, Nothing) -> False
        ]

-- | Check if a named follow-up action is unlocked at a location.
isActionEnabled :: LocationId -> Text -> WorldState -> Bool
isActionEnabled locId actionName ws =
  case Map.lookup locId ws.locationStates of
    Nothing -> False
    Just locSt -> actionName `elem` locSt.enabledActions

-- | Get any modifier to action strength unlocked by previous actions at a location.
getActionStrengthModifier :: LocationId -> Text -> WorldState -> Int
getActionStrengthModifier locId actionName ws =
  case Map.lookup locId ws.locationStates of
    Nothing -> 0
    Just locSt -> Map.findWithDefault 0 actionName locSt.modifiedStrengths

-- | Resolve target specifier (e.g. "current_zone" or specific LocationId) to a LocationId.
resolveEffectTarget :: Text -> WorldState -> Maybe LocationId
resolveEffectTarget targetText ws
  | targetText == "current_zone" || targetText == "current" =
      case ws.focus of
        AtLocation locId -> Just locId
        OnTravel trvId dir ->
          case Map.lookup trvId ws.travelCards of
            Just trv ->
              Just $ case dir of
                Forward -> trv.route.to
                Reverse -> trv.route.from
            Nothing -> Nothing
  | otherwise = Just (LocationId targetText)

--------------------------------------------------------------------------------
-- State Mutations & Transitions
--------------------------------------------------------------------------------

-- | Set or replenish the party's active light source.
setLightSource :: Text -> Int -> WorldState -> (WorldState, [ExplorationEvent])
setLightSource name mins ws =
  let ws' = ws{lightState = LightSourceState (Just (name, mins))}
   in (ws', [LightFuelDecreased (Just (name, mins))])

-- | Manually extinguish the active light source.
extinguishLight :: WorldState -> (WorldState, [ExplorationEvent])
extinguishLight ws =
  case ws.lightState.activeLight of
    Nothing -> (ws, [])
    Just (name, _) ->
      let ws' = ws{lightState = LightSourceState Nothing}
       in (ws', [LightFuelDecreased Nothing, LightExtinguished name])

-- | Consume minutes of light fuel, generating decrement and extinction events.
consumeLightFuel :: Int -> LightSourceState -> (LightSourceState, [ExplorationEvent])
consumeLightFuel deltaMins (LightSourceState mLight) = case mLight of
  Nothing -> (LightSourceState Nothing, [])
  Just (name, fuel) ->
    let remFuel = fuel - deltaMins
     in if remFuel <= 0
          then (LightSourceState Nothing, [LightFuelDecreased Nothing, LightExtinguished name])
          else (LightSourceState (Just (name, remFuel)), [LightFuelDecreased (Just (name, remFuel))])

-- | Update exit status from one location to another.
setExitStatus
  :: LocationId
  -> LocationId
  -> ExitStatus
  -> WorldState
  -> (WorldState, [ExplorationEvent])
setExitStatus fromLoc toLoc status ws =
  case Map.lookup fromLoc ws.locationStates of
    Nothing -> (ws, [])
    Just locSt ->
      let locSt' = locSt{exitStatuses = Map.insert toLoc status locSt.exitStatuses}
          ws' = ws{locationStates = Map.insert fromLoc locSt' ws.locationStates}
       in (ws', [ExitStatusChanged fromLoc toLoc status])

-- | Unblock an exit from one location to another.
unblockExit :: LocationId -> LocationId -> WorldState -> (WorldState, [ExplorationEvent])
unblockExit fromLoc toLoc = setExitStatus fromLoc toLoc ExitOpen

-- | Record an enabled follow-up action and optional difficulty modifier on a location.
unlockFollowUpAction
  :: LocationId
  -> Text
  -> Maybe Int
  -> WorldState
  -> WorldState
unlockFollowUpAction locId actionName mModStrength ws =
  case Map.lookup locId ws.locationStates of
    Nothing -> ws
    Just locSt ->
      let enabled' =
            if actionName `elem` locSt.enabledActions
              then locSt.enabledActions
              else locSt.enabledActions ++ [actionName]
          modStrengths' = case mModStrength of
            Just delta -> Map.insert actionName delta locSt.modifiedStrengths
            Nothing -> locSt.modifiedStrengths
          locSt' = locSt{enabledActions = enabled', modifiedStrengths = modStrengths'}
       in ws{locationStates = Map.insert locId locSt' ws.locationStates}

-- | Remove expired timed effects across all location states.
expireTimedEffects
  :: Int
  -> Map LocationId LocationRuntimeState
  -> (Map LocationId LocationRuntimeState, [ExplorationEvent])
expireTimedEffects currentMins =
  Map.foldrWithKey
    ( \locId locSt (accStates, accEvs) ->
        let (retained, expired) =
              partition
                ( \eff ->
                    case eff.expiresAtMinute of
                      Just expM -> expM > currentMins
                      Nothing -> True
                )
                locSt.activeEffects
            expiredEvs = [ClockEffectExpired locId eff | eff <- expired]
            locSt' = locSt{activeEffects = retained}
         in (Map.insert locId locSt' accStates, accEvs ++ expiredEvs)
    )
    (Map.empty, [])

-- | Apply a single ClockEffect to the appropriate target location and world state.
applyClockEffectSingle
  :: ClockEffect
  -> Maybe ClockEventId
  -> WorldState
  -> (WorldState, [ExplorationEvent])
applyClockEffectSingle eff mCardId ws =
  let mTargetLocId = resolveEffectTarget eff.target ws
      currentMins = ws.time.totalMinutes
      mExpire = fmap (\dur -> currentMins + toMinutes dur) eff.duration

      -- 1. Extinguish light if requested
      (wsWithLight, lightEvs) =
        if eff.extinguishesLight
          then case ws.lightState.activeLight of
            Just (nm, _) ->
              ( ws{lightState = LightSourceState Nothing}
              , [LightFuelDecreased Nothing, LightExtinguished nm]
              )
            Nothing -> (ws, [])
          else (ws, [])

      -- 2. Apply to target location
      (wsFinal, locEvs) = case mTargetLocId of
        Nothing -> (wsWithLight, [])
        Just locId ->
          let curLocSt =
                fromMaybe
                  LocationRuntimeState
                    { exitStatuses = Map.empty
                    , activeEffects = []
                    , enabledActions = []
                    , modifiedStrengths = Map.empty
                    , spawnedActors = []
                    }
                  (Map.lookup locId wsWithLight.locationStates)

              -- Set exit status mutation
              (curLocSt1, exitEvs) = case eff.setExitStatus of
                Just (SetExitStatus exitId newStatus) ->
                  ( curLocSt{exitStatuses = Map.insert exitId newStatus curLocSt.exitStatuses}
                  , [ExitStatusChanged locId exitId newStatus]
                  )
                Nothing -> (curLocSt, [])

              -- Spawn actors mutation
              (curLocSt2, spawnEvs) = case eff.spawnActors of
                Just actors ->
                  ( curLocSt1{spawnedActors = curLocSt1.spawnedActors ++ actors}
                  , [ActorsSpawned locId actors]
                  )
                Nothing -> (curLocSt1, [])

              -- Record active effect
              activeEff =
                ActiveClockEffect
                  { effect = eff
                  , expiresAtMinute = mExpire
                  , sourceCard = mCardId
                  }
              curLocSt3 = curLocSt2{activeEffects = curLocSt2.activeEffects ++ [activeEff]}

              appliedEv = [ClockEffectApplied locId eff]

              hazardEv = case eff.hazard of
                Just hDef -> [ClockHazardTriggered locId hDef]
                Nothing -> []

              updatedLocStates = Map.insert locId curLocSt3 wsWithLight.locationStates
           in ( wsWithLight{locationStates = updatedLocStates}
              , exitEvs ++ spawnEvs ++ appliedEv ++ hazardEv
              )
   in (wsFinal, lightEvs ++ locEvs)

-- | Explicitly apply a clock effect targeted to a location.
applyClockEffect
  :: LocationId
  -> ClockEffect
  -> Maybe ClockEventId
  -> WorldState
  -> (WorldState, [ExplorationEvent])
applyClockEffect locId eff = applyClockEffectSingle (eff{target = locId.unLocationId})

-- | Apply all structured effects from a drawn clock card.
applyClockEventEffects :: ClockEventCard -> WorldState -> (WorldState, [ExplorationEvent])
applyClockEventEffects card ws =
  foldl'
    ( \(curWs, curEvs) eff ->
        let (nextWs, newEvs) = applyClockEffectSingle eff (Just card.id) curWs
         in (nextWs, curEvs ++ newEvs)
    )
    (ws, [])
    card.effects

-- | Draw a clock card from a clock deck, reshuffling discard pile if draw pile is empty.
drawClockCard
  :: ClockDeckId
  -> WorldState
  -> State StdGen (WorldState, Maybe ClockEventCard, [ExplorationEvent])
drawClockCard cid ws = case Map.lookup cid ws.clockDecks of
  Nothing -> pure (ws, Nothing, [])
  Just deckSt -> case deckSt.drawPile of
    (c : cs) -> do
      let deckSt' =
            deckSt
              { drawPile = cs
              , discardPile = c : deckSt.discardPile
              }
          ws' = ws{clockDecks = Map.insert cid deckSt' ws.clockDecks}
      pure (ws', Just c, [ClockCardDrawn cid c])
    [] -> case deckSt.discardPile of
      [] -> pure (ws, Nothing, [])
      discards -> do
        shuffled <- shuffleListM discards
        case shuffled of
          [] -> pure (ws, Nothing, [])
          (c : cs) -> do
            let deckSt' =
                  deckSt
                    { drawPile = cs
                    , discardPile = [c]
                    }
                ws' = ws{clockDecks = Map.insert cid deckSt' ws.clockDecks}
            pure (ws', Just c, [ClockDeckShuffled cid, ClockCardDrawn cid c])

-- | Traverse an exit, either transitioning directly room-to-room or moving onto a TravelCard edge.
transitionViaExit
  :: LocationExit
  -> WorldState
  -> Either Text (WorldState, [ExplorationEvent], Duration)
transitionViaExit exit ws = case ws.focus of
  OnTravel _ _ -> Left "Cannot traverse exit while already traveling"
  AtLocation fromLocId ->
    case Map.lookup fromLocId ws.locationStates of
      Nothing -> Left "Current location not found in world state"
      Just locSt ->
        let status = Map.findWithDefault exit.status exit.to locSt.exitStatuses
         in if status == ExitBlocked
              then Left "Exit is blocked"
              else case exit.viaTravel of
                Nothing ->
                  case Map.lookup exit.to ws.locations of
                    Nothing -> Left "Target location does not exist"
                    Just targetLoc ->
                      let newFocus = AtLocation exit.to
                          ws' = ws{focus = newFocus}
                          evs = [PartyMoved ws.focus newFocus]
                       in Right (ws', evs, targetLoc.baseTime)
                Just trvId ->
                  case Map.lookup trvId ws.travelCards of
                    Nothing -> Left "Travel card not found"
                    Just trv ->
                      let dir =
                            if trv.route.from == fromLocId
                              then Forward
                              else Reverse
                          newFocus = OnTravel trvId dir
                          ws' = ws{focus = newFocus}
                          evs = [PartyMoved ws.focus newFocus]
                       in Right (ws', evs, Duration 0 Minute)

-- | Complete a travel edge and arrive at the destination location.
completeTravel :: WorldState -> Either Text (WorldState, [ExplorationEvent])
completeTravel ws = case ws.focus of
  AtLocation _ -> Left "Party is not currently traveling"
  OnTravel trvId dir ->
    case Map.lookup trvId ws.travelCards of
      Nothing -> Left "Travel card not found"
      Just trv ->
        let destId = case dir of
              Forward -> trv.route.to
              Reverse -> trv.route.from
            newFocus = AtLocation destId
            ws' = ws{focus = newFocus}
            evs = [PartyMoved ws.focus newFocus]
         in Right (ws', evs)

-- | Apply scheduled boundary ticks, firing EffortCycleFlush and drawing clock cards.
applyScheduledTicks
  :: Int
  -> Maybe ClockDeckId
  -> WorldState
  -> State StdGen (WorldState, [ExplorationEvent])
applyScheduledTicks count mGovClock startWs =
  go count startWs []
  where
    go n curWs accEvs
      | n <= 0 = pure (curWs, accEvs)
      | otherwise = do
          let flushEv = [EffortCycleFlushed]
          case mGovClock of
            Nothing ->
              go (n - 1) curWs (accEvs ++ flushEv)
            Just cid -> do
              (wsAfterDraw, mCard, drawEvs) <- drawClockCard cid curWs
              case mCard of
                Nothing ->
                  go (n - 1) wsAfterDraw (accEvs ++ flushEv ++ drawEvs)
                Just card -> do
                  let (wsAfterEffects, effEvs) = applyClockEventEffects card wsAfterDraw
                  go (n - 1) wsAfterEffects (accEvs ++ flushEv ++ drawEvs ++ effEvs)

-- | Advance expedition time with support for explicit interrupt clock triggers.
advanceTimeWithInterrupt
  :: Duration
  -> [Text]
  -> Maybe ClockDeckId
  -> WorldState
  -> State StdGen (WorldState, [ExplorationEvent])
advanceTimeWithInterrupt delta tags mExplicitInterrupt ws = do
  let m_start = ws.time.totalMinutes
      durMins = toMinutes delta
      m_end = m_start + durMins
      newTime = ExpeditionTime m_end

  -- 1. Advance time
  let timeEv = [TimeAdvanced delta newTime]

  -- 2. Decrement light fuel
  let (lightSt', lightEvs) = consumeLightFuel durMins ws.lightState

  -- 3. Expire timed clock effects
  let (locStates', expiredEvs) = expireTimedEffects m_end ws.locationStates

  let ws1 =
        ws
          { time = newTime
          , lightState = lightSt'
          , locationStates = locStates'
          }

  -- 4. Immediate clock draw (Loud or explicit interrupt)
  let isLoud = any (\t -> t `elem` ["Loud", "[Loud]", "loud", "[loud]"]) tags
  let mImmediateClock = case mExplicitInterrupt of
        Just cid -> Just cid
        Nothing -> if isLoud then getActiveGoverningClock ws1 else Nothing

  (ws2, immediateEvs) <- case mImmediateClock of
    Just cid -> do
      (wsAfterDraw, mCard, drawEvs) <- drawClockCard cid ws1
      case mCard of
        Nothing -> pure (wsAfterDraw, drawEvs)
        Just card -> do
          let (wsAfterEffects, effEvs) = applyClockEventEffects card wsAfterDraw
          pure (wsAfterEffects, drawEvs ++ effEvs)
    Nothing -> pure (ws1, [])

  -- 5. Scheduled clock ticks & EffortCycleFlush across boundary ticks
  let mGovClock = getActiveGoverningClock ws2
  let tickInterval = case mGovClock of
        Just cid -> case Map.lookup cid ws2.clockDecks of
          Just cSt -> cSt.tickInterval
          Nothing -> Duration 30 Minute
        Nothing -> Duration 30 Minute

  let ticksCrossed = clockTicksCrossed (ExpeditionTime m_start) delta tickInterval

  (wsFinal, scheduledEvs) <- applyScheduledTicks ticksCrossed mGovClock ws2

  let allEvents = timeEv ++ lightEvs ++ expiredEvs ++ immediateEvs ++ scheduledEvs
  pure (wsFinal, allEvents)

-- | Pure state transition advancing expedition time, updating fuel/timed effects,
-- and triggering Loud interrupts and scheduled clock ticks.
advanceTimeAndTriggerClocks
  :: Duration
  -> [Text]
  -> WorldState
  -> State StdGen (WorldState, [ExplorationEvent])
advanceTimeAndTriggerClocks delta tags = advanceTimeWithInterrupt delta tags Nothing

-- | Initialize or register a shared teamwork challenge on the WorldState.
startTeamworkChallenge :: ActiveChallenge -> WorldState -> WorldState
startTeamworkChallenge ch ws =
  let tp =
        TeamworkProgress
          { activeChallenge = ch
          , totalStrengthContributed = 0
          , totalCardsFlipped = 0
          , totalImpactTimeAdded = Duration 0 Minute
          , participatingActors = []
          }
   in ws{activeTeamworkChallenge = Just tp}

-- | Clear any active teamwork challenge on the WorldState.
clearTeamworkChallenge :: WorldState -> WorldState
clearTeamworkChallenge ws = ws{activeTeamworkChallenge = Nothing}

-- | Record card flips contributed by an actor toward the active teamwork challenge.
-- Returns updated WorldState, whether the challenge strength target has been reached,
-- and any additional time accumulated from timePerImpact.
contributeToTeamworkChallenge
  :: Text
  -> [CardInstance CoreCard]
  -> WorldState
  -> (WorldState, Bool, Duration)
contributeToTeamworkChallenge actorName flippedCards ws =
  case ws.activeTeamworkChallenge of
    Nothing -> (ws, False, Duration 0 Minute)
    Just tp ->
      let ch = tp.activeChallenge
          color = ch.challengeColor
          cardStrength (Identified _ cc) = getStat color cc.stats
          addedStr = sum (map cardStrength flippedCards)
          numCards = length flippedCards
          extraMins = numCards * maybe 0 toMinutes ch.timePerImpact
          extraDur = Duration extraMins Minute
          currentExtra = toMinutes tp.totalImpactTimeAdded
          newTotalExtra = Duration (currentExtra + extraMins) Minute

          newStrength = tp.totalStrengthContributed + addedStr
          newCardsFlipped = tp.totalCardsFlipped + numCards
          newActors =
            if actorName `elem` tp.participatingActors
              then tp.participatingActors
              else tp.participatingActors ++ [actorName]

          tp' =
            tp
              { totalStrengthContributed = newStrength
              , totalCardsFlipped = newCardsFlipped
              , totalImpactTimeAdded = newTotalExtra
              , participatingActors = newActors
              }
          isComplete = newStrength >= ch.challengeStrength
          ws' = ws{activeTeamworkChallenge = Just tp'}
       in (ws', isComplete, extraDur)
