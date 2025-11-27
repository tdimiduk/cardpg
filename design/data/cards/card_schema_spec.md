# Card Data Schema Specification

## Overview

This document defines the schema for CardPG card data.
**Format**: YAML
**Extension**: `.yaml`
**Location**: `design/data/cards/**/*.yaml`

## Card Categories

**Category is inferred from the file path** (e.g., `cards/core/` -> Deck, `cards/items/` -> Table).

1.  **Deck Cards**: Cards that go into a deck. They provide Stats (Red/Yellow/Blue) and contain a list of **Rules**.
2.  **Table Cards**: Cards that stay in play (Item, Monster, Character). They provide Defense, Resilience, and passive capabilities.

## Field Definitions

### Common Fields

- `name` (Required): Display name.
- `id` (Optional): Kebab-case unique identifier. **Defaults to slugified name**.
- `tags` (Optional): List of strings.
- `flavor` (Optional): Multi-line string.

### 1. Deck Cards (The "Hand")

**Types**: `Action`, `Defense`, `Ability`, `Fatigue`

- `stats` (Required): The Red/Yellow/Blue values this card contributes when played or flipped.
  ```yaml
  stats:
    red: 2
    yellow: 0
    blue: 1
  ```
- `cost` (Optional): Resources required to play. `null` or missing means it cannot be played (Status/Resource only).
  ```yaml
  cost:
    resources: 2
  ```
- `rules` (Optional): List of Mini-DSL strings defining the card's capabilities.
  - **Attack**: `Attack {Color}: Strength = {Color} + Mod`
  - **Defend**: `Defend {Color}: Strength = {Color} + Mod`
  - **General**: `Action: [Narrative Description]` (e.g., "Sleep 2 hours to remove this")
  - **Passive**: `Passive: [Bonus] [Condition]` (e.g., "Passive: +2 {Red} when attacking")
  - **Stance**: `Stance: [Duration]`
  - **Channel**: `Channel: [Duration]`
  - **Prime**: `Prime: [Trigger] -> [Reaction]`

### 2. Table Cards (The "Board")

**Types**: `Item`, `Monster`, `Character`

- `defense` (Optional): Integer. Defense value provided (e.g., Armor).
- `resilience` (Optional): Integer. Resilience value provided.
- `traits` (Optional): List of passive rules or keywords.
- `abilities` (Optional): List of special abilities (Mini-DSL).

## Example: Deck Card (`core/basic_martial.yaml`)

```yaml
- name: Strike
  type: Action
  tags: [Basic, Combat]
  stats: { red: 3, yellow: 2, blue: 2 }
  cost: { resources: 2 }
  rules:
    - "Attack {Red}: Strength = {Red} + 2"
  flavor: "A solid blow."

- name: Parry
  type: Defense
  tags: [Combat, Defense]
  stats: { red: 1, yellow: 4, blue: 2 }
  rules:
    - "Defend {Red}|{Yellow}: Strength = {Yellow}"
    - "Passive: +1 {Yellow} when defending"
  flavor: "Turning their force aside."
```

## Validation Rules

1.  **Deck Cards** MUST have `stats`.
2.  **Table Cards** MUST NOT have `stats`.
3.  `rules` strings must parse successfully against the DSL grammar defined by `CardPG.Core.Card.Rule`.
