# Resolution System Design Constraints & Evaluation Criteria

## Document Purpose

This document serves as the single, authoritative reference for all architectural constraints, mechanical requirements, tabletop ergonomic realities, and design goals that any proposed **Core Resolution Mechanic** in _caRdPG_ must satisfy.

Whenever a new resolution mechanic or iteration is proposed, it should be evaluated against the criteria detailed below.

---

## 1. Architectural & Substrate Constraints

These are foundational rules of _caRdPG_ that resolution systems must build upon rather than replace.

### 1.1. Cards as Your Character (The 24-Card Engine)

- **Single Resource Substrate:** A character's 24-card deck represents training, immediate focus, and physical/mental endurance. There are no separate resource pools (spell slots, HP, action points).
- **Tri-Color Anatomy:** _Every single card_ in the deck has numerical values for all three Core Colors: `Red` (Force/Endurance/Dominion), `Yellow` (Speed/Precision/Finesse), and `Blue` (Intellect/Planning/Discipline).
- **Strict Deck Economy:** Player deck size and circulation must remain closed and stable. A resolution mechanic must **not** permanently tie up player deck cards as injury markers on enemies or external tableaus (with rare, thematic exceptions for active concentration spells).
- **The Fatigue Cycle:** Running out of cards is a natural fatigue mechanic (add 2 Fatigue cards + Burden to discard, reshuffle). Resolution mechanics must treat mid-action reshuffling as a dramatic moment of near-exhaustion, not an error state.
- **Dead-Card Prevention:** Zero-stat cards (`0/0/0` like `Minor Wound`) must have active mechanics that force them out of hand, ensuring "dead" cards cannot be safely hoarded.

### 1.2. The Defender-Centric Paradigm Shift

- **Attacker Sets Difficulty; Defender Resolves:** Unlike traditional d20/dice RPGs where the attacker rolls to hit, in _caRdPG_ the attacker calculates an action's `Strength`, and the **defender is the active agent in resolving the action**.
- **The Struggle to Endure:** The mechanical spotlight and tension center on the defender's resource expenditure (playing Defend cards from hand, flipping from deck, absorbing through armor, and suffering resulting Impact).

### 1.3. The Dual Harm Structure & Recovery

Harm is modeled through two distinct, tangible layers:

- **Status Cards (In Deck - e.g., `Fatigue`, `Minor Wound`):** General exhaustion and minor pain that degrade deck efficiency and dilute card draws (the cognitive & physical drag of combat).
- **Condition Cards (On Table - e.g., `Rattled Guard`, `Breached Guard`, `Arm Injury`):** Persistent, tactical hurdles on the table that impose clear constraints (e.g., _"Impact of Defense +1"_, _"Must discard a card to attack"_).
- **Actionable Recovery Tasks:** Condition cards have explicit, built-in **Task checks** to mend or remove them (e.g., `Task: Stretch Out [Check Yellow 3; Time 1 min]` or `Task: Hammer Out [Check Red 8; Time 1 hr]`). This creates ludonarrative recovery arcs that bridge combat into downtime.

### 1.4. The Flexible Resolution Scale

- **Universal Duality:** The resolution engine must power both:
  1. **Crisis Time:** High-stakes, turn-by-turn, moment-to-moment tactical play.
  2. **General Actions:** Fast, single-resolution tasks where success is default and the mechanics determine the resource cost.
- **Seamless Shared Math:** The core math of `Strength`, `Defense`, and `Consequences` should operate consistently whether resolving a single lock-pick roll or a 4-round boss battle.

---

## 2. Tabletop Flow & Action Economy

### 2.1. Simultaneous Round Flow in Crisis Time

- **Plan Step:** All participants (players and GM) draw 2 cards and secretly plan their action (or choose to rest/hoard).
- **Resolve Step:** Actions are revealed and resolved simultaneously.
- **Non-Action / Rest Turns Are Core Gameplay:** Characters (both PCs and cunning monsters) will frequently choose _not_ to play an offensive action card on a turn—pausing to catch their breath, hoard cards for a big turn, take cover, or wait for an opening.
  - **Critical Constraint:** A resolution system **must not assume action-vs-action symmetry every turn**. It must cleanly resolve incoming attacks against resting, defending, or unprepared characters without requiring bespoke edge-case rules.

### 2.2. Hand Management & "Defensive Collapse"

- **Hoarding as an Emergent High-Risk Gamble:** Holding a large hand allows players to assemble massive power moves or hold reactive defenses. However, because cards held in hand are _not_ in the draw deck, hoarding dangerously shrinks the active draw pile.
- **Natural Punishment (Defensive Collapse):** If attacked while holding a large hand, a character quickly burns through their tiny draw pile, chaining Fatigue Cycles and rapidly flipping low-value Fatigue cards, causing `Impact` to skyrocket.
- **Design Implication:** The resolution mechanic relies on this core mathematical tension rather than arbitrary hand-size limits.

### 2.3. Multi-Combatant & Skirmish Scalability

- **Skirmish-Ready:** The system must scale effortlessly to asymmetrical encounters:
  - 4 PCs vs. 6 Goblins (mob skirmishes).
  - Multiple attackers dogpiling a single defender in the same round.
  - One area-of-effect attack targeting multiple defenders.
- **No Isolated 1-on-1 Tracks:** Systems relying on pairwise momentum/tug-of-war tracks fail when a third combatant intervenes. Resolution must be entity-centric or scene-wide.

### 2.4. Symmetrical Design

- **Universal Ruleset:** PCs, Bosses, and Minions operate under the same core engine.
- **Minions via Core Math:** Minions/mooks are not a separate exception-based rules class; their fragility is achieved elegantly through low core stats (e.g., `Resilience 0` or `1`, or `Consequence Pool Size 1`).

---

## 3. The Complexity Budget & Physical Ergonomics

### 3.1. The "10x Rule" of Core Rules Presence

- **Rule of Thumb:** Complexity in the core rulebook costs **10x** as much as complexity distributed on specific cards.
- **Core Rules Must Be Featherlight:** The procedure in `core-rules.md` should be minimal, intuitive, and easy to teach in under two minutes.
- **Verisimilitude Lives on the Cards:** Nuance, grit, weapon behaviors, injury recovery timelines, and tactical status effects should live on self-contained cards (Consequence cards, Item/Stance cards, Action cards) rather than extensive rulebook glossaries.

### 3.2. Cognitive Load & Table Pace

- **Intuitive Math over Tables:** Mechanics like _"spend 1 Impact per 1 Severity"_ are instantly grasped at the table. Complex multi-dimensional matrix lookups or continuous fractional divisions create friction.
- **Anti-Analysis Paralysis (AP):** Avoid mechanisms that reward players for actively counting the exact remaining distribution of their 24-card deck or calculating probability curves during mid-turn defensive choices.
- **Physical Reality of Tabletop Play:** Minimize excessive card shuffling, token bookkeeping, or multi-step currency conversions.

### 3.3. Equipment & Metabolic Costs

- **Burden & Encumbrance:** Armor protection must interface cleanly with the physical toll of wearing it:
  - `Burden`: Adds extra `Fatigue` cards per Fatigue Cycle.
  - `Encumbrance`: Causes card discards during strenuous maneuvers.
  - Defensive stats (e.g., `Defense`, `Resilience`, or `Pool Size`) absorb incoming Impact.

---

## 4. Multi-Pillar & Domain Decoupling

### 4.1. True Multi-Pillar Generality

- The resolution mechanic is not just a "combat system with combat tech debt"—it must universally govern:
  - **Combat:** Strikes, parries, armor absorption, battlefield wounds.
  - **Social:** Courtroom debates, interrogation, intimidation, seduction, morale.
  - **Exploration & Hazards:** Climbing treacherous cliffs, navigating blizzards, disarming traps, surviving shipwrecks.
  - **Downtime & Long-Term Endeavors:** Pushing through exhaustion, magical research, crafting.

### 4.2. Domain Decoupling (No Cross-Pillar Contamination)

- **The "Bruised Ego" Problem:** Harm must not act as generic, undifferentiated "Hit Points in disguise."
- Getting embarrassed or losing face in a social debate must impose social/mental friction (e.g., lost composure, reduced Blue dice, loss of influence) **without directly making the character 1-for-1 easier to kill with a dagger in a physical alleyway fight immediately afterward**.

---

## 5. Tactical Dynamics & Anti-Degeneracy

### 5.1. The "Big Attack vs. Small Attack" Balance

- **No "Save for the Knockout" Dominance:** The system must prevent a degenerate meta where the only optimal play is hoarding cards until you can deliver a single, massive knockout blow.
- **Small Actions Must Make Meaningful Progress:** Small attacks, probing strikes, minor adventuring setbacks, and light social jabs must contribute tangible, cumulative value toward victory (e.g., escalating tags, draining enemy guard, applying tactical conditions, opening up vulnerabilities).
- **Telegraphed Downward Spiral:** Defeat or catastrophic trauma should be the dramatic climax of an escalating downward spiral with clear warning shots, never an arbitrary one-shot kill against a fresh character.

### 5.2. Meaningful Defender Agency

- The defender must feel like they are **actively defending themselves**, not just acting as a passive target for an attacker's roll.
- Agency should offer clear tactical trade-offs (e.g., playing Defend cards from hand for zero Impact vs. flipping from deck to save hand cards vs. curating which consequence to suffer).

### 5.3. Default to Success at a Cost (Fail Forward)

- In General Actions and non-combat tasks, the core tension is not _"does it work?"_, but _"what does it cost?"_ Outright failure is an exceptional consequence, not the default baseline.

---

## Summary Evaluation Scorecard

When testing any candidate resolution mechanic, grade it against this 7-point checklist:

| #     | Evaluation Dimension                        | Key Question                                                                              |
| ----- | ------------------------------------------- | ----------------------------------------------------------------------------------------- |
| **1** | **Core Rules Footprint (The 10x Rule)**     | Does `core-rules.md` stay under 1–2 pages while letting cards carry the verisimilitude?   |
| **2** | **Rest & Inaction Compatibility**           | Does it cleanly handle turns where a character rests or hoards cards without acting?      |
| **3** | **Skirmish & Multi-Target Scalability**     | Does it resolve 4 PCs vs. 6 Goblins or 3-on-1 dogpiles without stalling?                  |
| **4** | **Pillar Generality & Domain Decoupling**   | Does it resolve social, hazards, and combat identically without absurd harm bleed?        |
| **5** | **Tactical Pacing (Small vs. Big Actions)** | Do small actions build meaningful momentum/escalation instead of "save for the knockout"? |
| **6** | **Defender Agency & Low AP**                | Does the defender make meaningful, low-math choices without tedious card counting?        |
| **7** | **Physical Table Ergonomics**               | Is it fast, tactile, and intuitive with a fixed 24-card deck and zero card loss?          |

---

## Sources Synthesized

_This document is a self-contained synthesis derived from:_

- `design/philosophy/guiding-principles.md` (Grounded Heroism, Fail Forward, Modular Design, Health & Recovery)
- `design/philosophy/design-precepts.md` (10x Rule, Differentiate via Math, Simultaneous Resolution, Zero-Stat Cards)
- `design/methodology/paradigm-shifts.md` (Defender-centric resolution, Success at a Cost, Non-HP harm model)
- `design/rules/core-rules.md` (24-card engine, Tri-Color anatomy, Fatigue cycles, Crisis vs. General scale)
- `design/rules/players-guide.md` (Defensive Collapse dynamics, Tactical hand management)
- `design/rules/gamemaster-guide.md` (Adjudication formulas, Minions via core math, Non-action tactical pacing)
- `design/iteration/resolution-exploration.md` (Critiques of prior mechanics, AP risks, Consequence Pool dynamics)
- `data/cards/consequences/baseline.yaml` (Dual harm taxonomy: in-deck Status vs on-table Condition Cards with task-removal)
