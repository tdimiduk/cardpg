# Play Trace 2: Armored Knight vs. Power Strike (Armor & Pierce Dynamics)

## Context & Combatants

- **Setting**: Heavy melee engagement in a ruined hall.
- **Attacker**: Orc Chieftain (Brute Red deck, wielding a Greatmaul).
- **Defender**: Knight (Shield-Fighter deck, wearing **Full Harness**).

### Armor & Gear Profile

- **Full Harness**:
  - Burden: 2
  - Rules:
    - _Passive 1_: Your consequence pool size is 4. An attack with Pierce 6 can ignore this passive.
    - _Passive 2_: Your consequence pool size is 3. An attack with Pierce 12 can ignore this passive.
    - _Armor Integrity Rule_: The first time a consequence pool would include a card of severity 4 or higher, damage (flip) this armor instead and the attacker must choose a different consequence.

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
  - Pierce is 4 (< 6). Passive 1 holds: **Defender Pool Size ($N$) = 4**.
- **Attacker Budget**: **3 Impact**.
- **Candidate Draws**:
  - Attacker spends 3 Impact to draw 3 candidate cards from Severity 1: `[Near Miss (Sev 1), Poor Footing (Sev 1), Out of Breath (Sev 1)]`.
- **Pool Curation (The "I Cut" Step)**:
  - The defender requires $N = 4$ cards in the pool.
  - Because the attacker only has 3 candidate cards, the 4th option is **implicitly filled with "No Consequence"**.
  - **Pool Presented to Defender**: `[Near Miss (Sev 1), Poor Footing (Sev 1), Out of Breath (Sev 1), No Consequence]`.

### 4. Defender Suffers a Consequence (The "You Choose" Step)

- Knight chooses **No Consequence**.
- **Narrative & Tactical Outcome**: The greatmaul crashes violently against the fluted steel plate, ringing the knight's ears and expending 3 cards of stamina/endurance, but the armor's structural coverage (Pool Size 4) prevents any debilitating wound or condition from landing.

---

## Exchange B: Overwhelming Sunder Strike (Pierce 6)

In the subsequent round, the Orc Chieftain commits everything to a specialized anti-armor blow.

### 1. Attack Declaration

- Orc Chieftain plays `Overhead Skull-Cracker`:
  - Attack: {Red} Str = {Red} + 5; **Pierce 6**; Cost: 3
  - Stack: Top card ({Red: 4}) + 3 Resources ({Red: 3, Red: 3, Red: 4}) + 5 modifier = **19 Red (Pierce 6)**.

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

- **Full Harness Check against Pierce 6**:
  - Pierce 6 meets the Pierce 6 threshold! Passive 1 is **ignored**.
  - Passive 2 remains active (Pierce 6 < 12) -> **Defender Pool Size ($N$) drops to 3**.
- **Attacker Budget**: **5 Impact**.
- **Candidate Draws (Spend 5 Impact)**:
  - Spend 2 Impact: Draws from Severity 2 deck $\to$ `Rattled Guard` (Severity 2, Tags: `combat`, `equipment`, `armor`).
    - _Passive_: Place this card on your equipped armor. While on your armor, your armor's first Pierce threshold is ignored by all incoming attacks.
    - _Action_: Re-buckle Under Fire (Spend {Yellow} 25) -> Remove this.
    - _Task_: Refit Harness & Tighten Straps (Check {Red} 15; Time 15 min; Requires Repair Tools) -> Remove this.
  - Spend 2 Impact: Draws from Severity 2 deck $\to$ `Strained Offense` (Severity 2, Tags: `physical`, `arms`, `combat`).
    - _Passive_: You must expend 1 card from your hand whenever you declare an Attack Action.
    - _Action_: Force Through Spasm (Spend {Red} 20) -> Remove this.
    - _Task_: First Aid & Muscle Wrap (Check {Blue} 15; Time 1 hour; Cost Bandage; Requires Splint) -> Remove this.
  - Spend 1 Impact: Draws from Severity 1 deck $\to$ `Slightly Battered` (Severity 1, Tags: `physical`, `injury`).
    - _Passive_: The Impact of all future defenses against you is increased by 1.
    - _Action_: Shake Off Impact (Spend {Red} 15) -> Remove this.
    - _Task_: Catch Breath & Tend Bruises (Time 5 min) -> Remove this.
- **Pool Curation (The "I Cut" Step)**:
  - The defender requires $N = 3$ cards.
  - Attacker presents all 3 drawn candidate cards to the defender:
  - **Pool Presented to Defender**: `[Rattled Guard (Sev 2), Strained Offense (Sev 2), Slightly Battered (Sev 1)]`.

### 4. Defender Suffers a Consequence (The "You Choose" Step)

- Knight is presented with `[Rattled Guard, Strained Offense, Slightly Battered]`.
- Knight selects **`Slightly Battered`** (Severity 1) to avoid the debilitating offensive taxes of `Strained Offense` and the armor vulnerability of `Rattled Guard`.
- Unselected cards (`Rattled Guard`, `Strained Offense`) are returned to the Severity 2 deck.

---

## Key Insights from Trace 2

1. **Armor as Pool Expansion is Elegant and Intuitive**:
   - Instead of tracking an abstract arithmetic divisor like `floor(Impact / Defense)`, armor directly acts as **insulation against concentrated harm**.
   - With Pool Size 4, an attacker needs at least 4 Impact to deal even a Sev 1 wound, and 8 Impact to force a Sev 2 wound.
2. **Pierce Translates Naturally**:
   - Pierce thresholds (e.g. Pierce 6) reduce the pool size directly (from 4 down to 3, or down to 2), shrinking the defender's buffer and allowing the attacker to concentrate Impact into fewer, higher-severity slots.
3. **Player Agency Under Pressure**:
   - The defender always has a choice among the offered consequences, allowing the knight to trade off deck pollution (`Pain`/`Injury`) against debilitating tactical conditions (`Breached Guard`).
