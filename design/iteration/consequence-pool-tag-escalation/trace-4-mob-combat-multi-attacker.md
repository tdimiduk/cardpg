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

### Total Round Impact Tally

- **Total Flipped Cards**: 6 cards expended from deck.
- **`Total Round Impact`**: $2 + 2 + 2 = \mathbf{6\text{ Impact}}$.

---

## 3. Draw Candidate Consequences & Curate Pool (Single Batched Pool)

Because all three attacks targeted the Squire during the same Crisis round, the attackers draw candidates using a single shared budget.

- **Defender's Consequence Pool Size ($N$)**: **3** (set by Padded Gambeson).
- **Attackers' Shared Budget**: **6 Impact**.

### Candidate Draws

The GM (controlling the goblins) spends 6 Impact to draw 3 candidate cards from the **Severity 2** deck (cost $2 + 2 + 2 = 6$):

1. **Candidate 1 (Severity 2)**: `Rattled Guard` (Tags: `combat`, `equipment`, `armor`)
   - _Passive_: Place this card on your equipped armor. While on your armor, your armor's first Pierce threshold is ignored by all incoming attacks.
   - _Action_: Re-buckle Under Fire (Spend {Yellow} 25) -> Remove this.
   - _Task_: Refit Harness & Tighten Straps (Check {Red} 15; Time 15 min; Requires Repair Tools) -> Remove this.

2. **Slot 2 (Severity 2)**: `Strained Offense` (Tags: `physical`, `arms`, `combat`)
   - _Passive_: You must expend 1 card from your hand whenever you declare an Attack Action.
   - _Action_: Force Through Spasm (Spend {Red} 20) -> Remove this.
   - _Task_: First Aid & Muscle Wrap (Check {Blue} 15; Time 1 hour; Cost Bandage; Requires Splint) -> Remove this.

3. **Slot 3 (Severity 2)**: `Afraid` (Tags: `fear`, `mental`)
   - _Passive_: You must expend 1 card from hand to make a melee attack or willingly move closer to a foe.
   - _Action_: Martial Fury Surge (Spend {Red} 25) -> Remove this.
   - _Task_: Center Yourself (Check {Blue} 15; Time 5 min) -> Remove this.

---

## 4. Resolve Escalations

- The Squire has no prior conditions in play on the table.
- No escalations trigger. The pool remains `{Rattled Guard, Strained Offense, Afraid}`.

---

## 5. Defender Suffers Exactly 1 Consequence

- **Pool Presented to Defender**:
  1. `Rattled Guard` (Severity 2 — Armor degradation)
  2. `Strained Offense` (Severity 2 — Offensive hand card tax)
  3. `Afraid` (Severity 2 — Movement and engagement penalty)

- **Defender's Tactical Choice**:
  - The Squire weighs the options: `Strained Offense` would cripple offensive tempo, and `Afraid` would prevent pressing the attack against the goblins.
  - The Squire chooses **`Rattled Guard`** (Severity 2).
  - The card is placed directly onto the Squire's **Padded Gambeson** card on the table.
  - The remaining unselected cards (`Strained Offense`, `Afraid`) are returned to the Severity 2 deck.

---

## Analysis & Key Insights

1. **Table Ergonomics & Speed**:
   - The defender made 6 flips in rapid succession during the defense step.
   - The GM performed **a single pool construction** and drew 3 cards at once.
   - The defender made **one single decision**.
   - This prevents the sluggish stop-and-go pattern of resolving 3 separate drafting rounds within a single turn.

2. **Swarm Viability vs. Armor Soak**:
   - Under a separate-pool model, each 2-Impact hit against Pool Size 3 would have left an unfilled slot ("No Consequence"), allowing the Squire to completely ignore all three hits without sustaining any conditions.
   - Under **Batched Round Resolution**, the collective pressure of 3 simultaneous attackers generates 6 Impact, successfully surpassing the armor's soak threshold ($3 \times 2 = 6$) to guarantee a Severity 2 consequence.
   - This preserves the tactical danger of mob combat and coordinated flanking.

3. **Armor Protection is Meaningful**:
   - Even though the goblins generated 6 Impact, the Squire's armor (Pool Size 3) forced that 6 Impact to be distributed across 3 slots ($2 + 2 + 2$).
   - If the Squire had been unarmored (Pool Size 2), 6 Impact could have been allocated as $3 + 3$ (forcing a Severity 3 injury like `Hamstrung` or `Knocked Prone`) or $4 + 2$.
   - The armor successfully cushioned the blow down to Severity 2.
