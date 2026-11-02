---
title: "Resolution Mechanics: Discarded Ideas Clearinghouse"
doc_type: iteration
track: ludology
origin: AI drafted
epistemic_status:
  confidence: high
  vetted_by_human: false
---

# Resolution Mechanics: Discarded Ideas Clearinghouse

## Document Purpose

The **one-stop clearinghouse** for resolution mechanics, candidate proposals, and brainstorming concepts that look attractive on the surface but failed under closer mathematical, cognitive, or table analysis.

Before designing or prototyping a new resolution mechanic, scan this catalog to verify whether the concept has already been explored and what fatal failure modes emerged.

> [!TIP]
> **Contributing to this clearinghouse:** Keep entries lightweight and scannable:
>
> 1. **The Pitch (1–2 sentences):** What was the idea, and what problem was it trying to solve?
> 2. **The Fatal Flaw (1–2 sentences):** Why did it fail or break down?
> 3. **Deep Dive / Source:** Link to a full post-mortem in `candidates/retired/` or `history.md`, or state `Surface inspection only`.

---

## 1. Consequence & Card Architecture

### 1.1. Cards Printed with All Severity Levels (Pip Escalation)

- **The Pitch:** Print Tiers 1–3 on every consequence card and track escalation in-place with a pip marker/cube (e.g. _Shaken_ $\to$ _Afraid_ $\to$ _Terrified_) to eliminate mid-combat deck tutoring and shrink table footprint to 1 deck.
- **The Fatal Flaw:** Becomes too text-heavy, strips nuance to fit card layouts, and forces an unnatural 3-tier escalation chain onto consequences that do not naturally possess three meaningful levels of severity.
- **Deep Dive:** [candidates/retired/consolidated-tiered-cards-and-triage.md](candidates/retired/consolidated-tiered-cards-and-triage.md)

### 1.2. Standalone Tag Escalation (Without Drafting Pool)

- **The Pitch:** Keep canon division ($\lfloor I / D \rfloor$) and draw single consequence cards whose matching leaf tags escalate active conditions, eliminating global Resilience and drafting pools.
- **The Fatal Flaw:** Bimodal variance failure: coupon-collector RNG either triggers sudden lethality spikes (PCs dying in 2–3 minor hits) or extreme combat drag (accumulating 10–14 parallel low-tier conditions without climax).
- **Deep Dive:** [candidates/retired/tag-escalation-resilience.md](candidates/retired/tag-escalation-resilience.md)

### 1.3. Impact Bands with Defender Choice

- **The Pitch:** Let defender choose any consequence up to an Impact tier band ($I=1\text{--}2$ Tier 1, $I=3\text{--}4$ Tier 2) to eliminate card drafting.
- **The Fatal Flaw:** Reintroduces Alpha-Strike Hoarding ([Pitfall 3](pitfalls.md#pitfall-3-the-hoard-for-the-alpha-strike-trap-lack-of-tactical-solutions-to-heavy-defense)). Defenders always select parallel Tier 1s to stall out moderate hits, making small attacks feel useless and forcing attackers to hoard for single massive strikes.
- **Deep Dive:** [candidates/retired/tag-escalation-resilience.md §2](candidates/retired/tag-escalation-resilience.md#2-why-lightweight-patches-failed)

### 1.4. Attacker Weapon Leaf Tags (Mono-Tag Targeting)

- **The Pitch:** Eliminate consequence deck RNG by giving weapons fixed leaf tags (e.g. Daggers inflict `[head]`, Warhammers inflict `[armor]`).
- **The Fatal Flaw:** Creates a degenerate mono-tag tunnel-vision meta where players sculpt decks to spam the exact same weapon attack 4 times in a row for guaranteed terminal escalation.
- **Deep Dive:** [candidates/retired/tag-escalation-resilience.md §2](candidates/retired/tag-escalation-resilience.md#2-why-lightweight-patches-failed)

### 1.5. Remainder Mechanics & Fixed 2-Card Curation Pools

- **The Pitch:** Cap consequence draws at $\le 2$ cards and let leftover Impact remainders ($I \pmod D$) or fixed brackets determine curation agency (attacker vs. defender choice) or stamina spillover, eliminating high-volume card drawing.
- **The Fatal Flaw:** Triggers the 2-card escalation catch-22 (attacker curation + tag upgrades bypasses armor width into instant-kill spikes, while defender choice renders tag upgrades a solved false dilemma), mathematical interval collapse at low Defense ($D \le 3$), and breaks swarm merging.
- **Deep Dive:** [candidates/retired/incremental-impact-mechanics.md](candidates/retired/incremental-impact-mechanics.md)

---

## 2. Defense Flip & Pre-Impact Agency

### 2.1. Declared Defense Effort (Upfront Commitment)

- **The Pitch:** The defender observes incoming `(Strength, Color)` and declares upfront exactly how many cards ($K$) they commit to flipping from their deck to meet the Strength.
- **The Fatal Flaw:** Grinds fast Crisis Time to an absolute halt with card-counting analysis paralysis as players calculate deck ratios; uncapped declarations also risk total combat stagnation.
- **Deep Dive:** [candidates/retired/declared-defense-effort.md](candidates/retired/declared-defense-effort.md)

### 2.2. Push Your Luck & Consequence Buy-Off

- **The Pitch:** Defenders flip sequentially one card at a time and can halt at any moment to buy off remaining Strength with a consequence (+1 Severity bump for free choice).
- **The Fatal Flaw:** Halting after every single card flip destroys the 2–3 second phrase cadence of Crisis Time rounds. Couldn't find a buy off option that didn't end up an "always pick" against larger attacks.
- **Deep Dive:** [candidates/retired/push-your-luck-buyoff.md](candidates/retired/push-your-luck-buyoff.md)

---

## 3. Historical Engine Generations (Playtested & Superseded)

### 3.1. Defend from Hand (Fractional Thresholds)

- **The Pitch:** Armor grants 1–2 deck flips; defenders then spend cards from hand to meet incoming attack Strength ($100\%$ = no effect, $50\%$ = minor, $25\%$ = major).
- **The Fatal Flaw:** Severe feel-bad action denial (spending attack cards just to survive), monsters get stun-locked into perpetual defense, and combats become unclosable because card draw easily maintains the $25\%$ survival threshold.
- **Deep Dive:** [history.md §1.2](history.md#12-legacy-mechanic-defend-from-hand-fractional-thresholds)

### 3.2. Allowed Severity Tables

- **The Pitch:** Armor provides a lookup table mapping Impact counts to allowed severity tiers; attackers draw candidate cards and pick one no higher than allowed.
- **The Fatal Flaw:** Heavy rulebook bloat, intense table clutter with multiple decks, and theoretical alpha-strike flaw where delivering low-tier consequences feels worthless.
- **Deep Dive:** [history.md §1.3](history.md#13-legacy-mechanic-allowed-severity-tables)

### 3.3. Flat Divisor Defense + Resilience Rows (Canon Baseline)

- **The Pitch:** Group flips into buckets of size `Defense` ($1\text{ consequence} = \lfloor I / D \rfloor$); place consequences in rows of width `Resilience` to advance tiers.
- **The Fatal Flaw:** Reintroduces **Unified Doom** (social setbacks advance physical trauma tracks), operates as pseudo-HP in disguise ([Pitfall 7](pitfalls.md#pitfall-7-pseudo-hit-points-the-linear-attrition-trap)), and features low tactical interactivity on defense.
- **Deep Dive:** [history.md §1.1](history.md#11-current-canon-defense--resilience)
