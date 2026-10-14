---
title: "Authoring Guide: Locations, Travel, and Clock Cards"
doc_type: guide
track: ludology
origin: AI drafted
epistemic_status:
  confidence: high
  vetted_by_human: true
---

# Authoring Guide: Locations, Travel, and Clock Cards

This document formalizes the data schemas, mechanical conventions, and card anatomy for **Location Cards**, **Travel Cards**, and **Clock Cards** in _caRdPG_.

Following our core design precepts, these schemas treat **in-game time as a concrete physical quantity (minutes, hours, days)** rather than abstract card triggers. The digital tabletop and GM use these structured definitions to track time passage, evaluate scheduled clock checks, and trigger immediate interrupt draws when noisy or high-risk actions occur.

---

## 1. Architectural Principles

1. **Explicit Time Quotas:** Every exploratory action, movement choice, or physical feat specifies an exact time cost (e.g. `10m`, `45m`, `2h`).
2. **Dual-Trigger Reactivity:**
   - **Scheduled Ticks:** Clock decks advance when cumulative elapsed time crosses defined thresholds (tentatively 30 min in delves, 60 min on trails, 24 h in havens).
   - **Action Interrupts:** Actions bearing specific risk tags (`[Loud]`, `[Exposed]`, `[Flared Torch]`) immediately force an interrupt draw from the designated clock deck, bypassing the timer.
3. **Ergonomic Action Menus:** Location and Travel cards serve as tactile, interactive choice boards where options present distinct trade-offs across [[Colors]] ([[Red]], [[Yellow]], [[Blue]]) alongside safe, time-intensive bypasses.
4. **No Flat Card Taxes (Labor vs. Attrition):** Cards should never demand arbitrary flat card discards (e.g. _"Discard 3 cards to pass"_). Strenuous physical exertion and methodical deconstruction are adjudicated as [[Red]] challenges testing [[Strength]]; success is default, but flipping cards represents caloric work and deck stamina. General environmental strain and march pacing are adjudicated through **in-game time**, allowing party attrition to flow naturally through the [[Vigilance]] dial, scheduled clock checks, and the [[Fatigue Cycle]]. Methodical "safe" options avoid acute injuries and noise interrupts, but they are never free of physical labor costs.
5. **Lean Schema (Computable vs. Descriptive):** Schemas only formalize fields that the game engine or VTT rules strictly compute (`time_cost_minutes`, `time_base_minutes`, `time_per_impact_minutes`, `color`, `strength`, `interrupt`, `exits`). Atmospheric details, lighting, and narrative outcomes remain concise text and freeform tags to minimize LLM hallucination and human audit overhead.
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
base_time_minutes: 5 # Time to traverse when cleared/unobstructed
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
    time_cost_minutes: 10 # Fixed in-game time elapsed
    color: "Red | Yellow | Blue" # Target Color
    strength: 15 # Required Strength to meet
    consequences: ["BluntForce", "Sprain"] # Specific tags for consequence cards drawn
    tags: ["Loud", "Exhausting", "ObstacleTags..."] # Tags triggering clock interrupts or tool affinities
    narrative: "What the character attempts and the immediate outcome."
    interrupt: "site_clock_id" # Optional. Triggers immediate clock draw on attempt

  # Methodical Labor Option (Safe from acute trauma/alarms, but costs deck stamina & dynamic time)
  - name: "Methodical Labor Title"
    color: "Red" # Usually Red for physical deconstruction or hauling
    strength: 16 # Required Strength to meet; success is default, cards flipped = caloric stamina
    time_base_minutes: 30 # Baseline duration
    time_per_impact_minutes: 10 # Additional time per card in the flipped stack
    consequences: ["Fatigue"] # Strictly benign physical wear/fatigue; no traumatic injury
    tags: ["Barricade", "Timber", "Leverage", "Teamwork", "Quiet"] # Tags interacting with tools & party effort
    narrative: "Disciplined, cautious labor that avoids alarm and physical trauma at the cost of stamina and time."
```

### 2.2 Reference Implementation: The Barricaded Portal

> [!NOTE]
> The examples below are drawn from the _Crag-Gallows Expedition_ case study to illustrate how Location, Travel, and Clock schemas interact in play.

```yaml
id: "loc_barricaded_portal"
name: "The Barricaded Portal"
card_type: "Location"
governing_clock: "site_activity_clock"
base_time_minutes: 5
tags: ["Chokepoint", "Dim", "ColdDamp"]

exits:
  - to: "loc_sorting_yard"
    status: "blocked"
    passage: "Rock archway jammed with timber and mine rails"

narrative: >
  A crude deadfall of twisted mine rails, sharpened stakes, and suspended tin 
  cans blocks the rock archway leading deeper into the workings.

actions:
  - name: "Sledgehammer Breach"
    time_cost_minutes: 1
    color: "Red"
    strength: 22 # Formidable physical feat
    consequences: ["Exhaustion", "BluntForce"]
    tags: ["Loud", "Exhausting"]
    narrative: "Shatter rails and timber stakes with heavy sledge blows. Clears the passage immediately."
    interrupt: "site_activity_clock"

  - name: "Muffled Wire Disarm"
    time_cost_minutes: 10
    color: "Yellow"
    strength: 15 # Challenging finesse feat
    consequences: ["PinchWound", "TripwireSnap"]
    tags: ["Quiet"]
    narrative: "Snip tripwires delicately and squeeze through gaps in the timbers without sound."

  - name: "Structural Keystoning"
    time_cost_minutes: 5
    color: "Blue"
    strength: 14 # Discipline and engineering insight
    tags: ["Quiet"]
    narrative: "Identify and dislodge the load-bearing wedge to swing the entire barricade outward like a gate."

  - name: "Methodical Deconstruction"
    color: "Red"
    strength: 16 # Challenging physical labor; success is guaranteed, flips determine stamina cost
    time_base_minutes: 30
    time_per_impact_minutes: 10 # Dynamic time: 30m + (Impact × 10m)
    consequences: ["Fatigue"] # Controlled risk: strictly fatigue cards, no blunt force or alarms
    tags: ["Barricade", "Timber", "Leverage", "Teamwork", "Quiet"]
    narrative: "Carefully lever rails aside and unseat timber stakes. Safe and quiet, but demanding physical labor. Leverage tools and teamwork apply."
```

### 2.3 Tag-Driven Tool & Teamwork Interactions

To maintain a lean schema, Location cards never hardcode inventory-specific rules. Instead, obstacles declare physical tags, and character inventory/gear interacts with those tags through defined keywords:

- **Strength Modifiers (Mechanical Advantage):** Tools with matching tags grant bonus Strength (e.g., _Prying Crowbar: +4 Red vs `[Leverage]`_). This directly reduces the number of cards flipped, lowering both [[Impact]] and dynamic time.
- **Dynamic Time Scaling:** Specialized tools can cut base labor time or per-impact scaling (e.g., _Two-Man Crosscut Saw: Halves base time on `[Timber, Teamwork]`_).
- **Consequence Filtering:** Protective gear can absorb impact or filter out specific minor trauma (e.g., _Heavy Work Gloves: Absorb 1 Impact from `[Splinter, PinchWound, Blister]` consequences_).
- **Approach Enablers:** Specialized kits unlock alternative Color approaches that would otherwise be impossible (e.g., _Lockpicks: Unlocks Yellow finesse actions on `[MechanicalLock]`_).
- **Collective Party Labor (`[Teamwork]`):** When a labor action has the `[Teamwork]` tag, multiple characters may contribute cards to meet the [[Strength]]. Each helper flips cards toward the total, and each worker only resolves [[Impact]] against their own [[Defense]] for the cards they personally flipped. Dynamic time is calculated using the highest individual Impact (or total flips divided by number of workers), representing shared labor efficiency.

---

## 3. Travel Card Schema (Overland Routes & Wilderness Legs)

A **Travel Card** represents an overland trail segment, mountain pass, or wilderness leg between landmarks.

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
  base_time_minutes: 60 # Standard walking pace
  terrain_tags: ["Steep", "ExposedWind", "DenseCanopy", "Fording"]

narrative: >
  Atmospheric overview of the trail, weather exposure, and terrain footing.

# Travel Paces & Stance Options
paces:
  # Measured / Standard Pace
  - name: "Measured March"
    time_cost_minutes: 60
    tags: ["StandardPace"]
    narrative: "Keep a steady, cautious footing along the trail. Party pays for [[Vigilance]] normally."

  # Rushed Pace (Red or Yellow Challenge to save time)
  - name: "Forced March / Fast Scramble"
    time_cost_minutes: 25
    color: "Red"
    strength: 15
    consequences: ["Exhaustion", "MuscleStrain"]
    tags: ["Rushed", "Exhausting"]
    narrative: "Power through at a dead run or heavy march to cut travel time in half."

  # Scouted / Cautious Pace (Blue Challenge to secure route)
  - name: "Route Scouting"
    time_cost_minutes: 75
    color: "Blue"
    strength: 14
    tags: ["Safe", "TimeConsuming"]
    narrative: "Scout solid ground and sightlines to bypass natural hazards and avoid predator ambushes."

# Optional Field Expedients (Omit if not applicable)
expedients:
  camp_restriction: "Exposed slope prone to rockslides; pitching camp triggers immediate clock draw."
  forage:
    time_cost_minutes: 30
    color: "Blue"
    strength: 10
    narrative: "Search for medicinal roots, dry kindling, or edible flora along the route."
```

### 3.2 Reference Implementation: The Low Scree Path

```yaml
id: "trv_low_scree_path"
name: "The Low Scree Path"
card_type: "Travel"
governing_clock: "wilderness_clock"

route:
  from: "haven_crow_roost"
  to: "site_timber_cut"
  distance_leagues: 1.5
  base_time_minutes: 45
  terrain_tags: ["LooseSlate", "WindBuffeted", "WolfSign"]

narrative: >
  A treacherous trail of loose shale skirting the ravine edge, buffeted by 
  erratic mountain drafts and crisscrossed by predator tracks.

paces:
  - name: "Measured Mountain March"
    time_cost_minutes: 45
    tags: ["StandardPace"]
    narrative: "Pick footsteps carefully through loose slate and low brambles. Standard vigilance flushes apply."

  - name: "Agile Scree Scramble"
    time_cost_minutes: 20
    color: "Yellow"
    strength: 15
    consequences: ["BruisedShins", "RattleScreeNoise"]
    tags: ["Rushed"]
    narrative: "Sprint up the shale incline before gravel slides gather momentum."
    interrupt: "wilderness_clock" # Failure or noise alerts predators

  - name: "Packhorse Anchor Haul"
    time_cost_minutes: 35
    color: "Red"
    strength: 20
    consequences: ["MuscleStrain"]
    tags: ["Exhausting"]
    narrative: "Drive anchor stakes and muscle companions and heavy gear up the grade."

expedients:
  camp_restriction: "Exposed slope; cold camping is prohibited due to rockfall hazard."
  forage:
    time_cost_minutes: 30
    color: "Blue"
    strength: 10
    narrative: "Gather willow bark and wound moss along the damp rock cut."
```

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
    duration_minutes: 60 # Optional. If omitted, change is permanent or immediate
```

### 4.2 Reference Implementation: Sentry Shift Rotation

```yaml
id: "clk_site_sentry_rotation"
name: "Sentry Shift Rotation"
card_type: "ClockEvent"
clock_deck: "site_activity_clock"
urgency: "Immediate"
tags: ["InhabitantAction"]

narrative:
  summary: "Goblin sentries rotate posts across the upper terraces."
  sensory_cue: "Muffled guttural bickering and the clatter of dropped spears echo along the catwalks."

effects:
  - target: "loc_barricaded_portal"
    text: "The barricade portal is left completely unguarded for the next 20 minutes."
    duration_minutes: 20
  - target: "loc_sorting_yard"
    text: "2 additional goblin lookouts join the watch fire."
```

### 4.3 Reference Implementation: Sudden Scree Squall

```yaml
id: "clk_wild_sudden_scree_squall"
name: "Sudden Scree Squall"
card_type: "ClockEvent"
clock_deck: "wilderness_clock"
urgency: "OngoingModifier"
tags: ["EnvironmentalShift"]

narrative:
  summary: "Freezing rain and sleet lash down from the upper crags."
  sensory_cue: "The wind shrieks as heavy hail hammers against cloaks and slates."

effects:
  - target: "current_zone"
    text: "Extinguish all unshielded open flames. +5 Yellow Strength to all footing and climbing checks."
    duration_minutes: 60
```

---

## 5. Visual Card Anatomy (Tabletop & VTT UI)

### 5.1 Location Card Anatomy

```
┌────────────────────────────────────────────────────────┐
│ [DELVE NODE]               THE BARRICADED PORTAL   [5m]│
│ Tags: [Chokepoint] [Dim] [ColdDamp]                    │
├────────────────────────────────────────────────────────┤
│ A crude deadfall of twisted mine rails, sharpened     │
│ stakes, and suspended tin cans blocks the rock archway.│
├────────────────────────────────────────────────────────┤
│ EXITS:                                                 │
│   • To Sorting Yard: Blocked (Clear deadfall below)    │
├────────────────────────────────────────────────────────┤
│ ACTIONS & OBSTACLES:                                   │
│                                                        │
│ [RED 22] Sledgehammer Breach                      [1m] │
│   💥 [LOUD] Immediately triggers Site Clock draw!      │
│                                                        │
│ [YEL 15] Muffled Wire Disarm                     [10m] │
│   🤫 [QUIET] Snip tripwires cleanly; bypasses alarm    │
│                                                        │
│ [BLU 14] Structural Keystoning                    [5m] │
│   🤫 [QUIET] Unseat the wedge; swings barricade open   │
│                                                        │
│ [RED 16] Methodical Deconstruction      [30m +10m/Imp] │
│   🤫 [QUIET] [TEAMWORK] [LEVERAGE] Safe; Fatigue only  │
└────────────────────────────────────────────────────────┘
```

### 5.2 Travel Card Anatomy

```
┌────────────────────────────────────────────────────────┐
│ [TRAVEL ROUTE]               THE LOW SCREE PATH  [45m] │
│ Route: Crow-Roost ➔ Timber Cut (1.5 Leagues)           │
│ Tags: [LooseSlate] [WindBuffeted] [WolfSign]           │
├────────────────────────────────────────────────────────┤
│ A treacherous trail of loose shale skirting the ravine │
│ edge, buffeted by erratic drafts and predator tracks.  │
├────────────────────────────────────────────────────────┤
│ MARCH PACES:                                           │
│                                                        │
│ [PACE]   Measured Mountain March                 [45m] │
│   🚶 Standard walking pace; normal vigilance flushes   │
│                                                        │
│ [YEL 15] Agile Scree Scramble                    [20m] │
│   ⚡ [RUSHED] Sprint up shale before slides gather     │
│                                                        │
│ [RED 20] Packhorse Anchor Haul                   [35m] │
│   💪 [EXHAUSTING] Muscle heavy baggage up the grade    │
├────────────────────────────────────────────────────────┤
│ EXPEDIENTS:                                            │
│   • Camp: Prohibited (Exposed slope / rockfall risk)   │
│   • [BLU 10] Forage: Willow bark & wound moss    [30m] │
└────────────────────────────────────────────────────────┘
```

### 5.3 Clock Event Card Anatomy

```
┌────────────────────────────────────────────────────────┐
│ [SITE CLOCK EVENT]         SENTRY SHIFT ROTATION [IMM] │
│ Tags: [InhabitantAction]                               │
├────────────────────────────────────────────────────────┤
│ "Muffled guttural bickering and the clatter of dropped │
│ spears echo along the catwalks."                       │
├────────────────────────────────────────────────────────┤
│ Goblin sentries rotate posts across the upper terraces │
│ leaving routine posts temporarily abandoned.           │
├────────────────────────────────────────────────────────┤
│ EFFECTS:                                               │
│   • loc_barricaded_portal: Unguarded for 20 minutes    │
│   • loc_sorting_yard: +2 Goblins at watch fire         │
└────────────────────────────────────────────────────────┘
```
