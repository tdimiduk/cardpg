# Card Types

This document iterates on card types that interact with the **Resolution Phase**, moving away from the legacy "Defend Card" terminology.

## 1. Resolution Cards

**Concept:**
Cards played from hand during the Resolution Phase to describe **how** a character defends or performs an action.

- **Free Play:** Playing these does **not** cost an Action (you simply do it).
- **Cost:** The cost is the card itself (it leaves your hand). Particularly powerful cards may also require a resource cost which you pay with other cards from your hand as usual.
- **Modifier:** They usually apply a specific bonus or mechanic to the resolution check.

**Timing Subtypes:**

- **Form (Start of Resolution):** Played before any actions are resolved. Affects the character for the entire phase. (Renamed from "Stance" to avoid collision with Action-phase Stances).
  - _Example:_ "Iron Form: +1 Defense this round."
- **Reaction (Triggered):** Played in response to a specific event (usually an incoming attack).
  - _Example:_ "Parry: Use {Yellow} instead of {Red} for this defense."

### Examples

#### Lightning Dodge (Reaction)

_Context:_ Lighting mage character interacting with a force-based attack.

```
Trigger: When defending against a {Red} attack.
Effect: You may add {Yellow} values to {Red} for this defense check.
```

#### Iron Skin (Phase)

_Context:_ A toughened durability technique.

```
Trigger: Start of Resolution Phase.
Effect: +1 Defense against all attacks this round.
```

#### Desperate Block (Reaction)

_Context:_ Generic mitigation.

```
Trigger: When defending.
Effect: Add +6 to the total Strength of your flipped cards. (Reduces Impact by meeting the attack strength sooner).
```

---

## 2. Flip Triggers ("Instincts")

**Concept:**
Passive effects that trigger only when the card is **revealed (flipped)** from the deck during a resolution check (Defense or General Action).

- They represent training that has become instinctual—reflexes that happen without conscious "planning" from the hand.
- They do **not** trigger if the card is played from hand or discarded.

### Examples

#### Duck Behind Counter

_Context:_ Boss monster in their domain.

```
Flip Trigger: If this card is flipped while defending, defense succeeds automatically, flip no more cards but compute Impact as normal.
```

#### <name needed>

_Context:_ Environmental awareness.

```
Flip Trigger: If this card is flipped while defending, add +3 to the total Strength of this check.
```

#### Adrenaline Surge

_Context:_ Combat reflex.

```
Flip Trigger: If this card is flipped, you may immediately draw 1 card.
```
