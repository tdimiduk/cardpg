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

Each goblin spends its 2 Impact to draw 1 candidate card from the **Severity 2** deck (cost 2 Impact each):

1. **Goblin 1 Draw (Severity 2)**: `Rattled Guard` (Tags: `combat`, `equipment`, `armor`)
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
   - Under an unbatched per-attack resolution model, each 2-Impact hit against Pool Size 3 would have left 2 unfilled slots ("No Consequence"), allowing the Squire to completely ignore all three hits without sustaining any conditions.
   - Under **Individual Spend into a Shared Round Pool**, each goblin's 2 Impact purchases 1 Severity 2 card. Together, the three goblins contribute three Severity 2 candidates, fully filling the Squire's Pool Size 3.
   - This ensures that coordinated multi-attacker pressure still threatens armored targets without allowing fractional 1-Impact hits to combine into unnatural instant trauma.

3. **Armor Protection is Meaningful**:
   - The Squire's armor (Pool Size 3) required 3 separate cards of Severity 2 to guarantee a tactical impairment.
   - If each goblin had only generated 1 Impact (e.g. if the Squire had higher defensive card values in hand), the goblins could only have purchased Severity 1 cards, cushioning the Squire against any Severity 2 injury for that round.
   - Conversely, if the Squire had been unarmored (Pool Size 2), two 2-Impact hits would have been sufficient to lock in Severity 2, leaving the third goblin's card as surplus curation leverage.
