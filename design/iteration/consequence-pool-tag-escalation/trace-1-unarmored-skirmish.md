# Play Trace 1: Unarmored Skirmish

## Context & Combatants

- **Setting**: Duel in an open courtyard between two agile fighters.
- **Attacker**: Swashbuckler (Aggressive, Yellow/Red finesse deck).
- **Defender**: Unarmored Rogue (Agile, Yellow defense, Base Pool Size: **2**, No Armor).

---

## Round Sequence

### 1. Plan Step

- Both combatants draw 2 cards.
- **Attacker's Hand**:
  - `Lunge & Thrust` (Attack: {Yellow} Str = {Yellow} + 2; Cost: 1; Stats: {Red: 2, Yellow: 3, Blue: 1})
  - `Feint` (Stats: {Red: 1, Yellow: 3, Blue: 2})
- **Attacker's Declaration**:
  - Plays `Lunge & Thrust` backed by `Feint` as a resource.
  - Calculated Attack: **Yellow Strength = 3 (top card) + 3 (resource card) + 2 (modifier) = 8 Yellow**.

- **Defender's Hand**:
  - `Quick Step` (Defend: Yellow Str = {Yellow} + 1; Stats: {Red: 1, Yellow: 2, Blue: 2})
  - `Dagger Slash` (Attack: {Yellow} Str = {Yellow}; Cost: 1; Stats: {Red: 2, Yellow: 2, Blue: 1})
- **Defender's Decision**:
  - Decides to preserve `Dagger Slash` for next round, but plays `Quick Step` from hand reactively to mitigate the blow.
  - Hand Defense provides **2 + 1 = 3 Yellow Strength**.
  - Remaining Strength to meet from Deck flips: **8 - 3 = 5 Yellow**.

---

### 2. Resolution: Step 1 - Determine Impact

- Defender flips cards from the top of their deck one by one:
  - Flip 1: `Acrobatics` ({Yellow: 2}) -> Cumulative: 2 (Need 5)
  - Flip 2: `Footwork` ({Yellow: 1}) -> Cumulative: 3 (Need 5)
  - Flip 3: `Tumble` ({Yellow: 3}) -> Cumulative: 6 (Met: 6 >= 5).
- **Total Flipped Cards**: 3 cards.
- **`Impact` Generated**: **3 Impact**.

---

### 3. Resolution: Step 2 - Draw Candidate Consequences & Curate Pool

- **Defender's Consequence Pool Size ($N$)**: **2** (Base unarmored).
- **Attacker's Budget**: **3 Impact**.

#### Attacker's Spending & Candidate Draws

The attacker has 3 Impact and decides to draw a spread of candidate consequences:

- **Candidate 1 (Spend 2 Impact | 1 remaining)**: Draws from Severity 2 deck $\to$ `Off Balance` (Severity 2, Tags: `positioning`, `combat`).
  - _Passive_: You cannot take Move actions or play Defend cards from hand.
  - _Action_: Regain Center (Spend {Yellow} 20) -> Remove this.
- **Candidate 2 (Spend 1 Impact | 0 remaining)**: Draws from Severity 1 deck $\to$ `Near Miss` (Severity 1, Tags: `combat`, `positioning`).
  - _Rules_: Return this card with no further effect.

#### Curating the Pool (The "I Cut" Step)

The defender's Pool Size is 2. The attacker has drawn exactly 2 candidate cards:

- **Pool Presented to Defender**: `[Off Balance (Severity 2), Near Miss (Severity 1)]`.

---

### 4. Resolution: Step 3 - Defender Suffers a Consequence (The "You Choose" Step)

- **Defender's Choice**:
  - The Defender is presented with `[Off Balance, Near Miss]`.
  - The choice is obvious: Defender chooses **`Near Miss`**.
  - `Near Miss` effect triggers: _Return this card with no further effect._
  - Unchosen card (`Off Balance`) is returned to the Severity 2 deck.

---

## Analysis of the Exchange

1. **Table Ergonomics**:
   - Calculating 3 flips was fast.
   - Attacker spent 3 Impact as $2 + 1$, drawing two physical cards and presenting them.
   - Defender made an instantaneous choice.
2. **Mechanical Dynamics**:
   - With 3 Impact and Pool Size 2, the attacker could not guarantee a Severity 2 wound (which requires $2 + 2 = 4$ Impact). The defender's reactive defense card (`Quick Step`) successfully shaved the Impact from 4 down to 3, directly saving them from guaranteed harm.
   - This makes reactive hand defense feel impactful and tactically necessary.
