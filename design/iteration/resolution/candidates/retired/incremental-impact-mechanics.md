---
title: "Post-Mortem: Remainder & Capped-Draw Incremental Impact"
doc_type: iteration
track: ludology
status: retired
origin: AI drafted
epistemic_status:
  confidence: high
  vetted_by_human: false
---

# Post-Mortem: Remainder & Capped-Draw Incremental Impact

## Status: Retired / Non-Viable

This document records the design evaluation and retirement of the **Remainder & Capped-Draw Incremental Impact** mechanics (formerly exploring ways to make incremental Impact matter without drawing one card per Impact).

---

## Executive Summary

> **Core Finding:** While capping draw volume at $\le 2$ or 3 cards and replacing $1\text{ Impact} = 1\text{ Card Drawn}$ with remainder modulo math ($R = I \pmod D$), stamina spillover, or fixed 2-card pools appears ergonomically appealing, every variant triggers severe mathematical anomalies, false dilemmas, or breaks core combat balancing.
>
> In the mature Consequence Pool engine, $1\text{ Impact} = 1\text{ Card Drawn}$ is not redundant card bloat; it functions as an elegant **physical analog state computer** that simultaneously governs soak thresholds, intra-tier curation, multi-attacker swarm merging, and consequence escalation width without division, modulo calculations, or special-case exception rules.

---

## 1. The Five Candidate Architectures Explored

The exploration evaluated five distinct architectures aimed at keeping physical draw volume to $\le 2$ cards while making every point of Impact mechanically relevant:

### Candidate A: Remainder Shifts Curation Agency (The "Agency Tug-of-War")

- **Mechanism:** When $I \ge D$, draw at most 2 cards from the appropriate Severity deck. The remainder $R = I \pmod D$ determines agency:
  - $R = 0$: Draw 2; Defender chooses 1 ("Rolling with the blow").
  - $R = 1$: Draw 1; Suffered directly.
  - $R \ge 2$: Draw 2; Attacker curates 1 ("Aimed strike").
  - $R \ge 3$: Attacker curates 1 of 2, plus inflicts 1 `Fatigue` directly into the defender's discard pile.

### Candidate B: Remainder as Stamina & Posture Spillover

- **Mechanism:** Penetrating hits ($I \ge D$) draw exactly 1 Consequence card. Leftover remainder $R$ drains stamina:
  - $1 \le R < D/2$: Defender discards 1 card from top of deck to expended pile.
  - $R \ge D/2$: Defender chooses between tucking/expending 1 card from hand OR adding 1 `Fatigue` card to discard.

### Candidate C: Impact as Tactical Maneuver Currency

- **Mechanism:** $I \ge D$ inflicts 1 Consequence card. Any leftover Impact points ($R = I - D$) are spent from a martial maneuver menu (1 Impact = Shove / Off-Balance; 2 Impact = Disarm / Tag Exposure; 3 Impact = Knock Down).

### Candidate D: Discrete Impact Bands (The "Gloomhaven" Model)

- **Mechanism:** Impact falls into discrete brackets based on $D$:
  - $I < D$: Soaked (0 cards).
  - $I = D \text{ to } (D+2)$: Glancing Hit (Draw 1 Severity 1 card).
  - $I = (D+3) \text{ to } (2D-1)$: Solid Strike (Draw 2 Severity 1 cards; Attacker chooses 1).
  - $I \ge 2D$: Crushing Blow (Inflict Severity 2).

### Candidate E: Fixed 2-Card Pool with Tier Escalation Thresholds

- **Mechanism:** Penetrating hits always draw exactly 2 candidate cards; defender selects 1. Incremental Impact adjusts the tier composition of those 2 cards:
  - $I = D \text{ to } D+1$: Draw `[Sev 1, Sev 1]`.
  - $I = D+2 \text{ to } 2D-1$: Draw `[Sev 1, Sev 2]`.
  - $I \ge 2D$: Draw `[Sev 2, Sev 2]`.
  - $I \ge 3D$: Draw `[Sev 2, Sev 3]`.

---

## 2. Adversarial Post-Mortem: Why It Was Retired

Adversarial stress-testing revealed that each capped-draw and remainder architecture creates critical systemic failures:

### 1. The 2-Card Escalation Catch-22 (Candidate A + Tag Escalation)

With a 2-card draw cap, the interaction between curation agency and tag escalation creates a lethal dilemma:

- **If the Attacker chooses on $R \ge 1$:** Defender agency ("You Choose") is completely destroyed. If the defender already possesses an active tag, upgrading 1 card via tag escalation yields a pool of `[Sev 1, Sev 2]`. The attacker immediately selects the `Sev 2` card, force-feeding higher-severity trauma directly to the defender. This completely bypasses armor width ($N$), resurrecting the catastrophic 3-hit sudden-death spikes documented in [tag-escalation-resilience.md](tag-escalation-resilience.md).
- **If the Defender chooses (Candidate E):** If the defender always chooses 1 of 2 cards from `[Sev 1, Sev 2]`, it becomes a solved [False Dilemma (Pitfall 2)](../../pitfalls.md#pitfall-2-the-false-dilemma--degenerate-defensive-choices). The defender will always select the milder `Sev 1` consequence. Upgrading a single card via tag escalation is rendered completely useless, stalling combat and paralyzing escalation.

### 2. Modulo Resets & Interval Collapse at Low Defense ($D \le 3$)

Remainder and bracket math breaks down when evaluated against light armor or unarmored combatants:

- **Sawtooth Modulo Resets:** Remainder math ($R = I \pmod D$) produces non-monotonic sawtooth drops at every $k \cdot D$ threshold. Against $D=4$, an attack increasing from $I=7$ ($R=3$, granting attacker choice + bonus Fatigue) to $I=8$ ($R=0$) resets remainder to zero, perversely stripping attacker curation and bonus Fatigue despite being a harder hit.
- **Unarmored Collapse ($D=2$):** Against an unarmored defender ($D=2$), the remainder $R = I \pmod 2$ can only ever be $0$ or $1$. The attacker can never achieve $R \ge 2$ or $R \ge 3$, meaning attacker curation and fatigue spillover are mathematically impossible against naked targets.
- **Interval Inversion in Brackets:** Fixed sub-tier brackets ($D+2 \text{ to } 2D-1$) in Candidates D and E collapse into impossible inverted ranges when $D \le 3$:
  - For $D=2$: $D+2 = 4$, while $2D-1 = 3$, creating the impossible range `4 to 3`.
  - For $D=3$: $D+2 = 5$, while $2D-1 = 5$, collapsing into an erratic 1-point window.

### 3. Multi-Attacker & Swarm Collapse

Decoupling $1\text{ Impact} = 1\text{ Card Drawn}$ breaks physical swarm mechanics:

- In the Consequence Pool, swarms combine low-Impact strikes into a single merged candidate pool of Tier 1 cards to overcome heavy armor ($N=4\text{--}5$), naturally maintaining a safe Tier 1 ceiling.
- Under capped remainder or bracket systems, decoupled Impact forces swarms to sum raw numerical Impact to crack high $D$. But allowing swarms to sum raw Impact means 4 goblin minions generating `Impact 8` against an unarmored target ($D=2$) instantly hit the $4D$ threshold, triggering Tier 4 instant-kill decapitations.
- Preventing this requires patching in complex multi-attacker severity caps, anti-swarm exceptions, and phase-timing rules, falling straight into [The Patchwork Trap (Pitfall 11)](../../pitfalls.md#pitfall-11-the-patchwork-trap-complexity-by-exception--flowchart-bloat).

### 4. False Dilemmas & Non-Combat Breakage (Candidates B & C)

- **In-Combat Deck Milling is Ineffective:** In Candidate B, milling 1 deck card to discard is mechanically negligible—a single card flip represents only $\sim 1/24\text{th}$ of an endurance cycle ([Pitfall 1.1](../../pitfalls.md#11-in-combat-vs-cross-combat-fatigue-dynamics)) and fails to create meaningful in-combat urgency.
- **Solved Fatigue Dilemma:** Offering a choice between "expend 1 card from hand vs. 1 Fatigue to discard" is a solved false dilemma ([Pitfall 2](../../pitfalls.md#pitfall-2-the-false-dilemma--degenerate-defensive-choices)). Players will almost always discard to fatigue rather than surrender immediate hand tempo during Crisis Time.
- **Tactical Maneuver Menus Violate Non-Combat Generality:** Candidate C introduces tactical combat menus (shove, trip, disarm) that violate [Combat-Centric Hyper-Specialization (Pitfall 12)](../../pitfalls.md#pitfall-12-combat-centric-hyper-specialization-the-two-game-trap). These actions cannot resolve social or environmental hazards, duplicate existing Tier 1/2 consequence cards (like `Off-Balance` or `Disarmed`), and bypass armor soak entirely.

---

## 3. Design Takeaway & Conclusion

In the Consequence Pool engine, setting **$1\text{ Impact} = 1\text{ Card Drawn}$** is not cumbersome arithmetic—it is a **physical analog state computer**.

By using cards directly as tokens:

1. **Soak & Penetration:** It automatically checks armor threshold ($I < N \implies 0\text{ cards drawn}$).
2. **Curation Leverage:** Extra Impact expands the candidate pool, naturally allowing the attacker to curate sharper outcomes without integer math or remainder division.
3. **Swarm Merging:** Multiple attackers can physically push their drawn cards together into a shared pool to overcome high $N$ while remaining structurally capped at Tier 1.
4. **Resilience Width:** It naturally scales against the Consequence Pyramid without needing division tables, modulo resets, or exception flowcharts.

Attempts to throttle card draw volume down to $\le 2$ cards using remainder math or bracket systems create far more cognitive overhead, mathematical pathology, and patchwork rules than handling the physical cards themselves.
