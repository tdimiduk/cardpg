# Resolution System Design Constraints & Evaluation Criteria

## Document Purpose

Authoritative reference for architectural constraints, mechanical invariants, tabletop ergonomics, and evaluation criteria for any proposed **Core Resolution Mechanic** in _caRdPG_.

---

## 1. Non-Negotiable Architectural Invariants

Resolution mechanics must build upon these foundational systems without redesigning them.

### 1.1. Single Resource Substrate (The 24-Card Engine)

- **Unified Pool:** A character's 24-card deck is their sole resource for training, focus, and endurance (no separate HP, stamina, or action points).
- **Tri-Color Anatomy:** Every card has numerical stats for all three Colors: `Red` (Force/Presence), `Yellow` (Speed/Finesse), and `Blue` (Intellect/Discipline).
- **Cycling Cost:** Cards held in hand, tableaus, or attachments actively shrink the draw deck, accelerating fatigue. Do not remove cards from circulation as superficial bookkeeping.
- **Fatigue Cycle:** Empty draw pile = add 2 `Fatigue` cards (+ total `Burden`) to discard, then reshuffle. Mid-action reshuffling is normal exertion, not an error.
- **Dead-Card Rule:** Zero-stat cards (`0/0/0` like `Minor Wound`) must have built-in mechanics that force them out of hand (cannot be safely hoarded).

### 1.2. Action Generation & Input Stacking (Immutable Input)

- **The Action Stack:** Attacks and maneuvers are declared by playing an Action Card on top of additional cards from hand equal to its printed **Resource Cost**.
- **Strength Formula:** Action $\text{Strength} = \sum(\text{Color values in stack}) + \text{printed modifier}$.
- **Narrative Actions:** Players without matching cards improvise by paying cards for cost; the GM assigns a modifier benchmarked against printed Action Cards of similar cost.
- **Constraint:** Resolution systems must accept $(\text{Strength}, \text{Color})$ as an external input from this stacking mechanism. Do not replace action generation with single-card flips or dice.

### 1.3. Unified Movement & Tactical Intent

- **Integrated Actions:** Moving, striking, and defending form a single maneuver (no separate movement phases, move actions, or AP budgets).
- **Tactical Disengagement:** Breaking away from an active foe is an obstacle requiring deliberate action choices/costs, never a free default.

### 1.4. Defender-Centric Resolution & Reactive Mitigation

- **Defender Resolves:** Attacker sets $(\text{Strength}, \text{Color})$; defender actively commits resources to meet it.
- **Stamina Flips (Impact):** Cards flipped from deck to meet Strength generate `Impact` (1 flip = 1 Impact).
- **Reactive Hand Mitigation:** Defenders can play `Defend` cards from hand to contribute Color value toward Strength _without_ generating Impact.

### 1.5. Dual Harm Structure & Non-Instant Death

- **In-Deck Status Cards (`Fatigue`, `Minor Wound`):** Dilute deck efficiency and drag down future draws.
- **On-Table Condition Cards (`Rattled Guard`, `Arm Injury`):** Impose persistent tactical constraints. Fleeting tactical hindrances feature **`Action:`** recoveries (seconds, playable in Crisis Time); physiological trauma features **`Task:`** checks (minutes/hours/days, strictly during Adventuring Time or Downtime).
- **Healing via Transformation:** Downtime gradually transforms severe trauma into manageable fatigue; crisis healing only provides temporary mitigation.
- **No Instant Death:** Character death is never a sudden single-attack wipe. Reaching maximum severity inflicts an actionable, persistent "Taken Out / Dying" condition (`Bleeding Out`, `Unconscious`, `Trapped`) that acts as an urgent rescue clock for allies.

### 1.6. Dual Play Modes & Hand Lifecycle

- **Crisis Time (Rounds):** High-stakes, simultaneous rounds (Plan Step $\rightarrow$ Resolve Step). Ending Crisis Time discards/expends all cards remaining in hand.
- **Adventuring Time (Ready Hand):** Players hold a 4-card face-down **Ready Hand** refreshed periodically via **Effort Cycles**. Transitioning to Crisis Time begins by picking up the Ready Hand.
- **General Actions:** Fast single-resolution tasks where success is default and mechanics calculate resource cost/consequences using shared math.

### 1.7. Conflict Conclusion, Dynamic Pacing & Harm Efficacy (Fatigue Alone is Insufficient)

- **Dynamic Pacing Over Arbitrary Round Caps:** The design goal is not an arbitrary round count (e.g., "must end in 3–6 rounds"), but ensuring combat **does not drag**. Turns must remain lightweight, simultaneous, and procedurally crisp; a 7–8 round duel is welcome if rounds are fast, interactive, and dynamic. The system must adapt to narrative stakes and feel decisive when appropriate.
- **Cross-Combat vs. In-Combat Fatigue:** In-deck status dilution and Fatigue Cycles are primarily an endurance tracking mechanism across encounters and during exploration. In an individual skirmish, a combatant will rarely cycle their deck more than once (drawing 2/turn + ~2 flips/turn when attacked = ~6 rounds per 24-card cycle). Furthermore, added Fatigue cards go to discard, having zero immediate effect during that exchange.
- **Immediate Escalation Required:** Because deck flips represent a minor stamina cost ($\sim 1/24\text{th}$ of an endurance cycle) and fatigue cards enter discard, resolution mechanics cannot rely on fatigue alone to close out fights. Successful penetrating attacks must generate on-table tactical constraints, vulnerability tags, or physical trauma that visibly alter the tactical landscape and accelerate resolution.

### 1.8. Scale Invariance & Progression Compatibility

- **Numerical Advancement:** Characters advance cleanly by upgrading the numbers on their cards or adding new cards with higher numbers (e.g., card values scaling from 2–3 up to 5–8+). The resolution engine must remain computationally lightweight and functionally identical without requiring a complex web of other numbers to stay in sync.
- **Fractal Entity Modeling (Macro-Scale Decks):** The core engine must be capable of resolving macro-scale conflicts (an entire army, a fortified keep, or a realm using a 24-card deck with numbers in the 100s or 1,000s) using the exact same core resolution procedure.
- **Card Counts vs. Subtraction:** Mechanics that measure impact or effort through card counts (ratios between incoming strength and card flip counts) preserve scale invariance naturally; mechanics that rely on flat numerical subtractions or hardcoded single-digit thresholds break it.

---

## 2. Tabletop Flow & Action Economy Constraints

### 2.1. Simultaneous Rounds & Inaction Handling

- **Simultaneous Resolution:** All actions in Crisis Time are planned and resolved concurrently.
- **Must Support Rest/Inaction:** Characters often pause to hoard cards, catch their breath, or hold reactive defenses. Resolution mechanics **must cleanly resolve incoming attacks against non-acting or resting defenders** without requiring symmetric action clashes.

### 2.2. Hand Hoarding & Defensive Collapse

- **Emergent Risk:** Large hands assemble powerful turns but leave tiny draw decks.
- **Defensive Collapse:** An attacked character with a large hand quickly exhausts their draw pile, chaining Fatigue Cycles and flipping low-value Fatigue cards (causing `Impact` to skyrocket).
- **Constraint:** Hand size is self-policing through this math; do not add arbitrary hand-size limits.

### 2.3. Multi-Combatant & Dogpiling Scalability

- **Asymmetric Skirmishes:** Must scale cleanly to 4 PCs vs. 6 Goblins, AoE attacks, and multi-attacker dogpiles without isolated 1-on-1 momentum tracks.
- **Dogpiling Balance:** Multi-attacker focus-fire must not multiply lethal consequence steps to fatal extremes (e.g., 4 weak mooks attacking at once must not trigger 4 separate lethal consequence draws on a fresh hero), while avoiding multi-phase resolution bottlenecks that slow table play.

### 2.4. Symmetrical Design

- **Universal Engine:** PCs, Bosses, and Minions share the same core rules. Minion fragility is achieved through stats (e.g., `Resilience 0/1` or `Pool Size 1`), not special-case rules.

### 2.5. Digital-First Playtesting & Physical Ergonomics Freedom

- **Digital Freedom in Active Iteration:** Near-term playtesting will occur primarily in digital tooling. Therefore, we do **not** need to prematurely rule out mechanics merely because they would be unwieldy at a physical table (e.g., managing $6 \times N$ consequence decks, dynamic candidate generation, or deep card pools).
- **Design Philosophy:** Build and validate the richest, most expressive resolution and escalation engine first. Once we observe how the math and psychological choices feel in play, we will explore physical streamlining techniques (e.g., multi-tier card layouts with markers, slider sleeves, consolidated decks, or automated digital companion tools).
- **Anti-Swing Severity Invariant:** Regardless of medium, the system must maintain telegraphed severity progression and prevent catastrophic RNG spikes (e.g., preventing a fresh hero from suffering a lethal "Punctured Lung" on round 1 from a minor goblin hit).

### 2.6. Attacker vs. Defender Decision Space

- **Agency Distribution is Open:** The exact allocation of decisions between attacker and defender is an active exploration space:
  - _"I Cut, You Choose":_ Attacker curates a candidate pool of $N$ cards; defender selects their poison.
  - _Defender-Led Filtering:_ Defender draws candidate cards and uses Armor discards to filter their outcome.
  - _Attacker-Driven Direct Selection:_ Attacker spends Impact directly to choose specific consequences.
- **Requirement:** Whichever distribution is used, resolution must keep the character at risk emotionally engaged, minimize idle downtime for both players, and cleanly define all edge cases (e.g., when $\text{Impact} > \text{Armor Pool}$ vs. $\text{Impact} \le \text{Armor Pool}$).

---

## 3. Ergonomics, Content Patterns & Complexity Budget

### 3.1. The 10x Rule of Core Complexity

- **Constraint:** Rulebook complexity costs **10x** card complexity. The procedure in `core-rules.md` must stay under 1–2 pages (teachable in 2 minutes). Grit, weapon dynamics, and injury nuances must live on cards.

### 3.2. Cognitive Load & Anti-Analysis Paralysis (Anti-AP)

- **Low-Math Tabletop Play:** Use intuitive math (e.g., grouping or 1-for-1 spending) rather than continuous division tables or fractional matrices.
- **No Card-Counting Incentives:** Avoid mechanics that reward calculating exact remaining deck odds or mid-turn probability optimization. Minimize extra token tracking and shuffling.
- **Decision Pacing in Flips:** Avoid requiring a fresh tactical decision on every individual card flip during defense (which drags play); keep decision points grouped or tied to clear milestone triggers.

### 3.3. Grounded Verisimilitude & Consequence Removal Lifecycle

- **Timescale Reality (1–10 Second Rounds):** Combat rounds represent rapid, split-second action (approx. 1–10 seconds). In-combat recovery via **`Action:`** or "Cards as Fuel" is strictly limited to fleeting tactical adjustments (e.g., standing from prone, resetting broken guard, calming sudden panic, or steadying footing).
- **Trauma Cannot Be Healed Mid-Combat:** Significant physical trauma (cracked ribs, broken limbs, concussions, severe bleeding) cannot be healed or removed during Crisis Time without exceptionally rare, high-cost magic.
- **Action vs. Task Distinction:**
  - **`Action:` (Crisis Time / Seconds):** Instantaneous in-combat tactical adjustments and guard resets.
  - **`Task:` (Adventuring Time / Minutes to Hours):** Non-combat procedures with real duration (field dressings, stabilizing dying allies, repairing sundered shields). Cannot be performed while actively engaged in combat.
- **Recovery Hierarchy:**
  - _In-Combat (`Action:`, Seconds):_ Clear tactical positioning tags and fleeting conditions (`Off-Balance`, `Shaken Guard`).
  - _Adventuring Time (`Task:`, Minutes/Hours):_ Field triage to halt worsening dying clocks or convert severe bleeding into bandaged fatigue.
  - _Downtime (Days/Weeks):_ Long-term biological healing transforming severe trauma into manageable deck fatigue.

### 3.4. Equipment & Metabolic Costs

- **Burden:** Heavy armor adds extra `Fatigue` cards per Fatigue Cycle.
- **Defensive Stats:** Armor/traits absorb Impact or mitigate consequence severity.

### 3.5. Modular Attack-Printed Stakes vs. Core Universality

- **Modular Enhancement, Not Core Replacement:** Action Cards carrying their own consequence tables (e.g., specific spell effects or boss maneuvers) are great modular tools, but cannot serve as the sole universal engine. Core rules must provide a universal resolution fallback for Narrative Actions, diverse weapon tags, and non-combat tasks without requiring GM fiat.

### 3.6. Inherent Tag Chaining vs. Mid-Draw Candidate Searches

- **Physical Card Reality:** Double-sided cards cannot function in randomized draw decks.
- **Tabletop Tag Chaining:** Tag escalation is best handled through inherent card upgrade triggers (e.g., _"If you take another Fear consequence, upgrade this to Terrified"_) or table condition state changes, rather than candidate-pool search mechanics during resolution.

### 3.7. Reactive Hand Defense via Equipment & Specialized Cards

- **Equipment-Gated Hand Defense:** Universal "defend from hand" creates card-hoarding and feel-bad resource spending. However, allowing _Defend from Hand + Flip to Finish_ as a specific mechanical benefit of gear (e.g., Shields, Parrying Daggers) or specialized `Defend` cards provides rich tactical design space without warping baseline play.

---

## 4. Multi-Pillar Generality & Domain Decoupling

### 4.1. Universal Application

- The engine must resolve Combat, Social Encounters, Hazards/Exploration, and Downtime using the same vocabulary (`Strength`, `Color`, `Impact`, `Consequences`).

### 4.2. Domain Decoupling (No Harm Bleed)

- Harm must not act as generic HP. Suffering social embarrassment or lost composure must impose social/mental friction **without making the character 1-for-1 easier to kill with a physical dagger immediately afterward**.

---

## 5. Tactical Dynamics & Anti-Degeneracy

### 5.1. Pacing: Small vs. Big Actions

- **No Knockout Meta:** Prevent strategies where the only viable move is hoarding for a single massive strike. Small/probing attacks must build tangible progress (escalating tags, draining guard, applying tactical conditions).
- **Telegraphed Spiral:** Defeat must be the culmination of visible escalation, never a surprise one-shot against a fresh character.

### 5.2. Fail Forward (Success at a Cost)

- In General Actions and non-combat tasks, success is the baseline assumption. Mechanics determine the stamina cost and fallout; outright failure is an exceptional result from specific high-severity cards.

### 5.3. Consequence Progression Ladders & Escalation Dynamics

- **Anatomical & Physiological Coherence (Avoiding the "Vanishing Wound" Pitfall):**
  - Upgrades and card replacements must strictly preserve verisimilitude. A condition can only upgrade an existing condition if they share the **exact same anatomical locus or systemic state**.
  - _Pitfall to Avoid:_ A blow to the chest causing `Cracked Ribs` must **never** replace or erase an active `Mild Concussion` on the head. A character does not stop being concussed because their ribs broke.
  - If incoming harm targets a new anatomical location, it opens a parallel localized condition rather than overwriting an existing wound.
- **Harm Ladders by Type:**
  - _Systemic & Tactical States (Continuous Escalation):_
    - _Position / Guard:_ `Off-Balance` $\to$ `Knocked Prone` $\to$ `Pinned` $\to$ `Helpless`
    - _Fear / Morale:_ `Uneasy` $\to$ `Afraid` $\to$ `Terrified` $\to$ `Panicked Fleeing` $\to$ `Catatonic / Broken`
  - _Localized Anatomical Trauma (Site-Specific Escalation):_
    - _Head / Neurological:_ `Rattled Helm` $\to$ `Mild Concussion` $\to$ `Severe TBI` $\to$ `Traumatic Coma / Unconscious`
    - _Thoracic / Ribs:_ `Bruised Ribs` $\to$ `Cracked Ribs` $\to$ `Flail Chest / Punctured Lung` $\to$ `Tension Pneumothorax`
    - _Limb / Arm:_ `Strained Arm` $\to$ `Dislocated Shoulder` $\to$ `Fractured Forearm` $\to$ `Severed / Mangled Limb`
- **Differing Escalation Dynamics (Tissue vs. Tactical):**
  - Tactical/positional states escalate smoothly with consecutive pressure.
  - Tissue trauma and bleeding may accumulate as discrete injuries or volume rather than small scratches magically morphing into severed arteries; severe vascular trauma is typically the result of direct heavy piercing/slashing strikes or specific targeted maneuvers.
- **Physical vs. Digital Delivery:** In digital play, condition upgrading and parallel card state management is completely frictionless. For physical play, design space includes multi-tier cards with tracking clips/markers, slider sleeves, or direct deck swaps.

---

## 6. Settled Invariants vs. Active Exploration Space

| Dimension                  | Settled Invariant (DO NOT Change)                                                                            | Open Exploration Space (Design Freedom)                                                                            |
| :------------------------- | :----------------------------------------------------------------------------------------------------------- | :----------------------------------------------------------------------------------------------------------------- |
| **Deck Substrate**         | 24-card deck, tri-color stats on every card, fatigue cycles on exhaustion.                                   | Sleeve overlay cards vs. adding fatigue cards (if cycling/collapse math works).                                    |
| **Action Generation**      | Action Stacking (Action Card + Resource Cost stack summing Color + mod; Narrative Actions with GM mod).      | Specific card actions, secondary effects, and modifier ranges.                                                     |
| **Movement**               | Movement integrated into action intent; no separate move economy. Disengagement is a tactical obstacle.      | Positional tags, reach modifiers, or movement bonuses on specific cards.                                           |
| **Round Flow**             | Simultaneous Plan & Resolve steps; Rest/hoard turns cleanly handled.                                         | Timing and resolution sequence of multi-target attacks during Resolve Step.                                        |
| **Harm Anatomy**           | Dual-layer harm: In-deck Status vs. On-table Conditions with Action vs Task lifecycle.                       | Progression ladders, specific condition mechanics, recovery costs, and tag taxonomies.                             |
| **Defeat & Death**         | No instant death; max severity triggers an actionable dying condition/clock (`Bleeding Out`, `Unconscious`). | Exact severity ladder depth (settled 4-tier model: 3 physical/impairment tiers + Tier 4 Taken Out).                |
| **Defender Role**          | Defender is active agent; deck flips = stamina cost; Defend cards from hand mitigate flips.                  | Specific math of how Armor/Stats mitigate Impact (`Defense`/`Resilience` vs. `Pool Size` $N$ vs. Declared Effort). |
| **Consequence Delivery**   | Consequences stem from unmitigated Impact and follow a telegraphed downward spiral.                          | Drafting dynamics ("I Cut, You Choose" pool curation, defender filtering, or direct spend).                        |
| **Multi-Attacker Scale**   | Dogpiling must not cause degenerate alpha-strike wipes; skirmish play remains fast and entity-centric.       | Round Impact pooling vs. grouped defense vs. threshold scaling for multiple attackers.                             |
| **Pillar Generality**      | Universal math across Combat, Social, Exploration; domain decoupling prevents harm bleed.                    | Specialized consequence decks tailored by domain, damage type, or environment.                                     |
| **Harm Attrition Pace**    | In-deck Fatigue alone cannot close fights; on-table tactical/physiological escalation is required.           | Condition progression ladders vs. tag escalation vs. threshold consequence tracks across domains.                  |
| **Deck Footprint & Tiers** | Balance severity progression vs. table deck count; prevent 1-hit lethal spikes against fresh targets.        | 4-tier model vs. digital card pools vs. multi-threshold cards vs. consolidated single decks.                       |

---

## Summary Evaluation Scorecard

|   #   | Evaluation Dimension                        | Key Question                                                                                         |
| :---: | :------------------------------------------ | :--------------------------------------------------------------------------------------------------- |
| **1** | **Core Rules Footprint (The 10x Rule)**     | Does `core-rules.md` stay under 1–2 pages while letting cards carry the verisimilitude?              |
| **2** | **Action Stacking & Input Compatibility**   | Does it cleanly accept incoming `Strength` from Action Card + Resource stacks and Narrative Actions? |
| **3** | **Rest & Inaction Compatibility**           | Does it cleanly handle turns where a character rests or hoards cards without acting?                 |
| **4** | **Skirmish & Multi-Target Scalability**     | Does it resolve 4 PCs vs. 6 Goblins or 3-on-1 dogpiles without stalling or degenerate wipeouts?      |
| **5** | **Pillar Generality & Domain Decoupling**   | Does it resolve social, hazards, and combat identically without absurd harm bleed?                   |
| **6** | **Tactical Pacing (Small vs. Big Actions)** | Do small actions build meaningful momentum/escalation instead of "save for the knockout"?            |
| **7** | **Defender Agency & Low AP**                | Does the defender make meaningful, low-math choices without tedious card counting?                   |
| **8** | **Non-Instant Death & Recovery Arcs**       | Does max severity trigger an actionable dying condition/clock rather than an instant kill?           |

---

## Sources Synthesized

- `design/philosophy/guiding-principles.md` (Grounded Heroism, Fail Forward, Modular Design, Health & Recovery)
- `design/philosophy/design-precepts.md` (10x Rule, Differentiate via Math, Simultaneous Resolution, Zero-Stat Cards, Unified Movement, Cards as Fuel, Scale Invariance)
- `design/methodology/paradigm-shifts.md` (Defender-centric resolution, Success at a Cost, Non-HP harm model, Non-instant death, Domain decoupling, Scale invariance)
- `design/rules/core-rules.md` (24-card engine, Tri-Color anatomy, Action Stacking, Fatigue cycles, Crisis vs. General scale, Ready Hand)
- `design/rules/players-guide.md` (Defensive Collapse dynamics, Tactical hand management)
- `design/rules/gamemaster-guide.md` (Adjudication formulas, Minions via core math, Non-action tactical pacing, Group actions)
- `design/rules/reading-the-cards.md` (Action syntax, Defend mechanics, Task checks)
- `design/iteration/resolution-exploration.md` (Critiques of prior mechanics, AP risks, Consequence Pool dynamics)
- `design/iteration/resolution-pitfalls.md` (Systemic anti-patterns, stagnation traps, degenerate defensive choices, combinatorial traps)
- `data/cards/consequences/baseline.yaml` (Dual harm taxonomy: in-deck Status vs on-table Condition Cards with task-removal)
