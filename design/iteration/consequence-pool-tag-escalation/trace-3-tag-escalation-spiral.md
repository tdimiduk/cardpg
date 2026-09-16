# Play Trace 3: Tag Escalation & The Downward Spiral

## Context & Combatants

- **Setting**: Muddy alleyway skirmish following an earlier brawl.
- **Attacker**: Cutthroat Duelist (Agile Yellow/Red build, exploiting defender's compromised state).
- **Defender**: Veteran Mercenary (Pool Size: **2**, armor already damaged/compromised).

### Existing Table State on Defender

The defender has already sustained two minor setbacks in earlier rounds:

1. `Poor Footing` (Severity 1, Tags: `positioning`, `physical`)
   - _Passive_: The Impact of your defenses is increased by 1.
   - _Action_: Regain Footing (Place a card from your hand on top of this. When 2 cards are on top of this, expend them and remove this).
   - _Task_: Catch Balance (Time 1 min) -> Remove this.
   - _Escalate_: **`if_suffer: positioning` $\to$ Replace with `Off Balance` (Severity 2).**
2. `Afraid` (Severity 2, Tags: `fear`, `mental`)
   - _Passive_: You must expend 1 card from hand to make a melee attack or willingly move closer to a foe.
   - _Action_: Martial Fury Surge (Spend {Red} 25) -> Remove this.
   - _Task_: Center Yourself (Check {Blue} 15; Time 5 min) -> Remove this.
   - _Escalate_: **`if_suffer: fear` $\to$ Replace with `Terrified` (Severity 3).**

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

### 3. Draw Candidate Consequences

- **Defender Consequence Pool Size ($N$)**: **2**.
- **Attacker Budget**: **4 Impact**.

The attacker spends 4 Impact directly to purchase candidate cards (1 Impact = 1 Severity):

1. **Draw 1 (Spend 2 Impact | 2 remaining)**:
   - Attacker draws from the **Severity 2** deck: **`Off Balance`** (Severity 2, Tags: `positioning`, `combat`).
2. **Draw 2 (Spend 2 Impact | 0 remaining)**:
   - Attacker draws from the **Severity 2** deck: **`Afraid`** (Severity 2, Tags: `fear`, `mental`).

_(Note: Candidate drawing is fast and uninterrupted—no card replacement checks or mid-draw table bookkeeping)._

---

### 4. Attacker Curates the Final Pool (The "I Cut" Step)

The defender's Pool Size is **2**. The attacker holds 2 candidate cards:

- `Off Balance` (Severity 2, `positioning`)
- `Afraid` (Severity 2, `fear`)

The attacker presents both cards to the defender. By examining the defender's active conditions, the attacker knows that **both** options will trigger a condition upgrade:

- Offering `Off Balance` threatens to upgrade `Poor Footing` $\to$ `Off Balance` (Severity 2).
- Offering `Afraid` threatens to upgrade `Afraid` $\to$ `Terrified` (Severity 3).

---

### 5. Defender Suffers Exactly 1 Consequence (The "You Choose" Step)

- **Pool Presented to Defender**:
  1. `Off Balance` (Severity 2 — Tags: `positioning`, `combat`)
  2. `Afraid` (Severity 2 — Tags: `fear`, `mental`)

- **Defender's Dilemma**:
  - If defender chooses `Off Balance`, active `Poor Footing` triggers its `escalate:` clause $\to$ `Poor Footing` is discarded and replaced with `Off Balance` (disabling Move actions and hand defenses).
  - If defender chooses `Afraid`, active `Afraid` triggers its `escalate:` clause $\to$ `Afraid` is discarded and replaced with **`Terrified` (Severity 3)** (2-card attack tax, cannot move closer).

- **Defender's Choice**:
  - The defender chooses **`Afraid`**.
  - **Resolution**: Active `Afraid` triggers its `escalate:` clause:
    - Active `Afraid` (Sev 2) is discarded.
    - Upgraded condition **`Terrified` (Severity 3)** is placed into play in front of the defender.
    - `Poor Footing` remains in play unchanged.

---

## Key Insights from Trace 3

1. **Clean Draw Ergonomics**:
   - Attackers spend Impact as straightforward 1:1 currency to draw cards from severity decks without mid-draw replacement cascades or tapping table cards during the purchase phase.
2. **Thematic Vulnerability & Attacker Targeting**:
   - The downward spiral emerges naturally when attackers observe active conditions and curate matching tags into the pool.
3. **Transparent Player Dilemmas**:
   - The defender sees both the incoming choices and their active conditions' explicit `escalate:` clauses, making the trade-off clear, high-stakes, andtactically meaningful.
4. **Clean Board State (No Redundant Cards)**:
   - When a condition escalates, the lower-tier card is discarded upon upgrade. The player only tracks the active, upgraded condition.
5. **Decisive 5-Tier Runway**:
   - The defender has reached **`Terrified` (Severity 3)**. Under the 5-tier model, suffering further compounding fear consequences triggers its `escalate:` clause directly toward terminal psychological collapse (**`Mind Void / Catatonic Panic`**), removing the mercenary from the fight. The stakes for subsequent rounds are immediate and unmistakable.
