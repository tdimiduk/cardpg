---
title: "Post-Mortem: Standalone Tag Escalation"
doc_type: iteration
track: ludology
status: retired
origin: AI drafted
epistemic_status:
  confidence: high
  vetted_by_human: false
---

# Post-Mortem: Standalone Tag Escalation

## Status: Retired / Non-Viable

This document records the design evaluation and retirement of the **Standalone Tag Escalation** proposal (formerly exploring tag-based harm progression using canon $\lfloor \text{Impact} / \text{Defense} \rfloor$ division and single-card draws without a consequence drafting pool).

---

## Executive Summary

> **Core Finding:** Simplifications of tag escalation designed to avoid extended card drawing and drafting curation all fall into **extreme variance issues** (unpredictable lethality spikes on one end, and tedious combat drag on the other).
>
> The Consequence Pool and _"I Cut, You Choose"_ drafting market from the [mature proposal](../consequence-pool-tag-escalation/proposal.md) are not extraneous bloat; they are the **necessary stabilizing governor** that makes tag-based anatomical escalation mathematically and tactically viable.

---

## 1. The Core Failure Mode: Extreme Variance

Under standalone tag escalation (inflicting 1 consequence at a time by drawing from a shuffled consequence deck):

1. **Decoupled RNG:** The physical consequence deck distributes leaf tags (`[head]`, `[torso]`, `[limbs]`, `[positioning]`, `[bleeding]`, `[exertion]`) randomly. Tag matching is governed by a Coupon Collector / Birthday Problem random walk rather than player tactics or strike magnitude.
2. **Wild Bimodal Pacing:**
   - **Lethality Spikes (Sudden Death):** If consecutive random draws hit matching tags, a fresh character can spike into terminal severity and be Taken Out in just **2–3 hits** from minor attacks.
   - **Combat Drag (Stagnation):** If random draws scatter across different tags, a combatant can accumulate **10–14+ parallel consequences** at lower tiers without escalating toward a climax, dragging combat out indefinitely.
3. **Impact Magnitude Inversion:** A massive blow ($\text{Impact } 8$) and a minor scrape ($\text{Impact } 2$) both enter play at Tier 1. A heavy blow only reaches higher severity if the multiple drawn cards happen to randomly share a tag.

---

## 2. Why Lightweight Patches Failed

Every attempt to patch standalone tag escalation without adopting the drafting pool triggered an established design pitfall:

| Attempted Tweak                                    | Intended Fix           | Fatal Failure Mode                                                                                                                                                                                                                                             |
| :------------------------------------------------- | :--------------------- | :------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| **Capacity Caps** (Max 2 Tier 1 slots)             | Stop high-end drag     | **Resurrects Unified Doom** ([Pitfall 7](../../pitfalls.md#pitfall-7-pseudo-hit-points-the-linear-attrition-trap)): A social or environmental setback in a full slot forces a minor physical scrape to escalate into serious trauma.                           |
| **Broad Vulnerabilities on Tier 2**                | Stop high-end drag     | **Worsens Lethality Spikes**: Once a character suffers any Tier 2 setback, exposing 3–4 vulnerable tags makes almost any follow-up strike trigger instant defeat.                                                                                              |
| **Pacing Floors** (Need 2 conditions for terminal) | Stop early spikes      | **Breaks Minion Scaling** ([Pitfall 13](../../pitfalls.md#pitfall-13-flat-soak--top-end-collapse-the-2--8--12-curve-failure)): Fresh minions or weak monsters can structurally never be one-shot by heavy hits. For PCs, it merely delays the spike by 1 turn. |
| **Attacker Weapon Leaf Tags**                      | Eliminate deck RNG     | **Mono-Tag Tunnel-Vision Meta**: Players sculpt decks to hit a single tag (`[head]`), turning combat into a degenerate race to spam the same attack 4 times.                                                                                                   |
| **Impact Bands with Defender Choice**              | Tie severity to Impact | **Alpha-Strike Hoarding** ([History §1.3](../../history.md#13-legacy-mechanic-allowed-severity-tables)): Defenders pick parallel Tier 1s to stall out small hits, making small attacks feel useless and forcing players to hoard for single massive strikes.   |

---

## 3. Design Takeaway & Path Forward

The mature Consequence Pool proposal works because its two mechanics counterbalance each other:

- **Defender Choice ("You Choose")** dampens the lower bound, preventing premature spikes on glancing hits.
- **Attacker Curation ("I Cut") + Vulnerability Draws** dampens the upper bound, accelerating fights toward a decisive conclusion once blood is drawn.
- **Pool Size ($N$)** provides symmetrical minion modeling ($N=1$ minions drop in one heavy hit; $N=2+$ PCs survive).

### Directive:

Do not attempt to strip the drafting engine out of tag escalation. Instead, future optimization should focus on **streamlining the ergonomics of the Consequence Pool** (e.g., capping draw volume at $\le 3\text{ cards}$ and simplifying GM curation math) rather than running tag matching standalone.
