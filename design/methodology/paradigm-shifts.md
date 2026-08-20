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

### DO NOT assume sequential turn-taking or constant action-taking.

In Crisis Time, all participants plan and resolve actions simultaneously. The rules must cleanly resolve incoming attacks against characters who choose to rest, hoard cards, take cover, or hold reactive defenses without requiring ad-hoc edge cases. Hand hoarding is balanced naturally by the systemic risk of **Defensive Collapse** (a depleted draw pile rapidly chaining Fatigue Cycles), not by artificial hand-size caps.

---

## Related Documents

- [Guiding Principles](../philosophy/guiding-principles.md) — The ultimate authority on creative vision, core pillars, and design philosophy.
- [Design Precepts](../philosophy/design-precepts.md) — Concrete design patterns and the "How-To" of system implementation.
- [Resolution System Design Constraints](../iteration/resolution-design-constraints.md) — The master scorecard and technical constraints for evaluating resolution mechanics.
- [Core Resolution Mechanic Exploration](../iteration/resolution-exploration.md) — Active critique and ongoing exploration of resolution alternatives.
- [Core Rules](../rules/core-rules.md) — The baseline player-facing rules.
