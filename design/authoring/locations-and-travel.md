---
title: "Authoring Guide: Locations, Travel, and Clock Cards"
doc_type: guide
track: ludology
origin: AI drafted
epistemic_status:
  confidence: high
  vetted_by_human: false
---

# Authoring Guide: Locations, Travel, and Clock Cards

This document formalizes the data schemas, mechanical conventions, and card anatomy for **Location Cards**, **Travel Cards**, and **Clock Cards** in _caRdPG_.

Following our core design precepts, these schemas treat **in-game time as a concrete physical quantity (minutes, hours, days)** rather than abstract card triggers. The digital tabletop and GM use these structured definitions to track time passage, evaluate scheduled clock checks, and trigger immediate interrupt draws when noisy or high-risk actions occur.

---

## 1. Architectural Principles

1. **Explicit Time Quotas (Parsed Durations):** Every exploratory action, movement choice, or physical feat specifies a duration with explicit units (e.g., `time: "10 min"`, `time: "45 min"`, `base_time: "1 hour"`, `duration: "2 days"`). The engine parses these into a canonical `Duration` type, allowing natural multi-scale expression across delve minutes, travel hours, and haven recovery days without manual conversion math.
2. **Dual-Trigger Reactivity:**
   - **Scheduled Ticks:** Clock decks advance when cumulative elapsed time crosses defined thresholds (tentatively 30 min in delves, 60 min on trails, 24 h in havens).
   - **Action Interrupts:** Actions bearing risk tags (`[Loud]`, `[Exposed]`) automatically trigger an immediate interrupt draw from the card's `governing_clock`, bypassing the chronometer. Actions only specify an explicit `interrupt: <clock_id>` if overriding the default clock.
3. **Ergonomic Action Menus:** Location and Travel cards serve as tactile, interactive choice boards where options present distinct trade-offs across [[Colors]] ([[Red]], [[Yellow]], [[Blue]]) alongside safe, time-intensive bypasses.
4. **No Flat Card Taxes—Caloric Work Always Tests `Strength`:** Cards should never demand arbitrary flat card discards (e.g. _"Discard 3 cards to pass"_), nor should physical travel or labor ever be free of card expenditure. Any activity that expends physical stamina—including **standard overland marching (`Measured March`)**, forced marches, heavy labor, and athletic maneuvers—is adjudicated as a colored challenge testing [[Strength]]: primarily [[Red]] (endurance, hiking, heavy lifting, deconstruction) and [[Yellow]] (agility, balance, scrambling, precision footing), with [[Blue]] for engineering and route-finding. Success is default, and flipping cards represents caloric work and deck stamina. Passive time passage (resting in camp, waiting, riding in a wagon) advances **in-game time** without a `Strength` check, while [[Vigilance]] flushes track the orthogonal mental/nervous cost of staying combat-ready. Sudden, acute perils (springing traps, collapsing masonry, flash floods) are adjudicated as **Hazard Attacks** testing active defenses and vigilance readiness per [Core Rules](../rules/core-rules.md).
5. **Lean Schema (Computable vs. Descriptive):** Schemas formalize fields that the game engine or VTT rules strictly compute (`base_time`, `time`, `time_per_impact`, `color`, `strength`, `unblocks`, `interrupt`, `exits`). Atmospheric details, lighting, and narrative outcomes remain concise text and freeform tags to minimize LLM hallucination and human audit overhead.
6. **Decoupled Tool Affinities (Tag-Driven Interaction):** Location cards should never hardcode specific item bypasses (e.g. _"If you have a crowbar: bypass"_). Instead, obstacles declare physical tags (`[Barricade]`, `[Timber]`, `[Leverage]`, `[Teamwork]`), and tools modify levers (Strength bonus, dynamic time reduction, impact absorption, or unlocking colors) through matching keywords. This keeps location schemas lean and decouples environment design from party inventory.

---

## 2. Location Card Schema (Delve & Dungeon Nodes)

A **Location Card** represents a distinct chamber, corridor, or threshold in a delve or indoor structure.

### 2.1 YAML Specification

```yaml
# Schema: Location Card
id: "loc_<slug>"
name: "Display Name"
card_type: "Location"
governing_clock: "site_clock_id" # Clock deck checked for scheduled or interrupt draws
base_time: "5 min" # Time to traverse when cleared/unobstructed
tags: ["Chokepoint", "PitchBlack", "ColdDamp"] # Freeform environmental & tactical tags

# Spatial Graph Navigation
exits:
  - to: "loc_destination_slug"
    status: "open | blocked" # If blocked, requires overcoming an obstacle below
    passage: "Stairs down | Heavy oak door | Iron portcullis"

# Narrative Presentation
narrative: >
  Concise sensory description of the space, hazards, and visible obstacles.

# Obstacles & Interactive Choices
actions:
  # Rapid / Acute Challenge (Tests Character Attributes via Red, Yellow, or Blue)
  - name: "Action Title"
    time: "10 min" # Base duration (parsed Duration: "m", "min", "h", "hour", etc.)
    color: "Red | Yellow | Blue" # Target Color (optional; omit if no challenge check)
    strength: 15 # Required Strength (optional; required if `color` present)
    consequences: ["BluntForce", "Sprain"] # Specific tags for consequence cards drawn (optional)
    tags: ["Loud", "Exhausting", "ObstacleTags..."] # Tags triggering clock interrupts or tool affinities
    unblocks: "loc_destination_slug" # Optional: matches exits[].to to open blocked passage on success
    narrative: "What the character attempts and the immediate outcome."
    interrupt: "other_clock_id" # Optional override (omit to trigger governing_clock automatically on [Loud])

  # Methodical Labor Option (Safe from acute trauma/alarms, but costs deck stamina & dynamic time)
  - name: "Methodical Labor Title"
    time: "30 min" # Base duration
    time_per_impact: "10 min" # Optional: additional time per card in the flipped stack (default: 0)
    color: "Red" # Usually Red for physical deconstruction or hauling
    strength: 16 # Required Strength to meet; success is default, cards flipped = caloric stamina
    consequences: ["Fatigue"] # Strictly benign physical wear/fatigue; no traumatic injury
    tags: ["Barricade", "Timber", "Leverage", "Teamwork", "Quiet"] # Tags interacting with tools & party effort
    unblocks: "loc_destination_slug" # Opens blocked exit upon completion
    narrative: "Disciplined, cautious labor that avoids alarm and physical trauma at the cost of stamina and time."
```

> [!TIP]
> **Reference Implementation:** See [`data/modules/crag_gallows/locations.yaml`](../../data/modules/crag_gallows/locations.yaml) for working Location card examples (such as _The Barricaded Portal_).

### 2.2 Tag-Driven Tool, `Defense` Domain & Teamwork Interactions

To maintain a lean schema, Location cards never hardcode inventory-specific rules. Instead, obstacles declare physical tags, and character inventory/gear interacts with those tags through defined keywords:

- **Strength Modifiers (Mechanical Advantage):** Tools with matching tags grant bonus Strength (e.g., _Prying Crowbar: +4 Red vs `[Leverage]`_). This directly reduces the number of cards flipped, lowering both [[Impact]] and dynamic time.
- **Dynamic Time Scaling:** Specialized tools can cut base labor time or per-impact scaling (e.g., _Two-Man Crosscut Saw: Halves base time on `[Timber, Teamwork]`_).
- **`Defense` Domains & Consequence Filtering:** Every character has an innate baseline of `Defense 1, Resilience 1` across all domains, while equipment and trait `Defense` ratings apply **only to their specified domain tags**. Combat armor grants `Defense` against external physical trauma (`[BluntForce]`, `[Slash]`, `[Puncture]`, `[Crush]`), never internal exertion (`[Fatigue]`, `[Exhaustion]`, `[MuscleStrain]`). Conversely, survival gear and conditioning traits grant `Defense` against matching labor or travel domains (e.g., _Heavy Work Gloves: `Defense 2` vs `[Splinter, PinchWound, Blister]`_; _Seasoned Traveler: `Defense 3` vs `[Travel, Exertion]`_).
- **Approach Enablers:** Specialized kits unlock alternative Color approaches that would otherwise be impossible (e.g., _Lockpicks: Unlocks Yellow finesse actions on `[MechanicalLock]`_).
- **Collective Party Labor (`[Teamwork]`):** When a labor action has the `[Teamwork]` tag, multiple characters may contribute cards to meet the [[Strength]]. Each helper flips cards toward the total, and each worker only resolves [[Impact]] against their own domain-applicable [[Defense]] for the cards they personally flipped. Dynamic time is calculated using the highest individual Impact (or total flips divided by number of workers), representing shared labor efficiency.

---

## 3. Travel Card Schema (Overland Routes & Wilderness Legs)

A **Travel Card** represents an overland trail segment, mountain pass, or wilderness leg between landmarks. Because walking and climbing across terrain expends physical stamina regardless of a character's mental [[Vigilance]], **every active foot-travel pace must include a colored `Strength` check**.

### 3.1 YAML Specification

```yaml
# Schema: Travel Card
id: "trv_<slug>"
name: "Display Name"
card_type: "Travel"
governing_clock: "wilderness_clock_id"

# Route & Distance Parameters
route:
  from: "node_id"
  to: "node_id"
  distance_leagues: 1.0 # Optional mapping distance
  base_time: "1 hour" # Standard walking pace duration
  terrain_tags: ["Steep", "ExposedWind", "DenseCanopy", "Fording"]

narrative: >
  Atmospheric overview of the trail, weather exposure, and terrain footing.

# Travel Paces & Stance Options (Advance party to route.to upon completion)
paces:
  # Measured / Standard Pace (Always includes a baseline Red endurance check)
  - name: "Measured March"
    time: "1 hour"
    color: "Red"
    strength: 10
    consequences: ["Fatigue"]
    tags: ["StandardPace", "Travel", "Exertion"]
    narrative: "Keep a steady, measured footing along the trail. Flip to meet hiking exertion, plus pay hourly [[Vigilance]]."

  # Rushed Pace (Higher Red or Yellow Challenge to save time, risking acute strain)
  - name: "Forced March / Fast Scramble"
    time: "25 min"
    color: "Red"
    strength: 16
    consequences: ["Exhaustion", "MuscleStrain"]
    tags: ["Rushed", "Exhausting", "Travel", "Exertion"]
    narrative: "Power through at a dead run or heavy march to cut travel time in half."

  # Scouted / Cautious Pace (Blue Challenge to secure route and avoid hazards)
  - name: "Route Scouting"
    time: "75 min"
    color: "Blue"
    strength: 14
    consequences: ["Fatigue"]
    tags: ["Safe", "TimeConsuming", "Travel", "Exertion"]
    narrative: "Scout solid ground and sightlines to bypass natural hazards and avoid predator ambushes."

# Optional Field Expedients (Local trailside tasks; does not advance route)
expedients:
  camp_restriction: "Exposed slope prone to rockslides; pitching camp triggers immediate clock draw."
  actions:
    - name: "Trailside Forage"
      time: "30 min"
      color: "Blue"
      strength: 10
      narrative: "Search for medicinal roots, dry kindling, or edible flora along the route."
```

> [!TIP]
> **Reference Implementation:** See [`data/modules/crag_gallows/travel.yaml`](../../data/modules/crag_gallows/travel.yaml) for working Travel card examples (such as _The Low Scree Path_).

---

## 4. Clock Deck Card Schema (Events, Shifts & Portents)

A **Clock Card** represents an event drawn from a procedural Clock Deck (Site Activity, Wilderness, or Macro Haven) per [Clocks and Fronts](../rules/modules/clocks-and-fronts.md).

### 4.1 YAML Specification

```yaml
# Schema: Clock Card
id: "clk_<slug>"
name: "Event Title"
card_type: "ClockEvent"
clock_deck: "site_activity_clock | wilderness_clock | haven_clock" # Deck this card belongs to
urgency: "Immediate | OngoingModifier | TelegraphedPortent"
tags: ["InhabitantAction | EnvironmentalShift | Encounter | Portent"]

# Narrative Presentation
narrative:
  summary: "Brief description of the event or shift."
  sensory_cue: "Acoustic, visual, or olfactory tell observed by characters."

# Concrete World State Changes
effects:
  - target: "loc_node_id | current_zone | party"
    text: "Clear description of the mutation (e.g. +5 Yellow Strength to footing, guard leaves post, monster spawns)."
    duration: "1 hour" # Optional parsed Duration (omit if immediate/permanent)
    hazard: # Optional: triggers defender-centric Hazard Attack modal in VTT
      color: "Yellow"
      strength: 12
      consequences: ["BluntForce", "Sprain"]
```

> [!TIP]
> **Reference Implementation:** See [`data/modules/crag_gallows/clocks.yaml`](../../data/modules/crag_gallows/clocks.yaml) for working Clock Event card examples (such as _Sentry Shift Rotation_ and _Sudden Scree Squall_).
