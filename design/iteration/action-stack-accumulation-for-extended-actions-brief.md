---
title: "Design Brief: Action Stack Accumulation for Extended Actions"
doc_type: iteration
track: ludology
origin: AI drafted
epistemic_status:
  confidence: high
  vetted_by_human: false
  vetting_notes: "Proposes an authoring framework for multi-round Crisis Time actions via progressive Action Stack accumulation, strictly respecting the 10x Rule of Core Complexity."
related_files:
  - "design/rules/core-rules.md"
  - "design/philosophy/design-precepts.md"
  - "design/authoring/card-schemas-and-syntax.md"
  - "design/iteration/crisis-round-duration-and-phrase-cadence-brief.md"
  - "design/research/theory/readings/temporal-spatial-card-mechanisms.md"
---

# Design Brief: Action Stack Accumulation for Extended Actions

## Purpose of this Working Session Track

To establish an authoring framework and rules standard for **Extended Actions** during Crisis Time. In a 2 to 3 second round, actions that require 4 to 15 seconds of physical effort (aiming a 130-lb warbow, spanning a heavy windlass crossbow, applying an emergency tourniquet, or channeling a spell) realistically span **2 to 5 rounds**.

This brief designs a **zero-token, card-native mechanic** based on **Action Stack Accumulation**, leveraging CardPG's existing Action Stack architecture without adding procedural tracking clutter.

---

## 1. Core Concept: Accumulation vs. Depletion

Earlier proposals explored countdown depletion (putting cards down upfront and discarding one per turn) or rotational card clocks. However, **Action Stack Accumulation** is far simpler and more intuitive:

```
Round 1 (Plan)         Round 2 (Plan)            Round 3 (Resolve)
+---------------+      +---------------+         +---------------+
| Action Card   |      | Action Card   |         | Action Card   |
+---------------+  ->  +---------------+   ->    +---------------+
  | [Card 1]    |        | [Card 1]    |           | [Card 1]    |
  +-------------+        +-------------+           +-------------+
                           | [Card 2]  |             | [Card 2]  |
                           +-----------+             +-----------+
                                                       | [Card 3]  |
                                                       +-----------+
                                                      ==> UNLEASH!
```

### Why Accumulation is Architecturally Superior

1. **Leverages Core Rules:** In `core-rules.md`, an [[Action Stack]] consists of 1 Action card on top plus additional cards from hand equal to its printed [[Cost]]. Accumulation simply allows a player to build this exact stack **across consecutive Plan Steps** rather than all at once.
2. **Zero External Tokens:** There are no counters, dice, or tracking sheets to bump or forget. The physical thickness of the card stack on the table directly displays progress.
3. **Natural Stamina Lock ("Sunk Effort"):** Every card tucked into an ongoing stack is physically locked on the table and unavailable for other plays. This organically models that drawing a heavy warbow or holding pressure on an arterial bleed ties up hands and mental focus.
4. **Adheres to the 10x Rule:** The core rulebook needs only one sentence explaining that high-cost actions can be fed across rounds. All specific nuances live on the Action Cards themselves.

---

## 2. Table Procedures & Mechanical Rules

### Step 1: Initiation (Plan Step, Round 1)

- The player plays the extended Action Card face up into their **Active Zone**.
- The player commits at least 1 card from hand beneath it to start the stack.
- While the stack is incomplete, the card remains active on the table. The character is considered **Occupied** (hands full, maintaining physical effort).

### Step 2: Accumulating (Plan Step, Round 2+)

- At the start of each subsequent round, the player draws their normal 2 round cards.
- In the Plan Step, the player commits additional cards from hand into the stack.
- **Cadence Agency:** Because the player draws 2 cards per round, they control their tactical pacing:
  - _Cautious Cadence:_ Commit 1 card to the stack and retain 1 card in hand for reactive defense.
  - _All-In Cadence:_ Commit both drawn cards to the stack to complete it faster, leaving hand empty if attacked.

### Step 3: Execution (Resolve Step, Completion Round)

- When the total supporting cards in the stack meet or exceed the required [[Cost]], the stack is complete!
- During that round's **Resolve Step**, the action reveals and unleashes its full Strength and special effects simultaneously with all other table actions.
- In the Cleanup Step, the entire stack (Action Card + supporting cards) is discarded to the expended pile as normal.

---

## 3. Handling Interruption: The Right to Abort

Combat is unpredictable. What happens if an enemy charges while a character has 2 cards committed to an unfinished warbow shot?

Players retain clear tactical agency through two options:

### Option A: Endure (Hold the Line)

- The player refuses to break concentration. The incomplete stack remains on the table.
- If attacked, the character cannot play a Defend Action Stack from hand (their hands and focus are occupied). They must face the attack using **innate Defense and blind deck flips**.
- **Failure Consequence:** If the character suffers a **Severity 2+ Consequence** (e.g. `Knocked Prone`, `Broken Wrist`, `Staggered`), their focus is shattered: the action is **Aborted** and all committed cards are discarded.

### Option B: Abort (Break and Defend)

- During the Plan Step, the player voluntarily abandons the unfinished stack.
- All cards in the stack are swept directly to the expended pile (the physical effort is spent).
- The player is now free to use their current hand to play a standard [[Defend]] Action Stack or evade.

---

## 4. Card Authoring Syntax & Archetype Examples

To author extended actions, cards can use the existing `Cost: X` field paired with the keyword `Extended: X` (or rules text specifying multi-round accumulation).

### Archetype 1: Military Warbow (Heavy Ranged Strike)

```yaml
name: "Military Warbow: Deliberate Aim"
color_strengths: { red: 3, yellow: 4, blue: 1 }
cost: 2
type: "Crisis Action"
keywords: ["Attack", "Ranged", "Extended"]
rules_text: >
  Extended: Accumulate up to 2 supporting cards across Plan Steps.
  While active, you cannot take Melee actions or sprint.
  Resolve (When Full): Unleash an aimed shot. Strength = {Yellow} + 5 (Piercing).
  If you suffer a Severity 2+ Consequence while accumulating, this stack is Aborted.
```

### Archetype 2: Heavy Crossbow (Mechanical Reload)

```yaml
name: "Heavy Crossbow: Span Windlass"
color_strengths: { red: 4, yellow: 2, blue: 2 }
cost: 3
type: "Crisis Action / Maneuver"
keywords: ["Maneuver", "Mechanical", "Extended"]
rules_text: >
  Extended: Accumulate up to 3 supporting cards across Plan Steps.
  Resolve (When Full): Your Heavy Crossbow is Spanned and Readied.
  Draw 1 card to hand. This card remains face up as your Readied Weapon.
```

### Archetype 3: Field Medicine (Emergency Hemostasis)

```yaml
name: "Emergency Hemostasis"
color_strengths: { red: 2, yellow: 2, blue: 4 }
cost: 2
type: "Crisis Action / Technical"
keywords: ["Technical", "Medical", "Extended"]
rules_text: >
  Target an adjacent ally with an active [Bleeding] Condition.
  Extended: Accumulate up to 2 supporting cards across Plan Steps.
  Resolve (When Full): Downgrade the target's [Severe Bleed] to [Bandaged Wound].
  You may voluntarily Abort this card during any Plan Step to defend freely.
```

### Archetype 4: Cooperative Accumulation (Assisted Tasks)

```yaml
name: "Siege Ram: Coordinated Surge"
color_strengths: { red: 5, yellow: 1, blue: 2 }
cost: 4
type: "Crisis Action / Teamwork"
keywords: ["Teamwork", "Extended"]
rules_text: >
  Extended: Accumulate up to 4 supporting cards.
  Cooperative: Adjacent allies may commit cards from their own hand to this stack during the Plan Step.
  Resolve (When Full): Strike the fortified barrier. Strength = {Red} + 12 (Demolition).
```

---

## 5. Next Steps & Open Questions

1. **Assisted Effort:** Should cooperative actions allow multiple characters to feed cards into the same central stack (as modeled in Archetype 4)?
2. **Partial Progress Value:** Should aborting certain non-binary tasks (like picking a complex lock under fire) preserve partial progress via a condition card, or is effort fully lost?
3. **Card Schema Validation:** Update `design/authoring/card-schemas-and-syntax.md` to formally document `Extended` syntax and validation rules.
