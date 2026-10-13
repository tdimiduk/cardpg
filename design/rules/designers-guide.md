# Designer's Guide: Card Anatomy, Pacing, and Content Engineering

This document is the official technical reference for game designers, module writers, and content creators authoring cards, hazards, encounters, and adventure decks for **caRdPG**.

While [Core Rules](core-rules.md) defines the foundational player-facing engine and the [Gamemaster's Guide](gamemaster-guide.md) provides advice for table adjudication, this guide provides the mechanical standards, schemas, mathematical budgets, and pacing conventions required to build balanced, tactile game content.

---

## 1. The Core Currency: Unified In-Game Time

In _caRdPG_, physical stamina and narrative progress are governed by a single unified resource: **in-game time**. Outside of [[Crisis Time]], time is tracked through pacing intervals (nominally 1 hour) where characters pay for vigilance.

### A. The 60-Minute Exploration Engine

The player deck (baseline 24 cards) acts as the party's expedition clock:

- At peak vigilance ([[Vigilance]] pool size 4), a character flushes 4 cards into their expended pile every hour.
- A 24-card deck cycles in **6 hours** at high vigilance, injecting $2 + \text{Burden}$ [[Fatigue]] cards into the deck.
- At ease (Vigilance 0), a character flushes 0 cards per hour, burning zero deck stamina.

Because cards committed to the [[Vigilance]] pool flush every hour, **time directly translates to stamina attrition for vigilant adventurers**.

### B. "Hard Going" vs. "Acute Perils"

When authoring Location, Travel, and Hazard cards, distinguish between continuous physical strain and sudden traumatic shocks:

| Category                            | Design Meaning                                                        | Card Implementation                                                                                          | Why It Matters                                                                                                                                                                                                 |
| :---------------------------------- | :-------------------------------------------------------------------- | :----------------------------------------------------------------------------------------------------------- | :------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| **Hard Going (Arduous Conditions)** | Strenuous terrain, poor weather, heavy obstacles, or slow navigation. | **Consumes In-Game Time** (`time_cost: 15m`, `time_cost: 30m`, or `Double Travel Time`).                     | Advances the narrative clock. Torches burn, daylight wanes, and characters pay for vigilance naturally. Vigilant characters pay for their readiness in card loss; relaxed characters pay in time and exposure. |
| **Acute Perils (Sudden Shocks)**    | Traps, cave-ins, ambushes, toxic gas, or sudden flash floods.         | **Direct Consequences or General Action** (`Flip Red 12 or suffer 2 Impact`, `Discard 2 cards to expended`). | Inflicts immediate, sharp damage that tests reflexes or forces instant deck attrition regardless of current vigilance posture.                                                                                 |

> [!IMPORTANT]
> **Avoid arbitrary flat card taxes for rough terrain.** Do not write _"Swamp: Each player discards 2 cards from deck."_ Doing so bypasses the player's deliberate risk/reward choice with their Vigilance Dial. Write `Swamp: Travel takes 45 minutes.`

### C. Standard Time Cost Benchmarks

When attaching time costs to cards, obstacles, and exploration tasks, use these standard increments:

- **5–10 Minutes:** Rapid sweep, traversing an unobstructed corridor, glancing at murals, quick barrier vault.
- **10–15 Minutes:** Thorough search of a single room/chamber, picking a standard lock, carefully disarming a mechanical trap, taking [[The Breather]].
- **30 Minutes:** Forcing open a collapsed portcullis, excavating rubble, deep research in a library stack, deciphering ancient script.
- **60 Minutes:** Ascending a steep mountain pass, enduring a punishing blizzard crossing, or an exhaustive search of a multi-room dungeon wing.

---

## 2. Card Anatomy & Content Schemas

All cards in _caRdPG_ are designed to be printed on standard playing-card sized stock and must follow consistent structural schemas.

### A. Action Cards (Player & NPC Decks)

Action cards represent active maneuvers, stances, and tactical techniques played during [[Crisis Time]] or committed during [[General Actions]].

```yaml
title: "Heavy Shield Bash"
type: "Attack" # Attack | Defend | Stance | Utility
color: "Red" # Red (Force/Vigor) | Yellow (Grace/Finesse) | Blue (Focus/Will)
value: 3 # Baseline numerical value in declared Color
resource_cost: 1 # Number of additional cards from hand required to pay cost
modifier: "+2 Strength" # Printed action modifier
rules_text: "Target suffers Staggered on 3+ Impact."
tags: ["Bludgeon", "Shield", "Melee"]
```

#### Authoring Rules for Action Cards:

1. **The 10x Rule:** Action text must fit within 2–3 lines of physical card text. Complexity belongs in tactical hand combinations, not wall-of-text card rules.
2. **Strict Keyword Usage:** Use recognized keywords (`Passive:`, `Resolve:`, `Reaction:`) defined in the [Keyword Glossary](keyword-glossary.md).
3. **Color Integrity:** Ensure the card's theme strictly adheres to [Colors of Action](colors-of-action.md) (Red = force/direct exertion, Yellow = agility/timing/precision, Blue = discipline/wit/perception).

---

### B. Location Cards (Adventuring Time)

Location cards represent physical rooms, wilderness hexes, landmarks, or dungeon chambers. They define the environment and provide interactive choice nodes.

```yaml
title: "Submerged Sluice Gate"
deck: "Dungeon - Sunken Bastion"
tags: ["Subterranean", "Flooded", "Chokepoint"]
time_cost: "15m" # In-game exploration time elapsed

environment_text: >
  Waist-deep brackish water fills the stone conduit. A rusted iron gate 
  blocks forward progress; debris has wedged into the winch gears.

obstacles:
  - name: "Force the Winch"
    type: "General Action"
    color: "Red"
    strength: 14
    consequence_pool: "Exploration Exhaustion"
    rules_text: "Clearing the winch opens the dry overflow passage."

  - name: "Dive Beneath the Gate"
    type: "General Action"
    color: "Yellow"
    strength: 10
    time_cost: "5m"
    rules_text: "Squeeze through silted gaps. Suffer Cold Exposure on 2+ Impact."

exits:
  - "Chamber of Cisterns"
  - "Flooded Vault"
```

---

### C. Clock & Front Cards (Campaign & Dynamic Pressures)

Clock cards model escalating threats, wandering patrols, and environmental timers per [Clocks and Fronts](modules/clocks-and-fronts.md).

```yaml
title: "The Scent of Blood"
front: "The Warren Goblins"
clock_trigger: "Advance Goblin Alert Clock by 1 Tick"
rules_text: >
  If the Goblin Alert Clock reaches 4 Ticks, shuffle the 'Goblin Ambush' 
  Encounter Card into the top 3 cards of the active Location Deck.
flavor_text: "Chittering echoes through the ventilation shafts."
```

---

### D. Consequence Cards (Harm & Complications)

Consequence cards represent the physical, mental, and logistical fallout of exceeding [[Defense]] and [[Resilience]].

- **Status Cards (In Your Deck):** Represent systemic attrition (`Fatigue`, `Minor Wound`, `Shaken`). They enter the expended pile and dilute future draws with low values.
- **Condition Cards (On the Table):** Represent acute tactical penalties (`Sprained Ankle`, `Pinned`, `Bleeding`). They sit face up on the table until resolved.

```yaml
title: "Exhausted Muscles"
type: "Status"
harm_category: "Fatigue"
deck_color: "Red 0"
rules_text: "When flipped during a physical check, adds 0 Strength and +1 Impact."
flavor_text: "Your arms tremble under the weight of your weapon."
```

---

## 3. Deck Mathematics & Attrition Budgets

When designing encounter suites or custom campaigns, adhere to these mathematical baselines:

### A. The 24-Card Endurance Curve

Every player character operates on a 24-card starting deck. Assuming hourly pacing:

$$\text{Deck Attrition Rate} = \frac{24}{\text{Vigilance Level}}$$

- **Vigilance 4:** Cycles deck every **6 hours** (4 cards/hour).
- **Vigilance 3:** Cycles deck every **8 hours** (3 cards/hour).
- **Vigilance 2:** Cycles deck every **12 hours** (2 cards/hour).
- **Vigilance 1:** Cycles deck every **24 hours** (1 card/hour).
- **Vigilance 0:** Infinite endurance (0 cards/hour).

#### Readied Card Math:

Retaining a [[Readied Card]] costs **2 cards off the top of the deck** each time vigilance is paid.
A character maintaining 1 Readied Card + 3 Face-Down cards burns $2 + 3 = 5\text{ cards/hour}$. Their deck will cycle in approximately **4.8 hours**. Ensure encounters provide natural pauses where players feel safe letting their vigilance down.

### B. Standard Strength Budgets for Challenges

When assigning [[Strength]] values to obstacles and general actions:

| Tier            | Typical Strength | Narrative Scale                                                                                 |    Expected Deck Flips (Casual Attempt)    |
| :-------------- | :--------------: | :---------------------------------------------------------------------------------------------- | :----------------------------------------: |
| **Routine**     |    **6 – 8**     | Picking a simple lock, scaling a dry wall, intimidating a nervous guard.                        |          1 – 2 flips (0–1 Impact)          |
| **Challenging** |   **12 – 16**    | Forcing a jammed portcullis, leaping a chasm, holding ground against a torrent.                 |          3 – 5 flips (1–3 Impact)          |
| **Formidable**  |   **20 – 26**    | Swimming through a freezing current, disarming an ancient runic engine, resisting venom.        |          5 – 8 flips (3–5 Impact)          |
| **Extreme**     |     **30+**      | Surviving a collapsing cavern roof, withstanding dragon fear, lifting an iron portcullis alone. | 8+ flips (Severe Impact / Deck Starvation) |

---

## 4. Design Tenets for Card Authors

1. **Defender-Centric Action Drafting:**
   - Never write cards that say _"The GM flips cards to attack you."_ The challenge sets the static [[Strength]] and [[Color]]; the targeted player flips, spends, and decides how to mitigate consequences.
2. **Success at a Cost:**
   - Avoid binary pass/fail triggers outside of explicit life-or-death saving checks. If an obstacle has a high Strength, meeting it flips cards and causes [[Impact]]. Success happens; the card's job is to extract the realistic physical price.
3. **Casual Realism:**
   - Ground all card text in cause-and-effect plausibility. Cross-reference injury timelines, armor weights, and physical exertion rates against the synthesis papers in `design/research/synthesis/`.
