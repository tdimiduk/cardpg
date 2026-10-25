# Play Trace 3: Tag Escalation & The Downward Spiral

## Context & Combatants

- **Setting**: Muddy alleyway skirmish following an earlier brawl.
- **Attacker**: Cutthroat Duelist (Agile Yellow/Red build, exploiting defender's compromised state).
- **Defender**: Veteran Mercenary (Pool Size: **2**, armor already damaged/compromised).

### Existing Table State on Defender

The defender has already sustained two tactical setbacks in earlier rounds:

1. `Poor Footing` (Tier 1, Tags: `positioning`, `physical`, Priority 2)
   - _Passive_: The Impact of your defenses is increased by 1.
   - _Action_: Regain Footing (Place a card from your hand on top of this. When 2 cards are on top of this, expend them and remove this).
   - _Task_: Catch Balance (Time 1 min) -> Remove this.
   - _Escalate_: **`if_suffer: positioning` $\to$ Replace with `Off Balance` (Tier 1).**
2. `Afraid` (Tier 1, Tags: `fear`, `mental`, Priority 4)
   - _Passive_: You must expend 1 card from hand to make a melee attack or willingly move closer to a foe.
   - _Action_: Martial Fury Surge (Spend {Red} 25) -> Remove this.
   - _Task_: Center Yourself (Check {Blue} 15; Time 5 min) -> Remove this.
   - _Escalate_: **`if_suffer: fear` $\to$ Replace with `Terrified` (Tier 2).**

---

## Round Sequence

### 1. Plan Step

- Attacker declares `Hamstringing Slice`:
  - Attack: {Yellow} Str = {Yellow} + 1; Cost: 1; Stats: {Yellow: 3, Red: 2}
  - Stack: Top card ({Yellow: 3}) + 1 Resource ({Yellow: 2}) + 1 modifier = **6 Yellow**.

### 2. Defense Step & Impact Calculation

- Defender has no defense cards remaining in hand.
- Defender flips cards from deck to meet 6 Yellow:
  - Flip 1: {Yellow: 2} -> 2
  - Flip 2: {Yellow: 2} -> 4
  - Flip 3: {Yellow: 3} -> 7 (Met: 7 >= 6).
- **Base Flipped Cards**: 3 flips.
- **Passive Trigger from `Poor Footing`**: "The Impact of your defenses is increased by 1."
- **Total Round `Impact`**: $3 + 1 = \mathbf{4\text{ Impact}}$.

---

### 3. Draw Candidate Consequences (Layered Pool Fill)

- **Defender Consequence Pool Size ($N$)**: **2**.
- **Total Impact ($I$)**: **4 Impact**.

Candidates fill tiers of width $N = 2$ from the bottom up (1 Impact = 1 card):

1. **Tier 1 (2 Impact)**: Fills Tier 1 completely, drawing 2 cards from the **Tier 1** deck:
   - `Off Balance` (Tier 1, Tags: `positioning`, `combat`, Priority 4)
   - `Afraid` (Tier 1, Tags: `fear`, `mental`, Priority 4)
2. **Tier 2 (2 Impact)**: Fills Tier 2 completely, drawing 2 cards from the **Tier 2** deck:
   - `Knocked Prone` (Tier 2, Tags: `positioning`, `combat`, Priority 5)
   - `Mild Concussion` (Tier 2, Tags: `head`, `trauma`, Priority 4)

Total candidates drawn: **4 cards** (two Tier 2, two Tier 1).

---

### 4. Attacker Curates the Final Pool (The "I Cut" Step)

The defender's Pool Size is **2**. The attacker holds 4 candidates across Tier 1 and Tier 2.

While the attacker could present the two raw Tier 2 trauma cards (`[Knocked Prone, Mild Concussion]`), the attacker notices that the two Tier 1 draws match active tags on the defender:

- `Off Balance` (`positioning`) matches active `Poor Footing` (triggering an escalation upgrade to `Off Balance`).
- `Afraid` (`fear`) matches active `Afraid` (triggering an escalation upgrade to `Terrified` [Tier 2]).

The attacker intentionally passes up the raw Tier 2 cards and curates the **two tag-matching Tier 1 cards**:

- **Pool Presented to Defender**: `[Off Balance (Tier 1), Afraid (Tier 1)]`.

---

### 5. Defender Suffers Exactly 1 Consequence (The "You Choose" Step)

- **Pool Presented to Defender**:
  1. `Off Balance` (Tier 1 — Tags: `positioning`, `combat`)
  2. `Afraid` (Tier 1 — Tags: `fear`, `mental`)

- **Defender's Dilemma**:
  - If defender chooses `Off Balance`, active `Poor Footing` triggers its `escalate:` clause $\to$ `Poor Footing` is discarded and replaced with `Off Balance` (disabling Move actions and hand defenses).
  - If defender chooses `Afraid`, active `Afraid` triggers its `escalate:` clause $\to$ `Afraid` is discarded and replaced with **`Terrified` (Tier 2)** (2-card attack tax, cannot move closer).

- **Defender's Choice**:
  - The defender chooses **`Afraid`**.
  - **Resolution**: Active `Afraid` triggers its `escalate:` clause:
    - Active `Afraid` (Tier 1) is discarded.
    - Upgraded condition **`Terrified` (Tier 2)** is placed into play in front of the defender.
    - `Poor Footing` remains in play unchanged.

---

## Key Insights from Trace 3

1. **Clean Draw Ergonomics**:
   - Attackers spend Impact as straightforward 1:1 currency to draw cards without mid-draw replacement cascades or complex divisor math.
2. **Thematic Vulnerability & Attacker Targeting**:
   - The downward spiral emerges naturally when attackers observe active conditions and curate matching tags into the pool.
3. **Transparent Player Dilemmas**:
   - The defender sees both the incoming choices and their active conditions' explicit `escalate:` clauses, making the trade-off clear, high-stakes, and tactically meaningful.
4. **Clean Board State (No Redundant Cards)**:
   - When a condition escalates, the lower-tier card is discarded upon upgrade. The player only tracks the active, upgraded condition.
5. **Decisive 4-Tier Runway**:
   - The defender has reached **`Terrified` (Tier 2)**. Under the 4-tier model, suffering further compounding fear consequences triggers its `escalate:` clause directly toward terminal psychological collapse (**`Mind Void` [Tier 4]**), removing the mercenary from the fight. The stakes for subsequent rounds are immediate and unmistakable.
