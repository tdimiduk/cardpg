# Reading the Cards

This guide explains how to interpret the rules text found on Action, Item, and Status cards.

## The Golden Rule

**Specific beats General.** If a card's text contradicts the Core Rules, the card takes precedence.

## Action Types

Cards use specific keywords to tell you **when** and **how** they can be used.

### 1. Crisis Actions (`Attack`, `Defend`, `Action`)

These are used during **Crisis Time** (combat or tense situations). They happen instantly or within seconds.

- **`Attack {Color}: Strength = {Color} (+/- Mod)`**

  - _Example:_ `Attack {Red}: Strength = {Red} + 2`
  - **Usage:** Play this card during your turn to attack.
  - **Cost:** You must pay the card's printed Resource Cost (top right).
  - **Effect:** Generates Strength equal to the formula to overcome an enemy's Defense.

- **`Defend {Color}: Strength = {Color} (+/- Mod)`**

  - _Example:_ `Defend {Red}: Strength = {Red} + 1`
  - **Usage:** Play this card in response to an attack.
  - **Cost:** You must pay the card's printed Resource Cost.
  - **Effect:** Generates Strength equal to the formula to block incoming damage. You count it's color value towards meeting the attack's strength, but do not count the card towards the impact of the defense.
  - **Effect:** Rules text that may further modify the defense.

- **`Action: [Name] (Spend {Color} X) -> [Effect]`**
  - **Usage:** Play this card during your turn to perform a special maneuver.
  - **Cost:** You must discard cards from your hand until their total value in the specified `{Color}` equals or exceeds `X`.
  - **Effect:** Happens automatically once the cost is paid.
  - _Example:_ `Action: Push Through (Spend {Red} 10) -> Remove this card.`

### 2. Narrative Tasks (`Task`)

These are used during **Adventuring Time** (exploration, downtime, or safe moments). They take minutes or hours to complete.

- **`Task: [Name] ({Color} X, [Time]) -> [Effect]`**
  - **Usage:** You spend the specified `[Time]` performing the activity.
  - **Resolution:** You must perform a **General Action** check. Flip cards from the top of your deck until their total `{Color}` value equals or exceeds `X`.
  - **Risk:** If you flip too many cards, you may suffer Consequences (like Fatigue or Injury) based on your Defense.
  - _Example:_ `Task: First Aid ({Blue} 3, 1 min) -> Remove this card.`

### 3. Passive & Triggered Rules

These rules are always active as long as the card is in play (on the table or in your hand, depending on the card type).

- **`Passive: ...`**

  - **Usage:** Always in effect. Usually provides a bonus to stats or armor.
  - _Example:_ `Passive: +1 Defense against Physical attacks.`

- **`When [Trigger] -> [Effect]`**
  - **Usage:** Happens automatically immediately after the `[Trigger]` condition is met.
  - **Mandatory:** You cannot choose to ignore this effect unless another rule explicitly allows you to "Cancel" it.
  - _Example:_ `When removed -> Add 1 Wound to your expended pile.` (This happens no matter _how_ you removed the card).

## Reading Symbols

- **{Red} (Square):** Force, Endurance, Presence.
- **{Yellow} (Circle):** Speed, Precision, Cunning.
- **{Blue} (Diamond):** Intellect, Planning, Discipline.
