# Play Trace 4: Mob Combat & Multi-Attacker Dynamics (Batched Round Pool)

## Context & Combatants

- **Setting**: Ambush in a cramped dungeon corridor.
- **Attackers**: 3 Goblin Skirmishers (Low-strength Red swarm attacks acting simultaneously in Crisis Time).
- **Defender**: Squire (Agile Red/Yellow deck, equipped with **Padded Gambeson**, Consequence Pool Size: **3**).

---

## 1. Simultaneous Attack Declarations

In the simultaneous declaration phase of Crisis Time, all three goblins coordinate their strikes against the Squire:

1. **Goblin 1**: `Whack` -> **Red Strength 4**.
2. **Goblin 2**: `Slash with Rusty Blade` -> **Red Strength 4**.
3. **Goblin 3**: `Spear Jab` -> **Red Strength 5**.

---

## 2. Defense Step & Total Round Impact Calculation

The Squire has no active defense cards in hand and resolves each attack in sequence by flipping cards from the deck:

1. **Defending Goblin 1 (Str 4)**:
   - Flip 1: {Red: 2} -> Cumulative: 2
   - Flip 2: {Red: 3} -> Cumulative: 5 (Met: 5 >= 4).
   - _Flipped_: 2 cards -> **2 Impact**.

2. **Defending Goblin 2 (Str 4)**:
   - Flip 1: {Red: 2} -> Cumulative: 2
   - Flip 2: {Red: 3} -> Cumulative: 5 (Met: 5 >= 4).
   - _Flipped_: 2 cards -> **2 Impact**.

3. **Defending Goblin 3 (Str 5)**:
   - Flip 1: {Red: 5} -> Cumulative: 5 (Met: 5 >= 5).
   - _Flipped_: 1 card -> **1 Impact**.

### Total Round Impact

- **Total Flipped Cards**: 5 cards expended from deck.
- **Combined Impact**: $2 + 2 + 1 =$ **5 Total Impact ($I$)**.

---

## 3. Draw Candidate Consequences (Layered Pool Fill)

Because all three attacks targeted the Squire during the same Crisis round, their Impact combines into a single pool to test the Squire's armor:

- **Defender's Consequence Pool Size ($N$)**: **3** (set by Padded Gambeson).
- **Total Round Impact ($I$)**: **5 Impact**.

### Layered Candidate Draws (5 Impact against N = 3)

Candidates fill tiers of width $N = 3$ from the bottom up (1 Impact = 1 card):

1. **Tier 1 (3 Impact)**: Fills Tier 1 completely, drawing 3 cards from the **Tier 1** deck:
   - `Rattled Guard` (Tier 1, Tags: `combat`, `armor`, Priority 5)
   - `Afraid` (Tier 1, Tags: `fear`, Priority 4)
   - `Winded` (Tier 1, Tags: `fatigue`, Priority 2)
2. **Tier 2 (2 Impact)**: Enters Tier 2, drawing 2 cards from the **Tier 2** deck:
   - `Knocked Prone` (Tier 2, Tags: `positioning`, `combat`, Priority 5)
   - `Cracked Ribs` (Tier 2, Tags: `torso`, Priority 4)

Total candidates drawn: **5 cards** (two Tier 2, three Tier 1).

---

## 4. Attacker Curates the Consequence Pool (The "I Cut" Step)

The Squire's Consequence Pool Size ($N$) is **3** (set by Padded Gambeson).

- The goblins hold 5 candidates and must curate down to 3 cards.
- They include **`Knocked Prone`** (Tier 2) to threaten a fatal knockdown.
- In the remaining two slots, they curate away the soft `Winded` (Priority 2) and offer two punishing Tier 1 locks: **`Rattled Guard`** (Priority 5) and **`Afraid`** (Priority 4).
- They curate a punishing 3-card pool:
  1. `Knocked Prone` (Tier 2 — doubled pierce and movement tax)
  2. `Rattled Guard` (Tier 1 — strips armor's first pierce threshold)
  3. `Afraid` (Tier 1 — approach and melee tax)

---

## 5. Defender Suffers Exactly 1 Consequence (The "You Choose" Step)

- **Pool Presented to Defender**:
  1. `Knocked Prone` (Tier 2)
  2. `Rattled Guard` (Tier 1)
  3. `Afraid` (Tier 1)

- **Defender's Tactical Choice**:
  - The Squire recognizes that taking `Knocked Prone` would be fatal against three surrounding goblins.
  - Between the two Tier 1 locks, `Afraid` would tax attacks against every goblin, while `Rattled Guard` loosens straps on their gambeson.
  - The Squire chooses **`Rattled Guard`** (Tier 1).
  - The card is placed directly onto the Squire's **Padded Gambeson** card on the table.
  - Unselected cards (`Knocked Prone`, `Afraid`) are returned to their respective decks.

---

## Analysis & Key Insights

1. **Table Ergonomics & Speed**:
   - The defender made 6 flips in rapid succession during the defense step.
   - The GM performed **a single pool construction** across all three attackers.
   - The defender made **one single decision**.
   - This prevents the sluggish stop-and-go pattern of resolving 3 separate drafting rounds within a single turn.

2. **Swarm Viability vs. Armor Soak**:
   - Under an unbatched per-attack resolution model, each 2-Impact hit against Pool Size 3 would have left 2 unfilled slots ("No Consequence"), allowing the Squire to completely ignore all three hits without sustaining any conditions.
   - Under **Individual Spend into a Shared Round Pool**, coordinated multi-attacker pressure combines candidate draws into a single pool that easily fills the Squire's Pool Size 3, generating surplus draws to curate away soft exits.

3. **Intra-Tier Dynamic Range in Swarm Play**:
   - If each goblin had generated only 1 Impact (e.g. if the Squire had played a Defend card from hand), the 3 goblins would have produced exactly three Tier 1 cards with zero surplus curation. The pool would have naturally included softer options like `Winded` or `Poor Footing`, allowing the Squire to safely absorb the blow.
   - By generating 2 Impact each, the swarm achieved curation leverage, purging the soft options and forcing the Squire to choose between a Tier 2 platform break and two sharp tactical locks.
