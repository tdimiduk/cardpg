# Consequence Pool & Tag Escalation: Evaluation

This document tracks the advantages, disadvantages, invariants, and open design questions for the Consequence Pool & Tag Escalation proposal suite.

---

# Disadvantages & Known Risks

## 1. More Complex Consequence Resolution Procedure

- Replaces simple division ($\lfloor I / D \rfloor$) and a row grid with a multi-step drafting market (Impact tally $\to$ threshold check $\to$ candidate draw $\to$ vulnerability exploitation $\to$ curate $N$ $\to$ suffer 1).
- Introduces two major player decision points per exchange (attacker curation and defender consequence selection) plus intermediate tag-matching steps, which may add friction and slow down Crisis Time resolution.

## 2. Heavy Card Draws & Deck-Handling Overhead

- Drawing 1 card per point of Impact plus tag promotions pulls a large volume of cards from the consequence decks in heavy exchanges or merged swarm attacks.
- Even with sub-threshold hits ($I < N$) cleanly skipping draws, a penetrating hit against $N=4\text{–}5$ pulls 4–8 cards at a time, resulting in frequent deck depletion, card reading, and reshuffling.

## 3. Additional Consequence Deck (Severity 4)

- Adds a 4th severity level (`Severity 4: Taken Out / Climax Clock`), requiring 1 additional physical deck per domain/harm type on the table.

## 4. GM Cognitive Load & Priority Adjudication

- When running monsters attacking players, the GM must actively curate candidate pools ("I Cut"), or rely on printed `Priority (1–5)` ratings to sort cards mechanically, which risks turning a narrative choice into procedural math.

## 5. Minion Handling Degrades Slightly

- In canon `Defense + Resilience`, setting `Resilience 0` allowed mooks to drop cleanly on any hit without tracking rows.
- While `Pool Size 1` makes minions drop on terminal tiers and eliminates drafting curation, it remains slightly fiddlier than `Resilience 0` when tracking intermediate hits.

---

# Advantages

## 1. Solves Unified Doom / Harm Bleed

- Decouples harm progression from an abstract global track.
- Non-lethal consequences (social embarrassment, minor fatigue, or fleeting footing setbacks) no longer advance a character toward lethal physical trauma.

## 2. Incremental Impact Matters

- Once an attack meets the threshold ($I \ge N$), every individual additional point of Impact draws an extra candidate card, giving the attacker direct curation leverage (squeezing out softer outcomes, hunting key vulnerability tags, or climbing severity tiers).

## 3. High Defender Agency ("You Choose")

- Defenders actively decide which consequence to absorb, giving them tactical agency on every penetrating hit even when caught with an empty hand or without reactive Defend cards.

## 4. Stat Consolidation (One Stat Instead of Two)

- Collapses two separate character/armor stats (`Defense` and `Resilience`) into a single intuitive parameter: **Consequence Pool Size ($N$)**.
- $N$ simultaneously governs the initial penetration threshold ($I < N$ does not penetrate) and the row width required to escalate into higher severities.

## 5. Emergent Multi-Attacker & Swarm Tactics

- Attackers naturally choose between keeping pools separate (inflicting multiple simultaneous Tier 1 conditions on lightly armored targets) or merging drawn candidate pools into a shared pool to crack heavy armor ($N = 4\text{–}5$) without escalating card severity.

---

# Stays About the Same

## Initial "Cracking the Shell"

- Getting past armor/poise to deliver an initial consequence remains roughly comparable to canon `Defense` (e.g., Full Harness shifts from `Defense 4` to `Pool Size 5`).
- However, once initial conditions land on the table, follow-up hits penetrate much faster due to tag vulnerability escalations.

---

# Open Questions & Dedicated Explorations

1. **Does replacing Resilience with Tag Escalation work without the pool mechanics?**
   - _Status:_ Yes, completely separable.
   - _Forked Proposal:_ See [tag-escalation-resilience.md](../retired/tag-escalation-resilience.md) for a post-mortem on applying Tag Escalation without pool drafting (retired due to bimodal variance).

2. **Is there sensible design space that lets incremental Impact matter without drawing one card per Impact?**
   - _Status:_ Evaluated and retired. Replacing $1\text{ Impact} = 1\text{ Card Drawn}$ with remainder math, stamina spillover, or fixed 2-card draws was explored but failed under adversarial stress-testing. Capped draws trigger the 2-card escalation catch-22 (attacker curation bypasses armor width into 3-hit sudden deaths, while defender choice renders single-tag escalation a solved false dilemma), suffer modulo resets and interval collapse at low Defense ($D \le 3$), and break emergent swarm merging—ultimately requiring more special-case exception rules than the full Consequence Pool engine.
   - _Post-Mortem:_ See [incremental-impact-mechanics.md](../retired/incremental-impact-mechanics.md).

3. **Can tag-based escalation be delegated to card rules instead of living in the core rules?**
   - _Status:_ Evaluated and rejected as a complexity shell game. Moving procedural tag-matching chains onto condition passive text or card keywords redistributes cognitive load rather than eliminating it, resulting in card text bloat and hidden board-state triggers. While scalar input modifiers like `+1 Impact` or threshold shifts remain cleanly on cards, core escalation logic belongs in procedural rules.

4. **Can we simplify the proposal while keeping its core benefits?**
   - _Status:_ Addressed by scrapping the "blank" / "no consequence" rule in favor of a clean threshold ($I < N \implies$ 0 cards drawn). Further simplification previously explored the Consolidated 3-Tier Deck architecture ([consolidated-tiered-cards-and-triage.md](../retired/consolidated-tiered-cards-and-triage.md), since retired).
