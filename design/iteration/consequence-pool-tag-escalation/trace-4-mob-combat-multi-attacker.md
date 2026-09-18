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
   - Flip 1: {Red: 3} -> Cumulative: 3
   - Flip 2: {Red: 3} -> Cumulative: 6 (Met: 6 >= 5).
   - _Flipped_: 2 cards -> **2 Impact**.

### Impact by Attacker

- **Total Flipped Cards**: 6 cards expended from deck.
- **`Goblin 1 Impact`**: 2 cards flipped -> **2 Impact**.
- **`Goblin 2 Impact`**: 2 cards flipped -> **2 Impact**.
- **`Goblin 3 Impact`**: 2 cards flipped -> **2 Impact**.

---

## 3. Draw Candidate Consequences & Curate Pool (Individual Spend into Shared Pool)

Because all three attacks targeted the Squire during the same Crisis round, their candidate draws are gathered into a single pool for curation. Each goblin spends its own individual Impact:

- **Defender's Consequence Pool Size ($N$)**: **3** (set by Padded Gambeson).
- **Individual Budgets**: Goblin 1 (2 Impact), Goblin 2 (2 Impact), Goblin 3 (2 Impact).

### Candidate Draws

Each goblin spends its 2 Impact. In the 4-tier engine, 2 Impact can purchase a **Tier 2** platform break, or two **Tier 1** tactical cards:

- **Goblin 1 (Spend 2 Impact)**: Draws one **Tier 2** candidate $\to$ **`Knocked Prone`** (Tier 2, Tags: `positioning`, `combat`, Priority 5).
- **Goblin 2 (Spend 2 Impact)**: Draws two **Tier 1** candidates $\to$ **`Rattled Guard`** (Tier 1, Tags: `combat`, `armor`, Priority 5) and **`Winded`** (Tier 1, Tags: `fatigue`, Priority 2).
- **Goblin 3 (Spend 2 Impact)**: Draws two **Tier 1** candidates $\to$ **`Strained Offense`** (Tier 1, Tags: `arms`, Priority 3) and **`Afraid`** (Tier 1, Tags: `fear`, Priority 4).

Total candidates in the combined hand: **5 cards** (one Tier 2, four Tier 1).

---

## 4. Attacker Curates the Consequence Pool (The "I Cut" Step)

The Squire's Consequence Pool Size ($N$) is **3** (set by Padded Gambeson).

- The goblins hold 5 candidates and have **surplus curation leverage** (5 candidates for 3 slots).
- The goblins curate away the softer, clearable option (`Winded` [Priority 2]) and one offensive tax (`Strained Offense` [Priority 3]).
- They curate a lethal, punishing 3-card pool:
  1. `Knocked Prone` (Tier 2 — doubled pierce and movement tax)
  2. `Rattled Guard` (Tier 1 — strips armor's first pierce threshold)
  3. `Afraid` (Tier 1 — melee attack and approach tax)

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
