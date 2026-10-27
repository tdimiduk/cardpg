---
title: "Design Brief: Movement, Area Control, and Reach Priority in Simultaneous Crisis Time"
doc_type: iteration
track: ludology
origin: AI drafted
epistemic_status:
  confidence: high
  vetted_by_human: false
  vetting_notes: "Grounded in empirical kinematics of movement interception, sports collision dynamics, and Liechtenauer/Fiore fencing treatises."
related_files:
  - "design/rules/core-rules.md"
  - "design/philosophy/design-precepts.md"
  - "design/research/synthesis/movement-interception-and-kinematics.md"
  - "design/research/synthesis/combat-spacing-and-reach.md"
  - "design/research/synthesis/tactical-movement.md"
  - "design/research/theory/readings/temporal-spatial-card-mechanisms.md"
---

# Design Brief: Movement, Area Control, and Reach Priority in Simultaneous Crisis Time

## Purpose of this Working Session Track

To articulate an intuitive, organic model for tactical movement, spatial interception, and area control during 2–3 second Crisis Time rounds. The primary aspiration is to eliminate artificial turn-based mechanics (like D&D's "Attacks of Opportunity" or grid-locked "Zones of Control") by relying on simultaneous declarations, human kinematic limits, and physical reach.

A central open question is whether to permit **Resolution Priority** for specific weapon configurations (such as a _Set Spear_ braced against a charge) without introducing complex initiative or sequencing rules into the core rulebook.

---

## 1. The Factual Bedrock: Kinematics of Interception & Passing

Our research synthesis ([`movement-interception-and-kinematics.md`](file:///home/tdimiduk/cardpg/cardpg/design/research/synthesis/movement-interception-and-kinematics.md)) establishes the physical realities of intercepting a moving body:

### A. The "Reactive Impasse" at Sprint Speed

- **Human Neurological Latency:** Sensory perception (180–240 ms) + choice decision (140–260 ms) + motor programming & electromechanical delay (110–160 ms) yields a pre-movement latency of **370 to 520 ms**. Delivering a stroke adds another 200–350 ms (**Total: 570 to 870 ms**).
- **Transit Velocity:** An 80 kg runner at an explosive sprint travels at **6.5 to 8.5 m/s** (~27 km/h).
- **The Transit Chord:** At a 1.0 m lateral offset, traversing an arming sword's static reach chord (1.81 m) takes **only 241 ms** (333 ms for a longsword).
- **Physical Finding:** A defender who stands static and attempts to _reactively_ strike a sprinting enemy as they enter reach will swing into empty air behind the runner. Reactive interception with a short hand weapon is physically impossible.

### B. Why Sprinters Cannot "Arc Around" Defenders

- **Curvilinear Limits:** Human runners are bounded by ground friction ($\mu \approx 0.6\text{–}1.0$) and lower-limb shear to a maximum centripetal acceleration of **0.8 to 1.2 g** ($7.8\text{–}11.8\text{ m/s}^2$).
- **Minimum Turning Radius:** At $7.5\text{ m/s}$, the sharpest possible turn radius is **$r_{min} \approx 5.74\text{ meters}$**.
- **Tactical Reality:** A sprinting runner **cannot physically curve around a defender at close range (1–2 m)**. Their path is locked in a straight line. Making a sharp 60°–90° cut forces the runner to brake violently, shedding **40% to 55% of forward velocity** and anchoring the plant foot for **340 to 460 ms**, turning the runner into an easy, exposed target.

### C. Impalement, Collision, and Reach

- **Momentum Transfer:** An 80 kg runner at $7.5\text{ m/s}$ carries **$600\text{ kg}\cdot\text{m/s}$ of momentum and $2,250\text{ Joules}$ of kinetic energy**.
- **Body Check Collision:** Intercepting a rusher head-on yields peak collision forces of **8,000 to 14,000 N** (shattering clavicles and ribs), halting both bodies.
- **The Spear Envelope:** A 2.5 m two-handed spear expands the exposure chord at a 1.0 m offset to **4.58 meters** (**611 ms exposure**), which fully encompasses the time required to place a braced point. Soft tissue penetration absorbs $<5\%$ of a sprinter's kinetic energy; an impaled rusher drives themselves up the blade until arrested by bone, crossguard, or spear lugs (_Flügellanze_).

---

## 2. Eliminating "Attacks of Opportunity" in Simultaneous Time

In unilateral turn-based games, "Attacks of Opportunity" exist solely as a patch for the **frozen statue artifact**: Character A moves 30 feet across the room while Character B stands completely paralyzed because it is not their turn.

In CardPG's simultaneous rounds:

1. **No Frozen Statues:** Both actors declare their action during the **Plan Step** and reveal simultaneously.
2. **Anticipation Beats Reaction:** A defender does not wait to be run past; they declare an offensive strike, an interception maneuver, or a defensive brace in the exact same 2.5-second window.
3. **Integrated Movement:** Movement is not a separate move economy; it is the physical vector of your declared action (e.g., _"Sprint 6 meters to engage the archer"_).

---

## 3. The Central Open Question: Reach Priority vs. Pure Simultaneity

Our core precept ([Mandate Simultaneous Action Resolution](file:///home/tdimiduk/cardpg/cardpg/design/philosophy/design-precepts.md#L42-L47)) states that all actions declare and resolve simultaneously. We strictly refuse to introduce initiative rolls, speed tiers, or complex sequencing into the core rules.

However, how do we adjudicate a situation where a spearman braces against a rusher armed with a dagger?

### Candidate Approaches

#### Model A: Pure Simultaneity with Consequence-Driven Momentum Interruption

- **Mechanism:** Both attacks resolve in parallel during the Resolve Step. Both sides calculate Strength, flip cards for Defense, and assign Consequences.
- **How it handles the spear:** The spear's massive reach is reflected in higher Strength, specialized reach traits, or consequence authoring. If the spear inflicts a major Consequence (e.g. `Impaled`, `Knocked Prone`, or `Shattered Ribs`), the rusher's declared action fails **consequence-driven** (per `core-rules.md` Section 4: an action fails when suffered consequences physically break the trajectory of the effort).
- **Pros:** 100% faithful to simultaneous resolution. Zero initiative rules, zero sequencing phases.
- **Cons:** If the rusher also rolls high Strength, they might inflict mutual harm ("double-hit") even if the spear stopped them 2 meters away, which feels counter-intuitive to historical spear tactics unless the rusher closed the measure.

#### Model B: Card-Specific Priority Keywords (`Priority: Braced` / `Priority: Reach`)

- **Mechanism:** The core rulebook maintains pure simultaneity. However, specific defensive Stances or weapon Action Cards (e.g. _Spear Wall: Braced Point_, _Long Pike Stance_) carry a card-specific keyword: **`Priority`**.
- **Rule Text:** _"Trigger (Resolve): If an opponent declares movement into your reach, resolve this attack before incoming melee strikes. If the target suffers a Consequence, their movement is halted at your point and their attack is aborted."_
- **Pros:** Respects the **10x Rule of Core Complexity**—the core rulebook stays pristine and minimal, while the tactical reality of a braced spear lives entirely on the card itself. Matches historical treatises (Fiore's _punta fitta_ / Liechtenauer's _Absetzen_).
- **Cons:** Introduces a conditional interrupt step during resolution that players must resolve before simultaneous reveals.

#### Model C: Proactive Spatial Commitment (`Guard` / `Intercept` Actions)

- **Mechanism:** Rather than an automatic weapon property, area control is a **deliberate action choice**.
- In the Plan Step, a vanguard plays a `Guard` or `Intercept` Action Stack:
  - _"Designate a 3-meter corridor or an adjacent ally. Any enemy declaring movement through this corridor is engaged by you in melee. Both parties resolve against each other."_
- **Pros:** Eliminates all speed/timing arguments. If a runner tries to bypass a guard to hit a backline ally, the guard's declared `Intercept` forcibly redirects the rusher's target to the guard.
- **Cons:** Requires players to dedicate full actions to defensive screening rather than attacking.

---

## 4. The Disengagement Problem: The Empty Tempo

How does a character disengage from melee without an "Attack of Opportunity"?

- **The Physical Reality:** In an active melee (_Krieg_ or _Ringen_), turning one's back to run away presents an unarmored, undefended target.
- **The Solution:** Disengaging is a tactical problem requiring a **Covering Action** (`Shove`, `Beat & Void`, `Fighting Retreat`).
- **Mechanical Rule Proposal:**
  - If Character A declares a disengagement/retreat action, they must play an action stack to create separation.
  - If Character A simply declares a sprint or move away _without_ a covering action, they present an **"Empty Tempo"**: the remaining opponent's declared attack resolves against them with **Defense 0** (or bonus Strength against their exposed back).

---

## 5. Next Steps & Working Hypotheses

- [ ] Prototype and playtest **Model A** (Consequence-Driven Momentum Interruption) vs. **Model B** (Card-Level `Priority` Keyword) in a VTT duel trace.
- [ ] Draft 3 archetype cards for spatial control:
  1. _Spear: Braced Reception_ (Testing the Priority keyword vs. Consequence halt).
  2. _Vanguard: Intercept & Tackle_ (Redirection maneuver).
  3. _Tactical Disengage: Beat & Peel_ (Covering action).
- [ ] Evaluate how multi-combatant movement paths are declared in the VTT without cumbersome grid measuring.
