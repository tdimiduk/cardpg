# Paradigm Shifts: Onboarding for TTRPG Designers

## Document Purpose

This is a designer-facing document intended for internal use by human designers and AI assistants.

Its purpose is to serve as an onboarding guide for designers who are familiar with common tabletop RPG conventions (e.g., D&D, Pathfinder, standard dice-pool systems). It highlights the core assumptions of _caRdPG_ that differ from mainstream tabletop RPGs, detailing the things one needs to "un-learn" to design and evaluate rules, content, and resolution mechanics effectively within this ruleset.

---

## Core System Assumptions

### DO NOT assume actions have a binary pass/fail outcome.

Actions almost always succeed at their immediate goal. The core mechanical tension does not come from a "roll to hit" or a check against a target number. Instead, the system is built on "Success at a Cost". The central resolution mechanic is determining the _Cost_ of an action (how many cards you expend or flip), which in turn determines the potential _Severity_ of the consequences you risk. True failure is an exceptional outcome dictated by a specific, high-severity Consequence Card or complication, not the default result of a "miss".

### DO NOT treat damage as simple Hit Point loss.

Characters do not have an abstract health pool that just gets depleted. Instead, harm is modeled through two distinct and tangible mechanics:

- **`Status Cards` (e.g., `Fatigue`, `Minor Wound`):** Added directly to a character's deck and discard pile. They represent general exhaustion, pain, and minor wear-and-tear, degrading overall effectiveness by diluting card draws and clogging hands with low-value or zero-stat cards.
- **`Condition Cards` (e.g., `Concussed`, `Arm Injury`, `Rattled Guard`):** Placed on the table in front of the player. They impose persistent mechanical penalties and present distinct tactical challenges with clear, actionable recovery tasks (e.g., rest, first aid, or tactical regrouping) to remove them.

### DO NOT treat death as an instantaneous event from damage.

Player character death is never the direct result of a single attack or card draw. It is the final step in a clearly telegraphed _process_. A character must first be put into a specific, persistent "dying" state (e.g., `Bleeding Out`) by a very high-severity consequence. This state then acts as a timer or a new, desperate objective that the party must work to resolve. This ensures that death is a dramatic, preventable outcome resulting from pushing past clear warning signs, not a sudden, random event.

### DO NOT separate resources from general action-taking.

There are no distinct resource pools like "spell slots," "per-day powers," "stamina bars," or "action points." A character's 24-card deck is their sole and universal resource for everything they do. Every significant action—whether attacking, defending, casting a spell, or performing a feat of exploration—is paid for by expending cards from hand or deck. This mechanic unifies physical stamina, mental focus, and endurance into a single, constantly cycling resource pool.

### DO NOT assume the attacker makes the decisive roll.

The initiating actor (attacker, hazard, or active challenger) sets the difficulty by calculating their action's `Strength`. The resolving actor (defender or task performer) is the active agent in resolving the outcome. The defender commits resources (playing cards from hand, flipping from deck, absorbing through armor) to meet the challenge. The mechanical and narrative focus is on the defender's struggle to endure and mitigate fallout. _(Note: While current canon measures `Impact` via deck flips against `Defense` and `Resilience`, the fundamental invariant is defender agency and resource expenditure, not a single mathematical formula)._

### DO NOT design mechanics solely for physical combat (Avoid Overly Tight Domain Coupling).

The core resolution engine must resolve physical combat, courtroom debates, treacherous climbs, and arcane research using the same universal vocabulary (`Strength`, `Color`, and `Consequences`). While cross-domain friction is natural and expected—getting mentally rattled in a debate can certainly strain your focus, add Fatigue to your deck, or impose tactical conditions in a subsequent brawl—mechanics should **avoid overly tight cross-domain coupling**. Having your consequence track filled with social embarrassment or mockery should not mean that the very first minor sword strike you take in an alleyway immediately escalates into a lethal punctured lung. Escalating trauma in one domain should not blindly trigger catastrophic, lethal outcomes in an unrelated domain.

### DO NOT assume sequential turn-taking.

In Crisis Time, all participants plan and resolve actions simultaneously. The rules operate on a simultaneous Plan step (secretly choosing actions) and a parallel Resolve step. This completely eliminates the classic tabletop bottleneck where players sit idle for 10–15 minutes waiting for their turn to come around in an initiative order. The engine must cleanly adjudicate parallel interactions—such as simultaneous attacks, mutual defenses, and contested maneuvers—without falling back on sequential turn-taking crutches.

### DO NOT assume constant action-taking (The "Pass" as a Core Tactical Decision).

In traditional d20 RPGs, "skipping a turn" is an action-economy catastrophe and a miserable player experience. In _caRdPG_, choosing to **Pass** during the Plan step is a core, intentional piece of tactical gameplay:

- **Why Pass?** Players draw only 2 cards per round. Passing is an active decision driven by tactical calculation:
  - _Powering Up / Banking Cards:_ Many cards carry significant resource costs—action costs frequently reach 4, 5, or higher (e.g., high-tier arcane spells and committed martial strikes). Since you only draw 2 cards per round, unleashing a major strike or complex spell requires deliberately holding back and assembling a substantial hand over multiple rounds.
  - _Defensive Readiness:_ Passing preserves valuable cards in hand specifically for reactive `Defend` actions against anticipated enemy attacks, ensuring you aren't caught flat-footed with an empty hand.
- **The "1 in 3" Cadence Rule of Thumb:** Continuous action on every single round is not the baseline expectation for all combatants; it is the hallmark of a **specific fast archetype** (e.g., relentless swashbucklers, agile skirmishers, or harrying beasts). The **typical baseline cadence** for most combatants and monsters is to **pass at least 1 round in 3**—circling, gathering energy, sizing up an opening, or bracing behind a shield before committing to another strike.
- **Balancing Large Hands:** Hand hoarding is balanced naturally by the systemic risk of **Defensive Collapse** (a depleted draw pile rapidly chaining Fatigue Cycles if forced to flip against an unexpected attack), not by artificial hand-size caps.

### DO NOT equate round count with combat duration (Table Pacing vs. Round Counts).

Designers arriving from mainstream d20 systems (e.g., D&D 5e, Pathfinder) carry an ingrained rule-of-thumb that "balanced, exciting combats should resolve in 3–5 rounds." In those systems, this heuristic is essential: turns are resolved sequentially, with individual player decision paralysis, movement grid measurement, and rules lookups meaning a single round can easily consume 10–20 minutes of table time. In that paradigm, an 8-round combat is an exhausting, multi-hour slog.

In _caRdPG_, this assumption does not apply:

- **Simultaneous Action Eliminates Table Downtime:** Because everyone plans and resolves in parallel, players stay continuously engaged throughout the fight.
- **Rounds are Fast by Design:** A round is designed to execute quickly, scaling directly with the complexity of what was declared:
  - An **"all pass" or low-action round** (circling, sizing up opponents, banking cards) resolves in **well under a minute**—players draw 2 cards, confirm passes or stances, and immediately advance.
  - A round featuring **a couple of minor attacks or defenses** resolves in **a few minutes** via straightforward card flipping.
- **Pacing is Measured in Table Time and Engagement, Not Round Numbers:** Between frequent passing and the fast resolution of minor exchanges, a combat spanning 8, 10, or 12 rounds easily finishes in **10–20 minutes of real-world table time**. If those rounds are brisk, high-tension, and continuously cycling decks, a higher round count is exciting and tactically deep, not a pacing failure.

**Design Implications:**

- **Frame Goals in Real-World Table Time:** State encounter pacing goals in terms of real-world minutes (e.g., "a brisk 5–10 minute skirmish" or "a 20–30 minute climactic set-piece") and player engagement, rather than prescribing an arbitrary round ceiling.
- **Target Friction, Not Round Caps:** When investigating whether combat is dragging, diagnose **table-time friction** (are rules slowing down physical card manipulation? are players bogged down in analysis paralysis?) and **round value** (did this round present interesting choices and shift the tactical state, or was it empty wheel-spinning?), rather than artificially truncating the number of rounds.

### DO NOT assume numerical advancement causes d20-style "level bloat" (Scale Invariance vs. Disjointed Math).

Designers arriving from mainstream d20 systems often carry a justified suspicion of vertical progression. In d20 systems, vertical escalation frequently causes severe mechanical and ludonarrative breakdown because separate mathematical subsystems scale unevenly: hit point pools inflate by 20x to 30x while defenses and saving throws scale far more slowly, transforming high-level combat into protracted damage-sponge attrition slogs that shatter table pacing.

In _caRdPG_, character advancement **explicitly embraces the numerical scaling of cards**. When characters grow in power, the numerical values on their cards increase, their defense thresholds improve, and they tackle higher-magnitude challenges. Crucially, this does not cause d20-style bloat because the core engine is mathematically **scale-invariant**:

- **Proportional Card-Flip Pacing:** Incoming attack `Strength` is met by flipping cards until the required value is matched, with `Impact` measured directly as the _number of cards flipped_. Because card values scale alongside challenge strengths, a low-level duel (`Strength 8` met by single-digit cards of values 2–3) and an epic clash (`Strength 80` met by double-digit cards of values 20–30) both flip approximately 3 cards. Combat rounds remain equally fast, decisive, and tactile across all numerical tiers.
- **Fractal Entity Modeling (Macro-Scale Decks):** The card engine is agnostic to physical scale. A deck is not limited to an individual human; it can represent an individual scoundrel, an elite unit, an entire army, a fortified province, or a kingdom. Giant numbers on macro-scale cards represent the coordinated efforts, pooled manpower, and systemic endurance of thousands of individuals. This allows mass warfare, siege logistics, and realm-level intrigue to be resolved seamlessly using the exact same Crisis Time and General Action procedures as a tavern brawl, without bolting on separate, clunky mass-combat subsystems.

---

## Related Documents

- [Guiding Principles](../philosophy/guiding-principles.md) — The ultimate authority on creative vision, core pillars, and design philosophy.
- [Design Precepts](../philosophy/design-precepts.md) — Concrete design patterns and the "How-To" of system implementation.
- [Core Rules](../rules/core-rules.md) — The baseline player-facing rules.
