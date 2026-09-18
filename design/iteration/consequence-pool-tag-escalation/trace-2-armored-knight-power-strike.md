# Play Trace 2: Armored Knight vs. Power Strike (Armor & Pierce Dynamics)

## Context & Combatants

- **Setting**: Heavy melee engagement in a ruined hall.
- **Attacker**: Orc Chieftain (Brute Red deck, wielding a Greatmaul).
- **Defender**: Knight (Shield-Fighter deck, wearing **Full Harness**).

### Armor & Gear Profile

- **Full Harness**:
  - Burden: 2
  - Rules:
    - _Passive 1_: Your consequence pool size is 5. An attack with Pierce 4 can ignore this passive.
    - _Passive 2_: Your consequence pool size is 4. An attack with Pierce 8 can ignore this passive.
    - _Passive 3_: Your consequence pool size is 3. An attack with Pierce 12 can ignore this passive.
    - _Armor Integrity Rule_: The first time a consequence pool forces you to suffer a consequence of Severity 3 or higher, flip this armor to its Damaged side instead and negate that consequence.

---

## Exchange A: Standard Heavy Strike vs. Intact Full Harness

### 1. Attack Declaration

- Orc Chieftain plays `Greatmaul Sweep`:
  - Attack: {Red} Str = {Red} + 3; Pierce 4; Cost: 2
  - Resource cards in stack: 2 cards ({Red: 3}, {Red: 3})
  - Top card: {Red: 4}
  - **Calculated Attack**: **Red Strength = 4 + 3 + 3 + 3 = 13 Red (Pierce 4)**.

### 2. Defense & Impact

- Knight has no active defense cards in hand, relying on armor and deck flips.
- Knight flips cards from deck to meet 13 Red:
  - Flip 1: `Conditioning` ({Red: 4}) -> Cumulative: 4
  - Flip 2: `Power` ({Red: 5}) -> Cumulative: 9
  - Flip 3: `Athletics` ({Red: 4}) -> Cumulative: 13 (Met: 13 >= 13).
- **Total Flipped Cards**: 3 cards.
- **`Impact` Generated**: **3 Impact**.

### 3. Draw Candidate Consequences & Curate Pool

- **Full Harness Check against Pierce 4**:
  - Attack has Pierce 4. Passive 1 is ignored; Passive 2 holds $\to$ **Defender Pool Size ($N$) = 4**.
- **Attacker Budget**: **3 Impact**.
- **Candidate Draws**:
  - Attacker spends 3 Impact to draw 3 candidate cards from Tier 1: `[Winded (Tier 1), Poor Footing (Tier 1), Slightly Battered (Tier 1)]`.
- **Pool Curation (The "I Cut" Step)**:
  - The defender requires $N = 4$ cards in the pool.
  - Because the attacker only has 3 candidate cards, the 4th option is **implicitly filled with "No Consequence"**.
  - **Pool Presented to Defender**: `[Winded (Tier 1), Poor Footing (Tier 1), Slightly Battered (Tier 1), No Consequence]`.

### 4. Defender Suffers a Consequence (The "You Choose" Step)

- Knight chooses **No Consequence**.
- **Narrative & Tactical Outcome**: The greatmaul crashes violently against the fluted steel plate, ringing the knight's ears and expending 3 cards of stamina/endurance, but the armor's structural coverage (Pool Size 4 after Pierce 4) prevents any debilitating wound or condition from landing.

---

## Exchange B: Overwhelming Sunder Strike (Pierce 8)

In the subsequent round, the Orc Chieftain commits everything to a specialized anti-armor blow.

### 1. Attack Declaration

- Orc Chieftain plays `Overhead Skull-Cracker`:
  - Attack: {Red} Str = {Red} + 5; **Pierce 8**; Cost: 3
  - Stack: Top card ({Red: 4}) + 3 Resources ({Red: 3, Red: 3, Red: 4}) + 5 modifier = **19 Red (Pierce 8)**.

### 2. Defense & Impact

- Knight plays `Shield Block` from hand ({Red: 3}, recovers 1 resource).
- Remaining Strength to meet: **19 - 3 = 16 Red**.
- Knight flips from deck:
  - Flip 1: {Red: 3} -> 3
  - Flip 2: {Red: 2} -> 5
  - Flip 3: {Red: 4} -> 9
  - Flip 4: {Red: 3} -> 12
  - Flip 5: {Red: 4} -> 16 (Met: 16 >= 16).
- **Total Flipped Cards**: 5 cards -> **5 Impact**.

### 3. Draw Candidate Consequences & Curate Pool

- **Full Harness Check against Pierce 8**:
  - Pierce 8 meets both Passive 1 (Pierce 4) and Passive 2 (Pierce 8)! Both are ignored.
  - Passive 3 remains active (Pierce 8 < 12) -> **Defender Pool Size ($N$) drops to 3**.
- **Attacker Budget**: **5 Impact**.
- **Candidate Draws (Spend 5 Impact)**:
  - The Orc Chieftain spends 2 Impact to draw a heavy **Tier 2** platform break, and spends 3 Impact to draw **Tier 1** candidates:
    - Spend 2 Impact: Draws from **Tier 2** deck $\to$ **`Knocked Prone`** (Tier 2, Tags: `positioning`, `combat`, Priority 5).
    - Spend 1 Impact: Draws from **Tier 1** deck $\to$ **`Rattled Guard`** (Tier 1, Tags: `combat`, `equipment`, `armor`, Priority 5).
    - Spend 1 Impact: Draws from **Tier 1** deck $\to$ **`Strained Offense`** (Tier 1, Tags: `physical`, `arms`, `combat`, Priority 3).
    - Spend 1 Impact: Draws from **Tier 1** deck $\to$ **`Slightly Battered`** (Tier 1, Tags: `physical`, `injury`, Priority 1).
- **Pool Curation (The "I Cut" Step)**:
  - The defender requires $N = 3$ cards.
  - The attacker holds 4 candidates and curates down to 3 cards:
    - Orc drops the softest option (`Slightly Battered` [Priority 1]) and returns it to the Tier 1 deck.
    - Orc presents the remaining 3 cards:
    - **Pool Presented to Defender**: `[Knocked Prone (Tier 2), Rattled Guard (Tier 1), Strained Offense (Tier 1)]`.

### 4. Defender Suffers a Consequence (The "You Choose" Step)

- Knight is presented with `[Knocked Prone, Rattled Guard, Strained Offense]`.
- Knight faces a high-stakes dilemma:
  - Choosing `Knocked Prone` leaves the knight in the dirt with doubled pierce against them.
  - Choosing `Strained Offense` taxes every subsequent swing by 1 hand card.
  - Choosing `Rattled Guard` loosens straps and strips their armor's first pierce threshold.
- Knight chooses **`Rattled Guard`** (Tier 1).
- `Rattled Guard` is placed onto the Knight's **Full Harness** card on the table.
- Unselected cards (`Knocked Prone`, `Strained Offense`) are returned to their respective decks.

---

## Key Insights from Trace 2

1. **Armor as Pool Expansion is Elegant and Intuitive**:
   - Instead of tracking an abstract arithmetic divisor like `floor(Impact / Defense)`, armor directly acts as **insulation against concentrated harm**.
   - With base Pool Size 5, an attacker needs at least 5 Impact to deal even a Tier 1 condition, 10 Impact for Tier 2, 15 for Tier 3, and 20 to take the knight out.
2. **Surplus Impact as Curation Leverage**:
   - Generating 5 Impact against $N = 3$ gave the Orc Chieftain the leverage to discard the softer `Slightly Battered` condition and present a brutal dilemma featuring a Tier 2 platform break and two sharp Tier 1 locks.
3. **Stepped Pierce Translates Naturally**:
   - Stepped Pierce thresholds (Pierce 4, 8, 12) peel away the defender's buffer (from 5 down to 4, 3, or 2), allowing heavy attacks to focus Impact into fewer, higher-tier slots.
4. **Player Agency Under Pressure**:
   - The defender always has a choice among the offered consequences, allowing the knight to trade off offensive tempo (`Strained Offense`) against future defensive vulnerabilities (`Rattled Guard`).
