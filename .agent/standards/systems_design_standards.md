# Game Systems Design Standards

This document defines the mathematical, mechanical, and architectural design standards for CardPG. All game systems and rules modifications must align with these standards to maintain structural consistency, mechanical balance, and ludonarrative harmony.

---

## 1. Core Objective

The central goal of CardPG systems design is to ensure that the **mechanically optimal choice aligns with the realistically realistic choice**. Rules and combat mathematics must be grounded in empirical data rather than arbitrary design conventions. For example, if research indicates a physical defense incurs a high metabolic cost, the corresponding game mechanic must reflect a stamina or fatigue penalty rather than a simple dexterity modifier.

---

## 2. Core Design Patterns

All mechanics must adhere to the following architectural patterns. Deviations are permitted only with explicit, documented justification.

### A. Defender-Centric Resolution

- **Definition:** The active player sets the difficulty of an action (representing `Strength` or effort); the **Defender** resolves the outcome and rolls/determines the consequences.
- **Goal:** Shift active agency during defense actions to the player being targeted, enhancing engagement and tactile feel.

### B. Simultaneity of Action

- **Definition:** Mechanics must resolve in parallel rather than through rigid sequential initiative stacks.
- **Goal:** Avoid standard "I go, then you go" gameplay, creating a more realistic flow of crisis time.

### C. Deck as Life (Card Economy)

- **Definition:**
  - **Resources:** Represented by cards in hand and deck.
  - **Immediate Costs:** Paid via card discards (immediate physical or cognitive effort).
  - **Cumulative Costs:** Paid by "polluting the deck" with Fatigue, Wound, or Strain cards, representing long-term attrition.

### D. Success at a Cost

- **Definition:** Avoid binary pass/fail mechanics. Outcomes should focus on the trade-offs of performance: _"What are you willing to pay to succeed?"_ or _"What is the cost of your success?"_

### E. Physicality and Table constraints

- **Definition:** All game systems must be playable on a standard physical table surface.
  - **Hidden Info:** Shuffled decks require identical card backs.
  - **Tracking Overhead:** No complex token tracking. Avoid tracking more than 3 ongoing status tokens per player/NPC.

---

## 3. Key References

1. **Core Rules:** `design/rules/core-rules.md` (Consult for existing mechanical structures)
2. **Guiding Principles:** `design/philosophy/guiding-principles.md` (Pillars and design vision)
