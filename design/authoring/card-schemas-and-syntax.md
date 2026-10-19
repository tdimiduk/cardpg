---
title: "Authoring Guide: Card Schemas and Mini-DSL Syntax"
doc_type: guide
track: ludology
origin: AI drafted
epistemic_status:
  confidence: medium-low
  vetted_by_human: false
---

# Authoring Guide: Card Schemas and Mini-DSL Syntax

This document is the authoritative technical reference for the data schemas, YAML layouts, and Mini-DSL grammar used to author game cards in **caRdPG**.

While [`locations-and-travel.md`](file:///home/tdimiduk/cardpg/cardpg/design/authoring/locations-and-travel.md) governs exploration nodes and clock decks, this guide covers **Deck Cards (`CoreCard`)**, **Equipment & Items (`ItemCard`)**, **Innate Traits (`NatureCard`, `TalentCard`)**, and **Consequences (`ConsequenceCard`)**.

---

## 1. Architectural Foundations

### Single Source of Truth (SSOT)

The game engine, card compiler, virtual tabletop (VTT), and unit test suites are driven directly by the Haskell data models defined in:

- [`Core.Card`](file:///home/tdimiduk/cardpg/cardpg/core/src/Core/Card.hs): Type definitions for [`CoreCard`](file:///home/tdimiduk/cardpg/cardpg/core/src/Core/Card.hs#L69-L84), [`MasterCard`](file:///home/tdimiduk/cardpg/cardpg/core/src/Core/Card.hs#L204-L218), [`ItemCard`](file:///home/tdimiduk/cardpg/cardpg/core/src/Core/Card.hs#L89-L101), [`NatureCard`](file:///home/tdimiduk/cardpg/cardpg/core/src/Core/Card.hs#L106-L116), [`TalentCard`](file:///home/tdimiduk/cardpg/cardpg/core/src/Core/Card.hs#L121-L132), and [`ConsequenceCard`](file:///home/tdimiduk/cardpg/cardpg/core/src/Core/Card.hs#L173-L184).
- [`Core.Rules`](file:///home/tdimiduk/cardpg/cardpg/core/src/Core/Rules.hs): Parser and layout grammar for card rules text and the Mini-DSL.

All card data files authored under [`data/cards/`](file:///home/tdimiduk/cardpg/cardpg/data/cards/) must strictly deserialize into these Haskell records and validate against their parsers.

### The Card Pipeline

```
  ┌────────────────────────┐
  │  data/cards/**/*.yaml  │  (Authoritative human/agent editable YAML)
  └───────────┬────────────┘
              │ card-compiler / cabal test
              ▼
  ┌────────────────────────┐
  │  generated_cards.json  │  (Validated JSON build artifact)
  └───────────┬────────────┘
              │ consumed by
              ▼
  ┌────────────────────────┐
  │   VTT & Simulation     │  (Reflex UI, Deck Engine, AI Opponents)
  └────────────────────────┘
```

---

## 2. Card Categories & YAML Schemas

### A. Master Deck Cards (`MasterCard` & `CoreCard`)

Master cards are defined in [`data/cards/master/`](file:///home/tdimiduk/cardpg/cardpg/data/cards/master/) (e.g. `martial.yaml`, `arcane.yaml`, `core.yaml`). They represent the catalog of techniques, maneuvers, reactions, and spells available to build player and NPC decks.

```yaml
# Schema: Master Deck Card (data/cards/master/*.yaml)
id: "sunder-armor" # Unique slug identifier
name: "Sunder Armor" # Printed display title
rules_status: "current" # current | outdated | experimental
cost: 1 # Additional cards needed to play an action stack
stats:
  red: 3 # Force / Endurance value
  yellow: 1 # Speed / Agility value
  blue: 1 # Focus / Intellect value
attack: "{Red}: Str = {Red} + 2 [Bludgeon, Sunder] -> Target armor loses 1 Defense this round."
rules:
  - "Passive: +1 {Red} when attacking heavy armor"
tags:
  - "Martial"
  - "Melee"
  - "Weapon"
flavor: "Find the structural seam and drive through with concussive weight."
```

#### Field Specifications:

| Field          | Haskell Type                     | Required | Description                                                                                   |
| :------------- | :------------------------------- | :------: | :-------------------------------------------------------------------------------------------- |
| `id`           | `Text`                           |   Yes    | Kebab-case unique identifier for catalog referencing.                                         |
| `name`         | `NonEmptyText`                   |   Yes    | Human-readable card name.                                                                     |
| `stats`        | `Stats Int`                      |   Yes    | Object containing integer values for `red`, `yellow`, and `blue`.                             |
| `cost`         | `Maybe Int`                      |    No    | Additional hand cards required to play/initiate this card. Omit if 0.                         |
| `attack`       | `Maybe AttackDef`                |    No    | Structured attack formula. See [Section 3: Attack Expressions](#a-attack-expressions-attack). |
| `rules`        | `Maybe [Rule]`                   |    No    | List of Mini-DSL rules (Actions, Tasks, Triggers, Passives, Narrative text).                  |
| `tags`         | `Maybe [Text]`                   |    No    | Tactical and thematic tags (e.g., `["Martial", "Shield"]`).                                   |
| `flavor`       | `Maybe RichText`                 |    No    | Atmospheric flavor text printed in italics.                                                   |
| `rules_status` | `Maybe RulesStatus`              |    No    | `current` (default), `outdated` (needs audit), or `experimental`.                             |
| `milestones`   | `Maybe (Map Text CardMilestone)` |    No    | Upgrade milestones substituting stats, costs, or rules upon advancement.                      |

---

### B. Table Cards: Items & Equipment (`ItemCard`)

Items stay on the table in front of the player (or in pack containers). They provide defense, resilience, burden, and persistent passive traits. Defined in [`data/cards/items/`](file:///home/tdimiduk/cardpg/cardpg/data/cards/items/) or inline under an actor's `items:` block. Defensive fields (`defense`, `resilience`, `burden`) are structured internally in a `DefenseProfile` but serialize as flat top-level YAML keys for authoring ergonomics.

```yaml
# Schema: Item Card (data/cards/items/*.yaml)
name: "Mail Hauberk"
defense: 3 # Defense provided against physical trauma
resilience: 2 # Width of resilience row before condition escalation
burden: 1 # Additional Fatigue cards added per Fatigue Cycle
passive: "Grants Defense 3 against Slash and Puncture. Does not apply against Fatigue or Exertion."
tags:
  - "Equipped"
  - "Armor"
  - "mail"
  - "torso"
flavor: "Interlinked iron rings riveted over a thick padded gambeson."
```

```yaml
# Schema: Consumable Supply Item (data/cards/items/supplies.yaml)
name: "Waterskin"
portions: 3 # Consumable charges/servings
rules:
  - "Drink 1 Portion every 4 hours of active travel, or during a Meal Break."
tags:
  - "Supply"
  - "Water"
```

#### Field Specifications:

| Field        | Haskell Type      | Required | Description                                                                                         |
| :----------- | :---------------- | :------: | :-------------------------------------------------------------------------------------------------- |
| `name`       | `NonEmptyText`    |   Yes    | Item title.                                                                                         |
| `defense`    | `Maybe Int`       |    No    | Damage absorption threshold (cards grouped per completed Consequence; part of `DefenseProfile`).    |
| `resilience` | `Maybe Int`       |    No    | Row capacity for condition severity escalation (part of `DefenseProfile`).                          |
| `burden`     | `Maybe Int`       |    No    | Metabolic load ($2 + \text{Burden}$ Fatigue cards added per cycle; part of `DefenseProfile`).       |
| `portions`   | `Maybe Int`       |    No    | Consumable portions/charges (e.g. food rations, water, fuel).                                       |
| `tags`       | `Maybe [Keyword]` |    No    | Categorical tags and functional keywords (`Equipped`, `Gear`, `Supply`, `weapon`, `cutting`, etc.). |
| `passive`    | `Maybe Text`      |    No    | Static card text detailing domain-specific protections or limitations.                              |
| `rules`      | `Maybe [Rule]`    |    No    | List of Mini-DSL rules or narrative guidelines associated with item usage.                          |
| `flavor`     | `Maybe RichText`  |    No    | Item backstory or sensory description.                                                              |

---

### C. Table Cards: Nature & Talents (`NatureCard` & `TalentCard`)

Innate species attributes, backgrounds, and learned proficiencies:

```yaml
# Schema: Nature Card (data/cards/pc/*.yaml under nature:)
name: "Hardy Mountain Folk"
defense: 1 # Innate baseline defense
resilience: 3 # Innate physiological resilience
passive: "You gain +1 Defense against environmental Cold consequences."
tags:
  - "Nature"
  - "Background"
  - "acclimated-cold"
  - "sure-footed"
```

---

### D. Consequence & Status Cards (`ConsequenceCard` & Status `CoreCard`)

> [!TIP]
> **Canonical Authoring & Portability Guide:** See [Authoring Guide: Consequences and Status Conditions](consequences.md) for detailed clinical calibration, empirical recovery task benchmarks, and guidance on authoring cards that remain portable across resolution iterations.

Harm in _caRdPG_ operates on two distinct card layers:

1. **Status Cards (In Your Deck):** Universal systemic fatigue and trauma that dilute deck density. Defined in [`data/cards/status/core.yaml`](file:///home/tdimiduk/cardpg/cardpg/data/cards/status/core.yaml).
2. **Condition Cards (On the Table):** Tactical penalties and clinical injuries arranged in rows governed by [[Resilience]]. Defined in [`data/cards/consequences/`](file:///home/tdimiduk/cardpg/cardpg/data/cards/consequences/).

#### 1. Status Card (`CoreCard` with zero/low stats):

```yaml
# Canonical: Fatigue (data/cards/status/core.yaml)
- name: "Fatigue"
  flavor: "Fatigue is setting in..."
  stats:
    red: 1
    yellow: 1
    blue: 1
  rules:
    - "Task: Sleep (Time 4 hours) → Remove this card."
  tags:
    - "Status"
    - "Fatigue"
    - "Physical"

# Canonical: Injury (data/cards/status/core.yaml)
- name: "Injury"
  flavor: "A minor injury. The pain is distracting."
  stats:
    red: 0
    yellow: 0
    blue: 0
  rules:
    - "If this card is in your hand at the end of the Resolve Step, expend it."
    - "Task: Rest (Time 1 day) → Remove this card."
  tags:
    - "Status"
    - "Injury"
    - "Physical"
```

#### 2. Condition Card (`ConsequenceCard`):

```yaml
# Schema: Condition Card (data/cards/consequences/exploration.yaml)
- name: "Lead-Heavy Legs"
  severity: 1 # 1 = minor friction, 2 = serious impediment, 3 = critical
  notes: "Delayed onset muscle soreness (DOMS) from eccentric strain during steep descents."
  passive: "When you flip one or more cards during a physical check, add +1 Impact to the resolution."
  rules:
    - "Task: Rest Day (Time 24 hours; Requires Haven) → Remove this"
  tags:
    - "Exploration"
    - "Condition"
    - "Physical"
    - "Exertion"
```

---

## 3. Mini-DSL Grammar & Syntax (`Core.Rules`)

Card rules strings are parsed by [`Core.Rules`](file:///home/tdimiduk/cardpg/cardpg/core/src/Core/Rules.hs). Use standard Unicode arrows (`→`) or ASCII arrows (`->`) interchangeably.

### A. Attack Expressions (`attack:`)

Defined in [`Core.Rules.Attack`](file:///home/tdimiduk/cardpg/cardpg/core/src/Core/Rules/Attack.hs). Used in the `attack:` field of `CoreCard` and `MasterCard`.

$$\text{Format: } \left[\text{Attack }\right]\{\text{ResistedColor}\}\text{: Str = }\{\text{PowerColor}\}\ [\pm\ \text{Mod}]\ [[\text{Tags...}]]\ [\to\ \text{Effect}]$$

```yaml
# Basic attack (matches resisted color)
attack: "{Red}: Str = {Red} + 2"

# Attack targeting defense with consequence tags
attack: "{Red}: Str = {Red} + 3 [Bludgeon, Stun]"

# Finesse attack targeting Red defense using Yellow speed
attack: "{Red}: Str = {Yellow} + 1 [Piercing] → Inflict 1 Bleed on 2+ Impact"

# Explicit Attack keyword syntax (also valid)
attack: "Attack {Yellow}: Str = {Yellow} + 4 [Slash]"
```

---

### B. Tactical Maneuvers (`Action:` / `General:`)

Defined in [`Core.Rules.General`](file:///home/tdimiduk/cardpg/cardpg/core/src/Core/Rules/General.hs). Crisis maneuvers played during combat or active play.

$$\text{Format: } \text{Action: [Name] }[(\text{Spend }\{\text{Color}\}\ X)]\ [\to\ \text{Effect}]$$

```yaml
rules:
  # Action with colored resource expenditure
  - "Action: Push Through (Spend {Red} 10) → Remove this card."

  # Tactical utility maneuver
  - "Action: Feint (Spend {Yellow} 4) → Target's next defense is at -2 Strength."

  # Free maneuver without resource cost
  - "Action: Drop Pack → Jettison backpack; reduce Burden to 0 immediately."
```

---

### C. Narrative & Recovery Tasks (`Task:`)

Defined in [`Core.Rules.Task`](file:///home/tdimiduk/cardpg/cardpg/core/src/Core/Rules/Task.hs). Non-crisis tasks performed during [[Adventuring Time]] or downtime.

> [!IMPORTANT]
> **Strict Task Clause Delimiters:** In `Task:`, clauses (`Check`, `Time`, `Cost`, `Requires`) **must be enclosed in parentheses and separated by semicolons (`;`)**. Multiple preconditions inside `Requires` are separated by commas (`,`). Do not place narrative text inside `Time`.

$$\text{Format: } \text{Task: [Name] (}\left[\text{Check }\{\text{Color}\}\ X\text{;}\right]\ \left[\text{Time }<\text{Duration}>\text{;}\right]\ \left[\text{Cost }<\text{Text}>\text{;}\right]\ \left[\text{Requires }<\text{Requirements}>\right]\text{) } \to\ \text{Effect}$$

```yaml
rules:
  # Timed rest task (no check)
  - "Task: Sleep (Time 4 hours) → Remove this card."

  # Skill check with duration
  - "Task: First Aid (Check {Blue} 6; Time 15 min) → Remove this card."

  # Rest task requiring safe settlement
  - "Task: Rest Day (Time 24 hours; Requires Haven) → Remove this"

  # Clinical care requiring tools and supplies
  - "Task: Rigid Splinting (Check {Blue} 8; Time 30 min; Cost Splint + Bandages) → Remove this"

  # Environmental rewarming combining canonical tags and narrative escape hatch
  - "Task: Active Rewarming (Time 4 hours; Requires Shelter, Campfire, hot broth and blankets) → Remove this"
```

#### Canonical Duration Formatting:

The `Time` clause is parsed strictly into canonical `Duration` units ([`Core.Time`](file:///home/tdimiduk/cardpg/cardpg/core/src/Core/Time.hs)):

- **Minutes:** `5 min`, `15 min`, `30 min`, `45 min`
- **Hours:** `1 hour`, `4 hours`, `8 hours`, `24 hours`
- **Days:** `1 day`, `2 days`, `14 days`

> [!NOTE]
> The engine supports `Minute`, `Hour`, and `Day`. Multi-week durations are written in days (e.g., `14 days`).

#### Environmental & Precondition Requirements (`Requires`):

The `Requires` clause accepts a comma-separated list of preconditions ([`Core.Rules.Task`](file:///home/tdimiduk/cardpg/cardpg/core/src/Core/Rules/Task.hs)):

- **Canonical Engine Tags:** `Haven`, `Campfire`, `Shelter`, `Unburdened` (parsed as machine-readable `RequiredKeyword`).
- **Narrative Escape Hatch:** Any condition not matching an engine tag (e.g., `hot broth and blankets`, `dry clothes`, `complete bed rest`) parses into `RequiredCustom RichText` without parser friction.

---

### D. Triggered Rules (`When`)

Defined in [`Core.Rules.Trigger`](file:///home/tdimiduk/cardpg/cardpg/core/src/Core/Rules/Trigger.hs). Mandatory reactive events that execute when their condition occurs.

$$\text{Format: } \text{When [Trigger] } \to\ \text{[Effect]}$$

```yaml
rules:
  # Removal fallout
  - "When removed → Add 1 Wound to your expended pile"

  # Exertion / trauma fallout
  - "When removed → Add 2 Fatigue to your expended pile"

  # Round-end check
  - "When round ends with enemy engaged → Suffer 1 Fatigue"
```

---

### E. Static Passives (`Passive:`)

Defined in [`Core.Rules.Passive`](file:///home/tdimiduk/cardpg/cardpg/core/src/Core/Rules/Passive.hs). Continuous bonuses or penalties active while the card is in play.

$$\text{Format: } \text{Passive: }[\pm\text{Mod }\{\text{Color}\}]\ [\text{Condition}]$$

```yaml
rules:
  # Combat modifier
  - "Passive: +2 {Red} when attacking"

  # Defensive protection
  - "Passive: +1 {Red} when defending against Physical attacks"

  # Conditioning trait
  - "Passive: +2 {Red} when resisting Exertion and Travel consequences"
```

---

### F. Ongoing Stances & Channels (`Ongoing`)

Defined in [`Core.Rules.Ongoing`](file:///home/tdimiduk/cardpg/cardpg/core/src/Core/Rules/Ongoing.hs). Sustained stances or timed buffs.

$$\text{Format: } \text{Ongoing (Duration or Condition) } \to\ \text{[Effect]}$$

```yaml
rules:
  # Timed stance
  - "Ongoing (1 min) → +1 Strength to all attacks"

  # Equipment-conditional stance
  - "Ongoing (While holding a shield) → You may intercept attacks directed at adjacent allies"
```

---

### G. Freeform Narrative Text (Fallback)

If a rule string does not begin with a recognized keyword (`Attack`, `Action`, `Task`, `When`, `Passive:`, `Ongoing`), the parser treats it as a [`RuleNarrative`](file:///home/tdimiduk/cardpg/cardpg/core/src/Core/Rules.hs#L86-L88).

```yaml
rules:
  - "If this card is in your hand at the end of the Resolve Step, expend it."
  - "You must have attacked last turn to play backswing."
```

---

## 4. Actor Decks & Card Composition

Player Characters ([`data/cards/pc/`](file:///home/tdimiduk/cardpg/cardpg/data/cards/pc/)) and Monsters ([`data/cards/monsters/`](file:///home/tdimiduk/cardpg/cardpg/data/cards/monsters/)) compose decks from the master catalog:

```yaml
# Excerpt: Player Character Manifest (data/cards/pc/shield-fighter.yaml)
name: "shield-fighter"
tags:
  - "pc"

# 24-card starting deck referencing master card IDs
deck:
  - card: "demoralize"
  - card: "conditioning"
  - card: "shielded-stance"
  - card: "sunder-armor"
    stats: # Stat override example
      blue: 3
  - card: "attack"
  - card: "shield-bash"

# Equipped Table Items
items:
  - name: "Battleaxe"
    tags: ["Equipped", "weapon", "cutting", "axe", "heavy weapon"]
  - name: "Light Mail"
    defense: 3
    burden: 1
    tags: ["Equipped", "armored"]

# Innate Characteristics
nature:
  - name: "Hero"
    defense: 2
    resilience: 3
```

---

## 5. Verification & Testing

To ensure authoring consistency and prevent parser drift:

1. **Parser & Schema Tests:** Run `cabal test core` to run the 100+ automated test suite across all card files in [`data/cards/`](file:///home/tdimiduk/cardpg/cardpg/data/cards/) and modules in [`data/modules/`](file:///home/tdimiduk/cardpg/cardpg/data/modules/).
2. **README Examples Test:** [`core/tests/ReadmeExamplesTest.hs`](file:///home/tdimiduk/cardpg/cardpg/core/tests/ReadmeExamplesTest.hs) extracts and parses code snippets to enforce valid DSL grammar.
3. **Index Synchronization:** After creating or moving authoring documents, run:
   ```bash
   cabal run tools-hs:exe:audit-index -- --fix
   ```
