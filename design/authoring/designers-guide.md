# Designer's Guide: Card Anatomy, Pacing, and Content Engineering

This document is the official technical reference for game designers, module writers, and content creators authoring cards, hazards, encounters, and adventure decks for **caRdPG**.

While [Core Rules](../rules/core-rules.md) defines the foundational player-facing engine and the [Gamemaster's Guide](../rules/gamemaster-guide.md) provides advice for table adjudication, this guide provides the mechanical standards, schemas, mathematical budgets, and pacing conventions required to build balanced, tactile game content.

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
- **10–15 Minutes:** Thorough search of a single room/chamber, picking a standard lock, carefully disarming a mechanical trap.
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
2. **Strict Keyword Usage:** Use recognized keywords (`Passive:`, `Resolve:`, `Reaction:`) defined in the [Keyword Glossary](../rules/keyword-glossary.md).
3. **Color Integrity:** Ensure the card's theme strictly adheres to [Colors of Action](../rules/colors-of-action.md) (Red = force/direct exertion, Yellow = agility/timing/precision, Blue = discipline/wit/perception).

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

Clock cards model escalating threats, wandering patrols, and environmental timers per [Clocks and Fronts](../rules/modules/clocks-and-fronts.md).

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

### A. The Endurance & Vigilance Curve

Every player character operates on a 24-card starting deck. Time translates to card attrition based on chosen readiness:

$$\text{Deck Attrition Rate} = \frac{24}{\text{Cards Expended per Hour}}$$

| Vigilance Stance             | Vigilance Pool Size | Clock Interval | Cards / Hour | Time to 1st Fatigue Cycle (Pure Travel) |
| :--------------------------- | :-----------------: | :------------: | :----------: | :-------------------------------------: |
| **At Ease**                  |       0 cards       |     1 Hour     |   0 cards    |      $\infty$ (No vigilance cost)       |
| **Low Alert**                |       1 card        |     1 Hour     |    1 card    |               24.0 Hours                |
| **Routine Vigilance**        |       2 cards       |     1 Hour     |   2 cards    |               12.0 Hours                |
| **Attentive Patrol**         |       3 cards       |     1 Hour     |   3 cards    |                8.0 Hours                |
| **Adventuring Focus**        |       4 cards       |     1 Hour     |   4 cards    |    6.0 Hours (~3.5–4.5h with checks)    |
| **Redline (Module)**         |       5 cards       |   30 Minutes   |   10 cards   |               ~2.4 Hours                |
| **Hyper-Vigilance (Module)** |       6 cards       |   30 Minutes   |   12 cards   |    2.0 Hours (Sentry / Breach limit)    |

#### Readied Card Math:

Retaining a [[Readied Card]] costs **2 cards off the top of the deck** each time vigilance is paid.

- At Adventuring Focus (1 Readied + 3 Face-Down, hourly): Burns $2 + 3 = 5\text{ cards/hour}$. The deck cycles in **4.8 hours**.
- At Hyper-Vigilance (1 Readied + 5 Face-Down, 30-min): Burns $2 + 5 = 7\text{ cards / 30m}$ ($14\text{ cards/hour}$). The deck cycles in **~1.7 hours**.

---

### B. Fatigue Dilution Mathematics & The Friction Cascade

In _caRdPG_, fatigue does not subtract hit points; it **dilutes card density and escalates impact**. Each [[Fatigue Cycle]] adds $2 + \text{Burden}$ [[Fatigue]] cards (printed values `1/1/1`, no action abilities) into the player's deck.

The table below models progressive deck degradation for an unarmored character (Burden 0, starting deck 24 cards, average stat 3.0):

| Fatigue Cycles Completed | Fatigue Cards in Deck | Total Deck Size | Dead Card Ratio (% of Deck) | Avg Card Stat (Baseline 3.0) | Stat Drop (%) | Action Density (Draw Chance) | 2-Card Hand Compromised Prob |
| :----------------------: | :-------------------: | :-------------: | :-------------------------: | :--------------------------: | :-----------: | :--------------------------: | :--------------------------: |
|      **0 (Fresh)**       |           0           |       24        |            0.0%             |            3.000             |   Baseline    |            100.0%            |           **0.0%**           |
|       **1 Cycle**        |           2           |       26        |            7.7%             |            2.846             |   **-5.1%**   |            92.3%             | **15.1%** (~1 in 6.6 hands)  |
|       **2 Cycles**       |           4           |       28        |            14.3%            |            2.714             |   **-9.5%**   |            85.7%             | **27.5%** (~1 in 3.6 hands)  |
|       **3 Cycles**       |           6           |       30        |            20.0%            |            2.600             |  **-13.3%**   |            80.0%             | **36.6%** (~1 in 2.7 hands)  |
|       **4 Cycles**       |           8           |       32        |            25.0%            |            2.500             |  **-16.7%**   |            75.0%             | **44.4%** (~1 in 2.3 hands)  |

$$\text{Compromised Hand Probability} = 1 - \left( \frac{N_{\text{actions}}}{N_{\text{total}}} \times \frac{N_{\text{actions}} - 1}{N_{\text{total}} - 1} \right)$$

#### The Mechanical Ripple Effects of Dilution:

1. **The Hand Compromise:** At 2 cycles, more than 1 in every 4 Crisis hands contains a dead card, choking out tactical Action Stacks.
2. **Impact Escalation (The Consequence Trap):** When flipping to meet challenge Strength or absorb incoming strikes, flipping a `1/1/1` Fatigue card provides only 1 point of Strength, forcing extra flips. Because every additional flipped card adds to **Impact**, fatigue directly converts into completed Defense stacks and **physical wounds/trauma**.

---

### C. Armor Burden & Compounding Attrition

Armor adds [[Burden]] to each Fatigue Cycle ($2 + \text{Burden}$ Fatigue cards added per cycle). While armored characters pay the same hourly vigilance cost, their deck dilution accelerates drastically once cycling begins:

| Gear Level                | Active Burden | Fatigue Cards per Cycle | Deck Size after 1 Cycle | Deck Size after 2 Cycles | Dead Card Ratio after 2 Cycles |
| :------------------------ | :-----------: | :---------------------: | :---------------------: | :----------------------: | :----------------------------: |
| **Unarmored / Light**     |   Burden 0    |        +2 cards         |  26 cards (7.7% dead)   |  28 cards (14.3% dead)   |    14.3% (~1 in 3.6 hands)     |
| **Mail / Medium**         |   Burden 1    |        +3 cards         |  27 cards (11.1% dead)  |  30 cards (20.0% dead)   |    20.0% (~1 in 2.7 hands)     |
| **Plate Harness / Heavy** |   Burden 2    |        +4 cards         |  28 cards (14.3% dead)  |  32 cards (25.0% dead)   |  **25.0%** (~1 in 2.3 hands)   |
| **Maximum Load / Siege**  |   Burden 3    |        +5 cards         |  29 cards (17.2% dead)  |  34 cards (29.4% dead)   |  **29.4%** (~1 in 2.0 hands)   |

A knight in full plate (Burden 2) who endures 2 Fatigue Cycles suffers a deck that is **25% dead cards**, with a 44.4% chance of drawing dead cards into every 2-card hand. This mathematically reflects the 2.2x metabolic cost of plate harness (Askew et al., 2012) without requiring granular encumbrance math at the table.

---

### D. Standard Strength Budgets for Challenges

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
