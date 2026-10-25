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

### 1.4. Defender-Centric Resolution & Card-Driven Reactive Mitigation

- **Defender Resolves:** Attacker (or obstacle) sets $(\text{Strength}, \text{Color})$; defender actively expends resources to meet it.
- **Stamina Flips (Impact):** Cards flipped from the deck to meet Strength form a **flipped stack** and generate `Impact` (1 card in the flipped stack = 1 Impact).
- **Card-Driven Reactive Mitigation ("Defend" Actions):** There is no universal "spend arbitrary cards from hand to block" rule. Instead, reactive mitigation lives as printed rules text on specific cards (equipment, skills, maneuvers) played as an [[Action Stack]] (paying their printed `Cost`, which is often 0 for defend cards). Common printed effects include adding the stack's Strength without generating Impact, defending with an alternate Color, or granting conditional dodges/mitigation.

### 1.5. Dual Harm Structure & Non-Instant Death

- **In-Deck Status Cards (`Fatigue`, `Minor Wound`):** Dilute deck efficiency and drag down future draws.
- **On-Table Condition Cards (`Rattled Guard`, `Arm Injury`):** Impose persistent tactical constraints. Fleeting tactical hindrances feature **`Action:`** recoveries (seconds, playable in Crisis Time); physiological trauma features **`Task:`** checks (minutes/hours/days, strictly during Adventuring Time or Downtime).
- **Healing via Transformation:** Downtime gradually transforms severe trauma into manageable fatigue; crisis healing only provides temporary mitigation.
- **No Instant Death (Actionable Crisis Clocks):** Character death is never a sudden single-attack wipe or an arbitrary "Slain" label. Reaching maximum severity inflicts an actionable, persistent "Taken Out / Dying" condition (`Bleeding Out`, `Unconscious`, `Pinned`) that acts as an urgent rescue clock or tactical objective for allies. Note that concrete proposals may vary the exact number of severity tiers (e.g., 3, 4, or 5 tiers), trading off table weight and authoring footprint against granularity and escalation runway; general constraints remain decoupled from a fixed tier integer. Streamlined "narrate dispatching this foe" as the "top severity level" as an option for enemies could be explored, but we should think carefully before applying that to player characters.

### 1.6. Dual Play Modes & Vigilance Lifecycle

- **Crisis Time (Rounds):** High-stakes, simultaneous rounds (Plan Step $\rightarrow$ Resolve Step). Ending Crisis Time discards/expends all cards remaining in hand.
- **Adventuring Time (Vigilance Pool):** Per [core-rules.md](../rules/core-rules.md), players do not hold a hand outside Crisis Time; instead, they maintain a **[[Vigilance]]** pool (0 to 4 face-down cards plus up to 1 face-up readied card), paid for periodically via hourly vigilance cycles. Entering Crisis Time with awareness picks up the Vigilance pool as the starting hand.
- **General Actions & Committing Vigilance:** Fast single-resolution tasks. Mechanics calculate stamina cost and consequences using shared math. On a General Action, a player may optionally pick up their Vigilance pool to either play an applicable reactive/mitigation Action Stack (e.g., a skill or tool modifier) if available or insert high-value cards from hand directly into the flipped stack (counting as flips toward Impact, but with deterministic high values rather than random top-deck draws). The cost for this is expending the cards you pick up, whether or not you use them.

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

### 2.5. Digital-First Playtesting & Physical Ergonomics (The _Gloomhaven_ Standard)

- **Digital Freedom in Active Iteration:** Near-term playtesting occurs primarily in our custom VTT. As with inspirations like _Gloomhaven_, physical tabletop ergonomics is a **"nice to have" rather than a hard blocker** during brainstorming and active exploration. We do **not** prematurely rule out mechanics merely because they would be fiddly at a physical table (e.g., managing multiple consequence decks, tag-based filtering, or dynamic candidate generation).
- **Design Philosophy:** Build and validate the richest, most expressive resolution and escalation engine first in the VTT. Once we observe how the math and psychological choices feel in play, we can explore physical streamlining techniques (e.g., simplifications that retain the empirically valuable properties, multi-tier card layouts with markers, slider sleeves, consolidated decks, or companion apps).
- **Anti-Swing Severity Invariant:** Regardless of medium, the system must maintain telegraphed severity progression and prevent catastrophic RNG spikes (e.g., preventing a fresh hero from suffering a lethal "Punctured Lung" on round 1 from a minor goblin hit).

### 2.6. Attacker vs. Defender Decision Space

- **Baseline vs. Bonus Agency:** Reactive `Defend` cards (played from hand or Vigilance) already provide pre-flip tactical agency when a character holds the right technique or gear. Additional agency built directly into the core consequence resolution loop is a strong **"bonus points"** goal:
  - **Post-Flip Selection ("How I Take the Blow"):** E.g., _"I Cut, You Choose"_ pool curation or defender filtering—choosing which consequence to suffer (trading positional footing or armor wear to avoid a broken rib).
  - **Mid-Resolution Posture/Risk Tradeoffs ("How Hard I Fight It Off"):** Desirable _only_ if the choice is genuinely non-degenerate (avoiding false dilemmas where one branch is always mathematically optimal) and does not incentivize per-flip probability calculation or card counting.
- **Requirement:** Whichever distribution is used, resolution should keep the character at risk emotionally engaged, minimize idle downtime, and avoid "noob traps".

---

## 3. Ergonomics, Content Patterns & Complexity Budget

### 3.1. The 10x Rule of Core Complexity

- **Constraint:** Rulebook complexity costs **10x** card complexity. The core resolution procedure in `core-rules.md` must stay under 1–2 pages (teachable in 2 minutes). Grit, weapon dynamics, reactive defense modifiers, and injury nuances must live on cards.

### 3.2. Cognitive Load & Anti-Analysis Paralysis (Anti-AP)

- **Low-Math Play:** Use intuitive comparisons rather than continuous division tables, fractional matrices, or mid-turn integer partition puzzles (see Pitfall 8 in [resolution-pitfalls.md](resolution-pitfalls.md)).
- **No Card-Counting Incentives:** Avoid mechanics that make calculating exact remaining deck probabilities on every flip the "correct" way to play.
- **Decision Pacing in Flips:** Avoid requiring a fresh tactical decision on every individual card flip during defense (which drags play); keep decision points grouped before flips (reactive cards) or after flips (consequence selection).

### 3.3. Grounded Verisimilitude & Consequence Removal Lifecycle

- **Timescale Reality (1–10 Second Rounds):** Combat rounds represent rapid, split-second action (approx. 1–10 seconds). In-combat recovery via **`Action:`** or "Cards as Fuel" is strictly limited to fleeting tactical adjustments (e.g., standing from prone, resetting broken guard, calming sudden panic, or steadying footing).
- **Trauma Cannot Be Healed Mid-Combat:** Significant physical trauma (cracked ribs, broken limbs, concussions, severe bleeding) cannot be healed or removed during Crisis Time without exceptionally rare, high-cost magic.
- **Action vs. Task Distinction:**
  - **`Action:` (Crisis Time / Seconds):** Instantaneous in-combat tactical adjustments and guard resets.
  - **`Task:` (Adventuring Time / Minutes to Hours):** Non-combat procedures with real duration (field dressings, stabilizing dying allies, repairing sundered shields). Cannot be performed while actively engaged in combat.

### 3.4. Equipment & Metabolic Costs

- **Burden:** Heavy armor adds extra `Fatigue` cards per Fatigue Cycle.
- **Defensive Stats & Reactive Gear:** Armor/traits absorb Impact or mitigate consequence severity, while defensive weapons/shields provide table actions or reactive `Defend` options.

### 3.5. Modular Attack-Printed Stakes vs. Core Universality

- **Modular Enhancement, Not Core Replacement:** Action Cards carrying their own consequence tables (e.g., specific spell effects or boss maneuvers) are great modular tools, but cannot serve as the sole universal engine. Core rules must provide a universal resolution fallback for Narrative Actions, diverse weapon tags, and non-combat tasks without requiring GM fiat.

---

## 4. Multi-Pillar Generality & Bounded Asymmetric Bleed

### 4.1. Universal Application

- The engine must resolve Combat, Social Encounters, Hazards/Exploration, and Downtime using the same vocabulary (`Strength`, `Color`, `Impact`, `Consequences`).

### 4.2. Bounded, Asymmetric Bleed vs. Unified Doom

- Rather than strict domain isolation, caRdPG models **honest, asymmetric cross-domain bleed** while strictly preventing **Unified Doom** (see [traces/README.md](traces/README.md) for the authoritative rubric and verification scenarios):
  - **Unified Doom Avoidance:** Suffering social humiliation, blown cover, or mental strain must **never** directly advance a character's physical lethality track (i.e., it must not pre-fill physical wound capacity or make them fewer sword-blows away from dying in an alley afterward).
  - **Plausible Asymmetric Bleed:** Exerting effort across any domain draws from the shared 24-card stamina deck. Furthermore, conditions bleed across domains where biologically or socially plausible (e.g., a cracked rib heavily penalizes combat mobility and stealthy climbing; a social rebuke shakes composure or imparts hesitation; a neurological migraine impairs fine finesse and rhetoric while leaving raw muscle output functional).

---

## 5. Tactical Dynamics & Anti-Degeneracy

### 5.1. Pacing, Armor Realism, and Tactical Solutions ("Crack the Shell")

- **Mundane Blows vs. Heavy Harness:** It is completely acceptable—and desirable for grounded realism—if a mundane sword swing against a knight in full plate does little more than knock them around (forcing 1–2 stamina flips from their deck with no lasting injury). We do not require artificial "chip damage" on every probing attack against heavy armor.
- **Viable Tactical Pathways (No Pure Hoarding Meta):** However, the system must prevent combat against armored foes from degenerating into a grindy "do nothing and hoard cards for 4 turns to make one massive alpha-strike" meta. Small or normal-sized actions must have viable tactical pathways to create leverage—such as attacking posture/footing (`Knocked Prone`), grappling, sundering/bypassing armor via `Pierce`, setting up tag escalations, or pressuring the target's stamina and hand economy.
- **Telegraphed Spiral:** Defeat must be the culmination of visible escalation, never a surprise one-shot against a fresh character.

### 5.2. Fail Forward (Success at a Cost)

- In General Actions and non-combat tasks, competence is presumed (see [core-rules.md](../rules/core-rules.md)). Mechanics determine the stamina cost and fallout; outright failure is consequence-driven (occurring when suffered consequences dictate that the effort was compromised or aborted).

### 5.3. Consequence Progression Ladders & Escalation Dynamics

- **Anatomical & Physiological Coherence (Avoiding the "Vanishing Wound" Pitfall):**
  - Upgrades and card replacements must strictly preserve verisimilitude. A condition can only upgrade an existing condition if they share the **exact same anatomical locus or systemic state** (e.g., `Bruised Ribs` $\to$ `Cracked Ribs` $\to$ `Punctured Lung`, or `Off-Balance` $\to$ `Knocked Prone`).
  - A blow to the chest causing `Cracked Ribs` must **never** replace or erase an active `Mild Concussion` on the head. If incoming harm targets a new anatomical location, it opens a parallel localized condition rather than overwriting an existing wound.
- **Tier-Count Agnosticism:** While individual proposals may test 3, 4, or 5 severity tiers, the general architecture requires a clear progression from _fleeting tactical friction_ $\to$ _moderate impairment / persistent trauma_ $\to$ _severe structural collapse_ $\to$ _incapacitated / crisis rescue clock_.

---

## 6. Settled Invariants vs. Active Exploration Space

| Dimension                | Settled Invariant (DO NOT Change)                                                                                   | Open Exploration Space (Design Freedom)                                                                            |
| :----------------------- | :------------------------------------------------------------------------------------------------------------------ | :----------------------------------------------------------------------------------------------------------------- |
| **Deck Substrate**       | 24-card deck, tri-color stats on every card, fatigue cycles on exhaustion, Vigilance pool in Adventuring Time.      | Sleeve overlay cards vs. adding fatigue cards (if cycling/collapse math works).                                    |
| **Action Generation**    | Action Stacking (Action Card + Resource Cost stack summing Color + mod; Narrative Actions with GM mod).             | Specific card actions, secondary effects, and modifier ranges.                                                     |
| **Movement**             | Movement integrated into action intent; no separate move economy. Disengagement is a tactical obstacle.             | Positional tags, reach modifiers, or movement bonuses on specific cards.                                           |
| **Round Flow**           | Simultaneous Plan & Resolve steps; Pass/hoard turns cleanly handled.                                                | Timing and resolution sequence of multi-target attacks during Resolve Step.                                        |
| **Harm Anatomy**         | Dual-layer harm: In-deck Status vs. On-table Conditions with Action vs. Task lifecycle.                             | Number of severity tiers (e.g., 3–5), progression ladders, recovery costs, and tag taxonomies.                     |
| **Defeat & Death**       | No instant death; max severity triggers an actionable dying condition/clock (`Bleeding Out`, `Unconscious`).        | Exact severity ladder depth and whether terminal states use physical cards or structured crisis clocks.            |
| **Defender Role**        | Defender flips to meet Strength; reactive `Defend` cards are printed card actions; Vigilance can be committed.      | How Armor/Stats mitigate Impact and whether additional pre- or post-flip defender agency is included.              |
| **Consequence Delivery** | Consequences stem from unmitigated Impact and follow a telegraphed downward spiral without integer-partition traps. | Drafting dynamics ("I Cut, You Choose", threshold drafting, defender filtering, or direct escalation tracks).      |
| **Multi-Attacker Scale** | Dogpiling must not cause degenerate alpha-strike wipes; skirmish play remains fast and entity-centric.              | Round Impact pooling vs. batched pool curation vs. threshold scaling for multiple attackers.                       |
| **Pillar Generality**    | Universal math across Combat, Social, Exploration; bounded asymmetric bleed without Unified Doom.                   | Specialized consequence decks or modular tracks tailored by domain, damage type, or environment.                   |
| **Table vs. Digital**    | Must be playable in our VTT now and streamlined for physical play later.                                            | Multi-deck VTT pools vs. consolidated multi-tier cards, slider tracks, or decoupled post-combat prognosis lookups. |

---

## Summary Evaluation Scorecard

|   #   | Evaluation Dimension                    | Key Question                                                                                                                    |
| :---: | :-------------------------------------- | :------------------------------------------------------------------------------------------------------------------------------ |
| **1** | **Core Rules Footprint (The 10x Rule)** | Does `core-rules.md` stay under 1–2 pages while letting cards carry the verisimilitude and reactive rules?                      |
| **2** | **Action & Vigilance Compatibility**    | Does it cleanly accept incoming `Strength` from Action Stacks, Narrative Actions, and Vigilance commitments?                    |
| **3** | **Pass & Inaction Compatibility**       | Does it cleanly handle turns where a character passes/hoards cards without acting?                                              |
| **4** | **Skirmish & Multi-Target Scalability** | Does it resolve 4 PCs vs. 6 Goblins or 3-on-1 dogpiles without stalling or degenerate wipeouts?                                 |
| **5** | **Bounded Bleed vs. Unified Doom**      | Does it allow honest asymmetric cross-domain friction while preventing non-lethal domains from advancing physical death tracks? |
| **6** | **Armor Realism & Tactical Pathways**   | Does heavy armor realistically shrug off mundane blows while leaving non-hoarding tactical solutions (posture, Pierce, tags)?   |
| **7** | **Defender Agency & Low AP**            | Does the defender make meaningful choices without per-flip probability math or integer-partition noob traps?                    |

---

## Sources Synthesized

- `design/philosophy/guiding-principles.md` (Grounded Heroism, Fail Forward, Modular Design, Health & Recovery)
- `design/philosophy/design-precepts.md` (10x Rule, Differentiate via Math, Simultaneous Resolution, Zero-Stat Cards, Unified Movement, Cards as Fuel, Scale Invariance)
- `design/methodology/paradigm-shifts.md` (Defender-centric resolution, Success at a Cost, Non-HP harm model, Non-instant death, Domain decoupling, Scale invariance)
- `design/rules/core-rules.md` (24-card engine, Tri-Color anatomy, Action Stacking, Fatigue cycles, Crisis vs. General scale, Vigilance pool)
- `design/rules/players-guide.md` (Defensive Collapse dynamics, Tactical hand management)
- `design/rules/gamemaster-guide.md` (Adjudication formulas, Minions via core math, Non-action tactical pacing, Group actions)
- `design/rules/reading-the-cards.md` (Action syntax, Defend mechanics, Task checks)
- `design/iteration/traces/README.md` (Bounded Asymmetric Bleed vs. Unified Doom, friction bands, verification rubrics)
- `design/iteration/resolution-exploration.md` (Critiques of prior mechanics, AP risks, Consequence Pool dynamics)
- `design/iteration/resolution-pitfalls.md` (Systemic anti-patterns, stagnation traps, degenerate defensive choices, combinatorial traps)
- `data/cards/consequences/baseline.yaml` (Dual harm taxonomy: in-deck Status vs on-table Condition Cards with task-removal)
