# Card Data & Schema

This directory contains the **Single Source of Truth (SSOT)** for all Cards, Items, and Encounters.
The data is stored in **YAML** format, which combines structured fields (Stats, Cost) with a **Mini-DSL** for game rules.

**Format**: YAML
**Extension**: `.yaml`
**Location**: `design/data/cards/**/*.yaml`

## Data Pipeline

1.  **Source**: YAML files in this directory.
2.  **Build**: The Haskell `card-compiler` tool validates these files and compiles them into a single JSON artifact.
3.  **Consumption**: The VTT (and potentially other tools) load the generated JSON.

## Card Categories

1.  **Deck Cards (`CoreCard`)**: Cards that go into a deck. They provide Stats (Red/Yellow/Blue) and contain a list of **Rules**.
2.  **Table Cards (`ItemCard`, `NatureCard`)**: Cards that stay in play (Item, Monster, Character). They provide Defense, Resilience, and passive capabilities.

## Schema Reference

**The authoritative schema is defined in the Haskell source code:**
[`Core.Card`](../../core/src/Core/Card.hs)

Refer to the Haskell types (`CoreCard`, `ItemCard`, `NatureCard`) for the exact list of required and optional fields.

### Key Concepts

- **Deck Cards (`CoreCard`)**:
  - Must have `stats` (Red/Yellow/Blue).
  - Use `rules` for active abilities (Attack, Defend, Action).
  - Use `cost` for play cost.

- **Table Cards (`ItemCard`, `NatureCard`)**:
  - Represent permanent state (Equipment, Monsters, Characters).
  - Use `defense` and `resilience` for durability.
  - Use `burden` to set the metabolic cost.
  - Use `traits` and `passive` for static effects.

## Syntax Reference

For semantic definitions of these rules, see `design/rules/reading-the-cards.md`.
This section defines the **strict syntax** required by the parser.

- **Resources**: `{Red}`, `{Yellow}`, `{Blue}`
- **Attack**: `Attack {Color}: Strength = {Color} (+/- Mod)`
  - _Example:_ `Attack {Red}: Strength = {Red} + 2`
- **Defend**: `Defend {Color} (| {Color})*: Strength = {Color} (+/- Mod)`
  - _Example:_ `Defend {Red}: Strength = {Red}`
  - _Example:_ `Defend {Red} | {Yellow}: Strength = {Yellow} + 1`
- **Action**: `Action: [Name] (Spend {Color} [Cost]) -> [Effect]`
  - _Example:_ `Action: Push Through (Spend {Red} 10) -> Remove this`
- **Task**: `Task: [Name] (Check {Color} [Diff]; Time [Duration]; Cost [Narrative]) -> [Effect]`
  - _Example:_ `Task: First Aid (Check {Blue} 3; Time 1 min) -> Remove this`
- **Trigger**: `When [Trigger] -> [Effect]`
  - _Example:_ `When removed -> Add 1 Wound`
- **Passive**: `Passive: [Bonus] [Condition]`
  - _Example:_ `Passive: +2 {Red} when attacking`
- **Stance**: `Stance ([Duration]) -> [Effect]`
- **Channel**: `Channel ([Duration]) -> [Effect]`

## Directory Structure

- `core/`: Core deck cards.
- `items/`: Equipment and Items.
- `pc/`: Player Character definitions.
- `monsters/`: Monster definitions.
- `generated_cards.json`: **DO NOT COMMIT**. Build artifact.
