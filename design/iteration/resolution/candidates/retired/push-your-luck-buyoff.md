---
title: "Post-Mortem: Push Your Luck & Consequence Buy-Off"
doc_type: iteration
track: ludology
status: retired
origin: AI drafted
epistemic_status:
  confidence: high
  vetted_by_human: false
---

# Post-Mortem: Push Your Luck & Consequence Buy-Off

## Status: Retired / Cautionary Note

> **Core Post-Mortem Finding:**
>
> 1. **Per-Flip Halts & Slowdown:** Pausing after every single card flip to evaluate buy-off options destroys the 2–3 second phrase cadence of Crisis Time rounds.
> 2. **Severity Ladder Distortion:** The "+1 Severity bump for free choice" mechanic strained the lean 3-to-4 tier severity ladder, making minor attacks artificially lethal when players attempted tactical steering.

---

## Concept Overview

This exploratory mechanic aims to grant the defender **mid-resolution risk-management agency** during defense by converting incoming `Strength` into an active "push your luck" sequence.

Instead of calculating fractional thresholds upfront, resolution happens sequentially:

1. **Incoming Strike:** Attacker sets `(Strength, Color)`.
2. **Defensive Flips:** The defender flips cards from their deck one by one to meet the Strength. Each flipped card adds to **Impact ($I$)**.
3. **The Mid-Flip Decision Fork:** After each flip, if the incoming Strength is not yet met, the defender chooses between two paths:
   - **Press Your Luck:** Continue flipping cards. If the next flips reveal high-value cards, total Impact remains low and the defender might escape with minor or no consequences. If low values appear (e.g. `Fatigue 1`), Impact skyrockets, exposing the defender to devastating consequence draws.
   - **The Buy-Off (Accepting the Cost):** The defender voluntarily stops flipping and bridges the remaining Strength deficit by **immediately taking a Consequence**.

---

## Mechanical Details & The Buy-Off Tradeoff

### 1. Static Buy-Off Value

The amount of remaining `Strength` absorbed per "buy-off increment" must be governed by a **static character statistic** (e.g., printed on their Nature or Core card based on tier/training, such as 5 Strength at Tier 1 or 15 Strength at Tier 3) rather than a dynamic division calculation, preserving scale invariance and low table math.

### 2. The Trade-Off

Choosing to Buy-Off incurs a **guaranteed severity bump** (e.g., accepting a consequence 1 severity higher than the current calculated impact severity).

In exchange for this higher severity, the defender gains **maximum agency**:

- The defender draws 3+ consequence cards from that higher severity deck.
- The defender **personally chooses** which consequence to suffer (bypassing any attacker curation).
- For example: an unarmored rogue faced with a crushing mace strike can choose to stop flipping and take a guaranteed Tier 2 consequence, deliberately picking `Knocked Prone` or `Winded` over `Cracked Ribs`.

---

## Critical Analysis & Pitfall Audit

| Pitfall / Criterion                                |        Assessment         | Key Tension                                                                                                                                                                                                                                                                      |
| :------------------------------------------------- | :-----------------------: | :------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| **Pitfall 2: False Dilemmas (The Mandatory Fold)** |     ❌ **High Risk**      | Against high-strength attacks, folding into a buy-off can become mathematically mandatory to avoid catastrophic Tier 3/4 outcomes, turning the choice into an illusion.                                                                                                          |
| **Decision Pacing (§3.2)**                         |   ❌ **Severe Failure**   | Violates the core ergonomic rule: _"Avoid requiring a fresh tactical decision on every individual card flip during defense."_ Stopping after every card flip to weigh whether to fold or flip another card dramatically slows Crisis Time rounds.                                |
| **Analysis Paralysis**                             |      ⚠️ **Warning**       | Strongly incentivizes calculating the marginal odds of the remaining deck on each flip before deciding whether to take the buy-off.                                                                                                                                              |
| **Severity Ladder Granularity**                    | ⚠️ **Structural Tension** | A "+1 severity bump" rule is difficult to balance on a lean 3- or 4-tier ladder. In a 3-tier system, a single bump on a moderate hit immediately pushes the defender to Tier 3 (incapacitation), requiring an expanded 5- to 10-tier ladder to accommodate incremental buy-offs. |
| **Scale Invariance**                               |     ✅ **Preserved**      | Using static tier-scaled buy-off values preserves progression math cleanly.                                                                                                                                                                                                      |

---

## Brainstorming Seeds & Next Steps

To make Push Your Luck viable without per-flip procedural drag:

1. **Batch the Decision Point:** Move the "Buy-Off" decision to the end of the flips (post-flip triage) rather than halting after every individual card.
2. **Post-Flip Consequence Selection:** Refactor the core insight—allowing defenders to trade higher severity for personal selection agency—into a clean post-flip curation dynamic (such as _I Cut, You Choose_ or threshold drafting).
