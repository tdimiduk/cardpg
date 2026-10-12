---
title: "Software Requirements: Time Economy, Living Clocks, and Modular Decks"
doc_type: iteration
track: ludology
origin: AI drafted
epistemic_status:
  confidence: high
  vetted_by_human: true
---

# Software Requirements: Time Economy, Living Clocks, and Modular Decks

This checklist details the architectural and functional software requirements for supporting the **Grounded Time Economy**, **Living Clock Decks**, and **Location/Travel Decks** within the _caRdPG_ digital tabletop platform.

---

## 1. System Architecture Overview

```mermaid
flowchart TD
    subgraph UI ["Frontend UI (Reflex-FRP)"]
        CHRONO_UI["Chronometer Widget<br/>(Day / Time / Light Fuel)"]
        BOARD_UI["Location / Map Board<br/>(Action Menus, Obstacles, Tags)"]
        CLOCK_UI["Clock Deck Tray<br/>(Active Decks, Progress Pulse)"]
        PLAYER_UI["Player Ready Hand Tableau<br/>(Vigilance Dial 0–4, Guard)"]
    end

    subgraph ENGINE ["Core Engine Logic (Haskell)"]
        CHRONO["Expedition Chronometer<br/>(Time Accumulator & Thresholds)"]
        EVENT_BUS["Event & Interrupt Bus<br/>(Tags: [Loud], [Exposed])"]
        DECK_MGR["Modular Deck Manager<br/>(Location, Travel, Clock, Player)"]
        EXPLORE_ENG["Adventuring Time State<br/>(Effort Cycles, Breathers, Fatigue)"]
    end

    BOARD_UI -->|Trigger Action / Move| CHRONO
    BOARD_UI -->|Emit Tags [Loud]| EVENT_BUS
    CHRONO -->|Threshold Crossed| DECK_MGR
    EVENT_BUS -->|Immediate Draw| DECK_MGR
    CHRONO -->|30m Effort Cycle| EXPLORE_ENG
    EXPLORE_ENG -->|Flush / Redraw| PLAYER_UI
    DECK_MGR -->|Reveal Event| CLOCK_UI
```

---

## 2. Requirement Checklist

### Epic 1: The Expedition Chronometer & Time Engine

- [ ] **1.1 Core Time Data Model (`Core.Time`)**
  - Implement `ExpeditionTime { day :: Int, hour :: Int, minute :: Int }`.
  - Provide formatting functions (e.g., `Day 1, 14:35`, `+15m`).
  - Implement time arithmetic: adding minutes, computing intervals.
- [ ] **1.2 Time Advancement Action & State**
  - Add `AdvanceExpeditionTime Minutes` constructor to root game action types.
  - Automatically advance chronometer when:
    - Resolving Location/Travel actions (`time_cost_minutes`).
    - Taking a Breather (`+15m`).
    - Moving between connected nodes (`base_time_minutes`).
- [ ] **1.3 Periodic Clock Schedule Dispatcher**
  - Configurable schedule triggers per environment:
    - **Delve/Dungeon:** Pulse every 30 minutes (tentative baseline).
    - **Wilderness:** Pulse every 60 minutes (tentative baseline).
    - **Macro Haven:** Pulse every 24 hours.
  - Statefully track elapsed minutes toward the next scheduled pulse.
  - When threshold is crossed:
    1. Emit `ScheduledClockCheck <DeckId>`.
    2. Emit `EffortCycleFlush`.
    3. Decrement active light source fuel.
- [ ] **1.4 Consumable Timers & Fuel Tracking**
  - Track active light sources (`Torch`, `Lantern`, `Candle`) with remaining duration in minutes.
  - When light fuel reaches 0:
    - Transition current location lighting state to `PitchBlack`.
    - Trigger dark peril notifications / condition checks.

---

### Epic 2: Modular Deck Architecture (Location, Travel, Clock)

- [ ] **2.1 Card Definition Schemas & Parsers**
  - Implement YAML parsers and Aeson codecs for:
    - `LocationCard` (traversal time, lighting, atmosphere, actions with Color/Strength, search/breather options).
    - `TravelCard` (distance, terrain tags, travel paces, forage options).
    - `ClockEventCard` (target entity/zone, mutations, sensory cues).
- [ ] **2.2 Multi-Deck Management Engine**
  - Extend game state to hold named active decks:
    - `activeLocationDeck :: Maybe LocationDeck`
    - `activeTravelDeck :: Maybe TravelDeck`
    - `siteActivityClock :: ClockDeck`
    - `wildernessClock :: ClockDeck`
    - `macroHavenClock :: ClockDeck`
  - Support deck operations:
    - `DrawCard :: DeckId -> GameState -> (Card, GameState)`
    - `InsertInterferenceCard :: DeckId -> Card -> GameState -> GameState` (for player project sabotage or delay)
    - `ShuffleDeck :: DeckId -> GameState -> GameState`
    - `PeekTop :: DeckId -> Int -> [Card]` (for scouting abilities)

---

### Epic 3: Interrupt & Event-Driven Engine

- [ ] **3.1 Action Tag Evaluation**
  - Actions specify metadata tags: `[Loud]`, `[Exposed]`, `[Quiet]`, `[Exhausting]`.
  - On action execution, inspect tags:
    - If `[Loud]` is present: bypass the chronometer timer and immediately dispatch `ImmediateClockDraw SiteActivityDeck`.
    - Notify adjacent nodes or raise regional alert level.
- [ ] **3.2 Catastrophic Failure / Alert Hooks**
  - If a player fails a General Action with severe margin or suffers an alerting consequence (`RattleScreeNoise`, `SpilledTinCans`), emit immediate clock draw.
- [ ] **3.3 Event Execution & Mutation Pipeline**
  - Apply Clock Card effects to game state:
    - `ModifyHazard` (e.g. wet slates, sleet, extinguished torches).
    - `ClearGuard` / `ReinforceGuard` (shift monster tokens between nodes).
    - `SpawnEncounter` (initiate Crisis Time transition).

---

### Epic 4: Adventuring Time State & Ready Hand Automation

- [ ] **4.1 The Vigilance Dial & Ready Hand Tableau**
  - Each actor maintains a `vigilanceDial :: Int` (range: 0 to 4).
  - Ready Hand state:
    - Up to 1 card can be marked as `FaceUpGuard`.
    - Remaining cards (up to dial) dealt face down.
- [ ] **4.2 Automated Effort Cycle Flushing**
  - Triggered automatically on scheduled 30-min delve pulses (or manual GM trigger).
  - Flush procedure:
    1. For unspent `FaceUpGuard`: prompt player to either discard 2 cards from deck to retain guard, or allow guard to flush to expended pile.
    2. Move remaining Ready Hand cards to `expended` pile.
    3. Redraw face-down cards from draw deck up to `vigilanceDial`.
    4. If deck is exhausted during redraw, execute standard `FatigueCycle`.
- [ ] **4.3 Breather (Short Rest) Procedure Wizard**
  - Dedicated interactive modal/action:
    1. Adds 15 minutes to Chronometer.
    2. Inspects actor's `expended` pile count:
       - $< 12$ cards: adds 1 Fatigue card.
       - $\ge 12$ cards: adds 2 Fatigue cards.
    3. Toggle: `"Unbuckle Armor Harness"`:
       - If checked: ignore armor `Burden` for this rest cycle.
       - If unchecked: add active `Burden` to added fatigue cards.
    4. Reshuffles expended pile into draw deck.
    5. Allows player to select 1 Action Card as free `FaceUpGuard`.
    6. Refills Ready Hand up to chosen vigilance dial.

---

### Epic 5: Transition between Adventuring Time and Crisis Time

- [ ] **5.1 Mutual Awareness Transition**
  - When an encounter triggers from a Location or Clock card:
    - Actors pick up their `Ready Hand` (face-down + face-up guard) as their starting hand for Round 1 of Crisis Time.
    - Actors with vigilance dial 0 enter Round 1 with an empty hand (must rely on 2 drawn round cards).
- [ ] **5.2 Surprise & Ambush Transition**
  - If characters are caught unprepared:
    - Characters with Ready Hand 0 skip Round 1 action declaration.
- [ ] **5.3 Exiting Crisis Time Back to Exploration**
  - Discard all remaining hand cards to expended pile.
  - Reset Ready Hand from deck based on current vigilance dial.
  - Resume Chronometer tracking.

---

### Epic 6: User Interface & Tabletop Ergonomics (Reflex Frontend)

- [ ] **6.1 Chronometer & Environment Bar**
  - Persistent UI banner displaying:
    - Current day, time, and active lighting icon (Torch / Lantern / Darkness).
    - Visual progress meter toward next scheduled clock pulse (e.g. `20/30m`).
    - Remaining fuel indicator (e.g. `Torch: 35m left`).
- [ ] **6.2 Location / Node Card Display Widget**
  - Render active Location Card:
    - Room title, atmosphere tags, and narrative flavor.
    - Color-coded action buttons with explicit `[Strength]` and `[Time Cost]`.
    - Visual indicators for `[LOUD 💥]` options.
- [ ] **6.3 Clock Event Banner / Card Reveal Modal**
  - When a Clock Card is drawn (scheduled or interrupt):
    - Display dramatic card reveal with sensory cue text.
    - Highlight world state changes (e.g., _“Patrol shifted to Ore Yard!”_).
- [ ] **6.4 Vigilance Dial Slider on Player Board**
  - Tactile 0–4 slider on actor mat allowing quick vigilance adjustments between rooms.
  - Visual display of Face-Up Guard card and Face-Down cards.
