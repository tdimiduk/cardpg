# Core Rules

## 1. Your Deck is Your Character

Your character is defined by a 24-card deck that serves as your stamina, skill pool, and health. Every significant action expends cards, and exhausting your deck incurs fatigue.

### The Three Colors

The numbers in the upper left of each card represent its strength in the game's three core Colors:

- **Red (Square):** Force, Endurance, Presence, Passion, Dominion
- **Yellow (Circle):** Speed, Precision, Perception, Cunning, Finesse
- **Blue (Diamond):** Intellect, Planning, Discipline, Lore, Intrigue

_(See [Colors of Action](colors-of-action.md) for how skills and activities map to each color)._

### Anatomy of a Card

- **Color Strengths (Upper Left):** Values for Red, Yellow, and Blue.
- **Resource Cost (Upper Right):** Additional cards required from hand to play this card as an Action Stack.
- **Rules Text:** Action type, modifiers, or trigger keywords (such as [[Attack]], [[Defend]], [[Stance]], or [[Passive]]).

---

## 2. Facing a Challenge

Whenever you face a challenge—whether it is an enemy attack, a crumbling ruin, or an iron door—resolution is **defender-centric**. The person facing the pressure is always the one who flips cards and absorbs the outcome:

- **Facing an Enemy Attack:** When an enemy strikes, they set the [[Strength]]; _you_ meet the blow, absorb the [[Impact]], and suffer any [[Consequences]]. (When _you_ attack an enemy, you set the Strength, and _they_ face it).
- **Weathering an Environmental Hazard:** When a crumbling ledge gives way or a trap springs, the environment presents a [[Strength]] that you must endure.
- **Tackling an Obstacle:** When you climb a wall, pick a lock, or sprint past guards, the task sets a [[Strength]] representing the physical or mental effort required to succeed.

Whatever the challenge, facing it follows the same four steps:

1. **Meet the Strength:** The threat or task presents a target [[Strength]] in a specific [[Color]]. You meet or exceed that Strength by adding together card values in that Color (playing prepared cards from hand or flipping cards from your deck).
2. **Impact:** Your [[Impact]] is the number of cards in your **flipped stack**. Prepared cards played from hand (such as Defend cards or Action Stacks) do not add to your Impact.
3. **Suffer Consequences:** If you flip cards from your deck, check your active armor or gear for your [[Defense]] and [[Resilience]] ratings (both default to **1** if unarmored):
   - Group your flipped cards into stacks equal to your [[Defense]]. You suffer **1 Consequence** for each completed stack. (Leftover cards that do not complete a stack cause no harm and are discarded).
   - Arrange your Consequence cards on the table in rows of width equal to your [[Resilience]]. The first row holds [[Severity 1]] consequences (minor friction). Filling that row escalates new consequences to [[Severity 2]] (serious injury/vulnerability). Filling the second row pushes you to [[Severity 3]] (incapacitated).
4. **The Fatigue Cycle:** When you must draw or flip a card and your deck is empty—or voluntarily outside a resolution—perform a Fatigue Cycle: add 2 [[Fatigue]] cards (plus your total active [[Burden]] from heavy gear) to your expended pile, reshuffle it into a new deck, and draw or flip the required card.

---

## 3. In Conflict: Crisis Time

Crisis Time resolves combat, chases, and tense, second-by-second struggles. Play proceeds in simultaneous rounds.

### Round Structure

1. **Plan Step:** Each player draws 2 cards from their deck. Secretly choose your play for the round:
   - **Play an Action:** Commit an Action card from hand (such as an Attack or Stance) along with any cards required to pay its resource cost.
   - **Pass:** Take no action this round to conserve cards.
   - _Movement:_ Narrative positioning and maneuvering are integral parts of your declared action intent.
2. **Resolve Step:** All participants reveal their actions simultaneously:
   - Attackers declare their targets and attack Color.
   - Defenders resolve Defend actions to absorb incoming attacks.
   - All declared actions resolve in parallel. Consequences take effect at the end of the Resolve Step.
3. **Cleanup:** Discard all cards played or flipped during the round to your expended pile, unless an active card specifies otherwise (such as persistent Stances).

### Attack Actions

To attack, play an Attack card from your hand into an [[Action Stack]] with additional cards from your hand equal to its printed Resource Cost. The colored icon on the Attack card indicates the attack's [[Color]]. The attack's [[Strength]] equals the sum of that Color on all cards in the stack, plus the top card's printed modifier. The target must then face the attack (see [Facing a Challenge](#2-facing-a-challenge)).

_(To improvise maneuvers without a printed Action card, see the [Narrative Actions Module](modules/narrative-actions.md))._

### Defend Actions

When targeted by an attack, you face the strike by meeting its Strength in the declared Color (see [Facing a Challenge](#2-facing-a-challenge)):

1. **Defend from Hand (Optional):** You may play a Defend card from your hand, paying any printed Resource Cost from hand. It will add [[Strength]] to your defense or otherwise modify the resolution. Cards played from hand do not add to your Impact.
2. **Flip from Deck:** If Strength is not yet met, flip cards from your deck one by one into a **flipped stack** until the total meets or exceeds the attack's Strength.
3. **Suffer Consequences:** Count the cards in your flipped stack (your Impact) and resolve consequences against your Defense and Resilience as normal.

### Transitions

- **Entering Crisis (Mutual Awareness):** Pick up your [[Ready Hand]] (both face-down cards and any face-up guard) as your starting hand for Round 1.
- **Entering Crisis (Surprise):** If caught unaware or marching at ease (Ready Hand size 0), you enter Crisis Time with an empty hand, drawing only your 2 round cards when Round 1 begins.
- **Exiting Crisis:** When tension breaks, all characters discard any cards remaining in hand to their expended pile.

---

## 4. In Exploration: Adventuring Time

Adventuring Time is used for travel, investigation, dungeon exploration, and downtime.

### The Ready Hand & Effort Cycles

You do not hold a hand during Adventuring Time. Instead, you maintain a [[Ready Hand]] of 0 to 4 cards on the table, representing your vigilance:

- **Face-Down Cards:** Dealt from the top of your deck and kept face down.
- **Face-Up Guard:** Up to 1 card in your Ready Hand may be kept face up as a prepared stance or readied action (prepared via roughly one minute of quiet focus outside of crisis).
- **Effort Cycles:** Maintaining vigilance burns stamina. Periodically, the GM will call an **Effort Cycle** to **flush** your Ready Hand:
  1. Discard your Ready Hand to your expended pile. _(To retain a face-up guard, discard 2 cards from the top of your deck to your expended pile instead)._
  2. Redraw face down from your deck back to your chosen Ready Hand size (0 to 4). If your chosen size is 0 (marching at ease), Effort Cycles cost you no cards.

### General Actions

Tasks with meaningful stakes outside combat (climbing a cliff, picking a lock, calming a beast) are resolved as [[General Actions]]. You face the obstacle using the steps in [Facing a Challenge](#2-facing-a-challenge), with one key assumption: success is the default; the resolution determines the physical and stamina _cost_ of that success.

The GM or challenge sets the [[Color]] and [[Strength]]:

1. **Commit Ready Hand (Optional):** You may resolve the task using deck flips alone, or pick up your Ready Hand. If picked up, you may play an Action card from hand as an Action Stack (card + Cost) to modify the check (e.g. bonus Strength or Defense). Cards in the Action Stack do not count toward your flipped stack.
2. **Meet Strength:** Flip cards from your deck into a flipped stack until the Strength is met. If you committed your Ready Hand, instead of a flip you may add a card from your [[Ready Hand]] to the flipped stack.
3. **Suffer Consequences:** Count your flipped stack (your Impact) and resolve consequences against your Defense and Resilience.
4. **Flush:** If you picked up your Ready Hand, discard remaining hand cards and flush back to your chosen Ready Hand size.

---

## 5. Reference: Harm Types & Keywords

### Status Cards vs. Condition Cards

- **Status Cards (In Your Deck):** Represent general systemic wear-and-tear (_Fatigue_, _Minor Wound_). They enter your expended pile, shuffle into your deck during Fatigue Cycles, and clog your draws with low Color values.
- **Condition Cards (On the Table):** Represent acute tactical injuries or setbacks (_Sprained Ankle_, _Concussion_, _Pinned_). They sit face up on the table, imposing persistent penalties until treated or cleared through narrative recovery.

### Keywords and Timing

- **`Passive:`** Continuously active while the card is in play on the table or in hand.
- **Triggered Keywords (e.g., `Resolve:`):** Checked at the start of the matching round step. If the card is active when the step begins, its ability queues and resolves simultaneously with all declared actions in that step.
