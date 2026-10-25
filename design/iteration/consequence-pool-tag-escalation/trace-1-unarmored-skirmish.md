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
- **Total Impact**: **3 Impact**.

#### Layered Candidate Draws (3 Impact against N = 2)

Candidates fill tiers of width $N = 2$ from the bottom up (1 Impact = 1 card):

1. **Tier 1 (2 Impact)**: Fills Tier 1 completely, drawing 2 cards from the **Tier 1** deck:
   - `Poor Footing` (Tier 1, Tags: `positioning`, `physical`, Priority 2)
   - `Dust in Eyes` (Tier 1, Tags: `sensory`, Priority 3)
2. **Tier 2 (1 Impact)**: Enters Tier 2, drawing 1 card from the **Tier 2** deck:
   - `Knocked Prone` (Tier 2, Tags: `positioning`, `combat`)

Total candidates drawn: **3 cards**.

#### Curating the Pool (The "I Cut" Step)

The defender's Pool Size is 2. The attacker selects 2 cards from the 3 drawn candidates:

- The attacker keeps **`Knocked Prone`** (Tier 2) to threaten a platform takedown.
- For the second slot, the attacker curates **`Poor Footing`** over `Dust in Eyes` to establish an active `positioning` tag.
- **Pool Presented to Defender**: `[Knocked Prone (Tier 2), Poor Footing (Tier 1)]`.

---

### 4. Resolution: Step 3 - Defender Suffers a Consequence (The "You Choose" Step)

- **Defender's Choice**:
  - The Defender is presented with `[Knocked Prone (Tier 2), Poor Footing (Tier 1)]`.
  - The Defender selects **`Poor Footing`** (Tier 1).
  - `Poor Footing` enters play in front of the Defender as an active condition.
  - The unchosen card (`Knocked Prone`) is returned to the Tier 2 deck.

---

## Analysis of the Exchange

1. **Elimination of No-Ops**:
   - In earlier iterations, the defender picked `Near Miss`, resulting in zero table impact despite sustaining 3 Impact.
   - Under the 4-tier engine, the defender suffers **`Poor Footing`**—a tangible condition with an active $+1$ Impact penalty, clearable mid-combat, that serves as vital kindling for subsequent tag escalations.
2. **Defensive Value of Hand Play**:
   - With 3 Impact and Pool Size 2, the attacker could not guarantee a Tier 2 platform break (which requires $2 \times 2 = 4$ Impact).
   - By playing `Quick Step` from hand, the defender shaved the attack down from 4 to 3 Impact, directly saving themselves from being forced to take `Knocked Prone`.
3. **The Tactical Dilemma Ahead**:
   - The defender now has an exposed `positioning` tag. On their upcoming turn, they must choose between sacrificing tempo to `Regain Footing` or attacking and risking an escalation to `Off Balance` or `Knocked Prone` on the next incoming blow.
