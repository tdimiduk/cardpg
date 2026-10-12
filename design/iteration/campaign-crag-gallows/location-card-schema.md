---
title: "Data Schema: Location, Travel, and Clock Cards"
doc_type: iteration
track: ludology
origin: AI drafted
epistemic_status:
  confidence: high
  vetted_by_human: true
---

# Data Schema: Location, Travel, and Clock Cards

This document formalizes the data schemas and card anatomy for **Location Cards**, **Travel Cards**, and **Clock Cards** in _caRdPG_.

Following our core design precepts, these schemas treat **in-game time as a concrete physical quantity (minutes, hours, days)** rather than abstract card triggers. The digital tabletop uses these structured definitions to automate time passage, evaluate scheduled clock checks, and trigger immediate interrupt draws when noisy or high-risk actions occur.

---

## 1. Architectural Principles

1. **Explicit Time Quotas:** Every exploratory action, movement choice, or physical feat specifies an exact time cost (e.g. `10m`, `45m`, `2h`).
2. **Dual-Trigger Reactivity:**
   - **Scheduled Ticks:** Clock decks advance when cumulative elapsed time crosses defined thresholds (tentatively 30 min in delves, 60 min on trails, 24 h in havens).
   - **Action Interrupts:** Actions bearing specific risk tags (`[Loud]`, `[Exposed]`, `[Flared Torch]`) immediately force an interrupt draw from the designated clock deck, bypassing the timer.
3. **Ergonomic Action Menus:** Location and Travel cards serve as tactile, interactive choice boards where options are organized by the three Colors of Action (Red, Yellow, Blue) alongside standard logistical routines (Search, Rest).

---

## 2. Location Card Schema (Delve & Dungeon Nodes)

A **Location Card** represents a distinct chamber, corridor, or threshold in a delve or indoor structure.

### 2.1 YAML Specification

```yaml
# Schema: Location Card
id: "loc_<zone>_<slug>"
name: "Display Name"
card_type: "Location"
zone: "Upper Works | Lower Cuts | Haven | Wilderness"

# Spatial & Environmental Traits
traversal:
  base_time_minutes: 5 # Time to pass through without searching/obstruction
  lighting: "PitchBlack | Dim | Bright"
  atmosphere: "Clean | Blackdamp | ColdDamp | Smoke"
  tags: ["Chokepoint", "RottedPlanks", "Drafty"]

# Active Clock Engine
governing_clock: "site_activity_clock" # Deck checked for this location

# Obstacles & Interactive Actions
actions:
  - id: "action_slug"
    name: "Action Title"
    category: "Challenge | Exploration | Logistical"
    color: "Red | Yellow | Blue | Neutral"
    strength: 25 # Required strength to meet (if challenge)
    time_cost_minutes: 10 # Elapsed time added to Chronometer
    tags: ["Loud", "Exhausting", "Quiet"] # Tags triggering interrupts or extra fatigue
    narrative: "Narrative description of what the character attempts."
    success:
      narrative: "What occurs upon meeting strength."
      state_change: "UnlockPassage | RevealLoot | SuppressAlert"
    consequence_pool:
      defense_type: "Physical | Stamina"
      tags: ["BluntForce", "Sprain", "NoiseAlert"]

# Standard Logistical Routines
logistics:
  search:
    available: true
    time_cost_minutes: 15
    color: "Blue"
    strength: 15
    tags: ["Quiet"]
    discovery_table: "upper_works_salvage"
  breather_allowed: true # Whether 15-minute rest can be safely attempted here
  unbuckle_safe: false # If false, taking off armor risks ambush without defense
```

### 2.2 Concrete Example: `loc_u1_barricaded_portal.yaml`

```yaml
id: "loc_u1_barricaded_portal"
name: "The Barricaded Portal"
card_type: "Location"
zone: "Upper Works"

traversal:
  base_time_minutes: 5
  lighting: "Dim"
  atmosphere: "ColdDamp"
  tags: ["Chokepoint", "Barricaded", "AlarmWired"]

governing_clock: "site_activity_clock"

actions:
  - id: "sledge_breach"
    name: "Sledgehammer Breach"
    category: "Challenge"
    color: "Red"
    strength: 35
    time_cost_minutes: 1
    tags: ["Loud", "Exhausting"]
    narrative: "Shatter twisted mine rails and timber stakes with heavy sledge blows."
    success:
      narrative: "The barricade collapses forward into splintered kindling. Path is clear."
      state_change: "ClearObstacle"
    interrupt:
      trigger_draw: "site_activity_clock"
      alert_adjacent: ["loc_u2_sorting_yard"]

  - id: "muffled_wire_disarm"
    name: "Muffled Wire Disarming"
    category: "Challenge"
    color: "Yellow"
    strength: 20
    time_cost_minutes: 10
    tags: ["Quiet"]
    narrative: "Delicately snip suspended tin-can tripwires and squeeze through gaps."
    success:
      narrative: "Wires are pinned in silence; the party slips through unnoticed."
      state_change: "ClearObstacleSilent"

  - id: "keystone_shoring"
    name: "Structural Arch Keystoning"
    category: "Challenge"
    color: "Blue"
    strength: 15
    time_cost_minutes: 5
    tags: ["Quiet"]
    narrative: "Identify and dislodge the load-bearing wedge to drop the rails safely."
    success:
      narrative: "The entire barricade swings outward like a gate with zero chime rattle."
      state_change: "ClearObstaclePermanent"

logistics:
  search:
    available: false # Exposed threshold; nothing to search
  breather_allowed: false # Active goblin sightlines
  unbuckle_safe: false
```

---

## 3. Travel Card Schema (Overland Routes & Wilderness Legs)

A **Travel Card** represents an overland trail segment, mountain pass, or wilderness leg between landmarks.

### 3.1 YAML Specification

```yaml
# Schema: Travel Card
id: "trv_<zone>_<slug>"
name: "Display Name"
card_type: "Travel"
zone: "Wilderness"

# Route & Distance Parameters
route:
  from_node: "node_id"
  to_node: "node_id"
  distance_leagues: 1.0
  base_march_time_minutes: 60 # Standard walking pace
  terrain_tags: ["Steep", "LooseScree", "ExposedWind", "Fording"]

governing_clock: "wilderness_clock"

# Travel Paces & Stance Options
paces:
  - id: "steady_march"
    name: "Steady Mountain March"
    time_cost_minutes: 60
    tags: ["StandardPace"]
    narrative: "Keep a measured, cautious footing along the exposed path."
    mechanical_cost: "Effort Cycle flushes if vigilance > 0"

  - id: "fast_scramble"
    name: "Agile Scramble"
    time_cost_minutes: 25
    color: "Yellow"
    strength: 15
    tags: ["Rushed", "Exhausting"]
    narrative: "Power up the shifting slope at a dead run to cut travel time in half."
    success:
      narrative: "You crest the rise in record time without slipping."
    failure_risk:
      consequence_tags: ["BruisedShins", "RattleScreeNoise"]

  - id: "geological_scout"
    name: "Geological Route Scouting"
    time_cost_minutes: 75
    color: "Blue"
    strength: 20
    tags: ["Safe", "TimeConsuming"]
    narrative: "Scout solid granite contours to bypass loose slate washouts."
    success:
      narrative: "The entire party walks across stable ledges; bypasses scree hazards."

logistics:
  cold_camp_allowed: true # Pitching camp triggers immediate Wilderness Clock draw
  forage_available: true
  forage_time_minutes: 45
```

### 3.2 Concrete Example: `trv_w1_low_scree_path.yaml`

```yaml
id: "trv_w1_low_scree_path"
name: "The Low Scree Path"
card_type: "Travel"
zone: "The Jagged Defile"

route:
  from_node: "haven_crow_roost"
  to_node: "wild_timber_cut"
  distance_leagues: 1.5
  base_march_time_minutes: 45
  terrain_tags: ["LooseSlate", "WindBuffeted", "WolfSign"]

governing_clock: "wilderness_clock"

paces:
  - id: "cautious_march"
    name: "Measured Mountain March"
    time_cost_minutes: 45
    tags: ["StandardPace"]
    narrative: "Pick footsteps carefully through loose slate and low brambles."

  - id: "fast_scramble"
    name: "Agile Scree Scramble"
    time_cost_minutes: 20
    color: "Yellow"
    strength: 15
    tags: ["Rushed"]
    narrative: "Sprint up the shale incline before gravel slides gather momentum."
    failure_risk:
      consequence: "Minor Consequence: Bruised Shins"
      interrupt:
        trigger_draw: "wilderness_clock"
        draw_filter: "PredatorAlert"

  - id: "packhorse_haul"
    name: "The Packhorse Anchor Haul"
    time_cost_minutes: 35
    color: "Red"
    strength: 25
    tags: ["Exhausting"]
    narrative: "Drive anchor stakes and muscle companions and heavy packs up the grade."
    success:
      narrative: "All party members ascend without individual checks."

logistics:
  cold_camp_allowed: false # Exposed slope prone to rockslides
  forage_available: true
  forage_time_minutes: 30
  forage_color: "Blue"
  forage_strength: 10 # Willow bark and wound moss along the cut
```

---

## 4. Clock Deck Card Schema (Events, Shifts & Portents)

A **Clock Card** represents an event drawn from a Living Clock Deck (Site Activity, Wilderness, or Macro Haven).

### 4.1 YAML Specification

```yaml
# Schema: Clock Card
id: "clk_<clock>_<slug>"
name: "Event Title"
card_type: "ClockEvent"
clock_deck: "site_activity_clock | wilderness_clock | macro_haven_clock"

category: "EnvironmentalShift | InhabitantAction | Encounter | Portent"
urgency: "Immediate | OngoingModifier | TelegraphedPortent"

# Narrative Presentation
fluff:
  summary: "Brief atmospheric description."
  sensory_cue: "Acoustic / visual / olfactory tell observed by characters."

# World State Mutation
effects:
  - target: "zone | node | player"
    mutation_type: "SpawnEncounter | ModifyHazard | AlterLighting | AdvanceThreat"
    details:
      monster_id: "goblin"
      roster_count: 3
      node_target: "adjacent"
```

### 4.2 Concrete Example: `clk_site_sentry_rotation.yaml`

```yaml
id: "clk_site_sentry_rotation"
name: "Sentry Shift Rotation"
card_type: "ClockEvent"
clock_deck: "site_activity_clock"

category: "InhabitantAction"
urgency: "Immediate"

fluff:
  summary: "Goblin sentries rotate posts across the terraces."
  sensory_cue: "Muffled guttural bickering and the clatter of dropped spears echo along the catwalks."

effects:
  - target: "loc_u1_barricaded_portal"
    mutation_type: "ClearGuard"
    details:
      note: "The barricade portal is now unguarded for the next 20 minutes."
  - target: "loc_u2_sorting_yard"
    mutation_type: "ReinforceGuard"
    details:
      note: "2 additional goblins join the sorting yard watch fire."
```

### 4.3 Concrete Example: `clk_wild_sudden_scree_squall.yaml`

```yaml
id: "clk_wild_sudden_scree_squall"
name: "Sudden Scree Squall"
card_type: "ClockEvent"
clock_deck: "wilderness_clock"

category: "EnvironmentalShift"
urgency: "OngoingModifier"

fluff:
  summary: "Freezing rain and sleet lash down from the upper crags."
  sensory_cue: "The wind shrieks as heavy hail hammers against cloaks and slates."

effects:
  - target: "zone_jagged_defile"
    mutation_type: "ModifyHazard"
    details:
      extinguish_open_flames: true
      terrain_mod: "Slick (+5 Yellow Strength to all footing checks)"
      duration_minutes: 60
```

---

## 5. Visual Card Anatomy (Tabletop & VTT UI)

```
┌────────────────────────────────────────────────────────┐
│ [UPPER WORKS]              THE BARRICADED PORTAL   [5m]│
│ Tags: [Chokepoint] [Drafty] [Alarm-Wired]              │
├────────────────────────────────────────────────────────┤
│ A crude deadfall of twisted mine rails, sharpened     │
│ stakes, and suspended tin cans blocks the rock archway.│
├────────────────────────────────────────────────────────┤
│ ACTIONS & OBSTACLES:                                   │
│                                                        │
│ [RED 35] Sledgehammer Breach                      [1m] │
│   💥 [LOUD] Immediately triggers Site Clock draw!      │
│                                                        │
│ [YEL 20] Muffled Wire Disarm                     [10m] │
│   🤫 [QUIET] Snip tripwires cleanly; preserves surprise│
│                                                        │
│ [BLU 15] Structural Keystoning                    [5m] │
│   🤫 [QUIET] Unseat the wedge; clears doorway silently │
├────────────────────────────────────────────────────────┤
│ LOGISTICS:                                             │
│   • Search: Not available                              │
│   • Breather: Restricted (Active sentry line)          │
└────────────────────────────────────────────────────────┘
```
