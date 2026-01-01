# Proposal: Standardized Stats Record

## Objective

Unify the handling of Red/Yellow/Blue resource values across the codebase to remove duplicated case logic and provide standard accessors/lenses.

## Current State

- `ResourceType` (Red | Yellow | Blue) is defined in `Primitives.hs`.
- `Stats` { red :: Int, yellow :: Int, blue :: Int } is defined in `Card.hs` (specific to Int).
- `DefenseDetails` (Wire type) has flattened `red`, `yellow`, `blue` fields.
- `stackPower` and `attackAction` contain manual case logic matching `ResourceType` to fields.

## Proposed Changes

### 1. Polymorphic `Stats` Record

Move `Stats` to `CardPG.Core.Primitives` (or kept in `Card`) and make it polymorphic.

```haskell
data Stats a = Stats
  { red :: a
  , yellow :: a
  , blue :: a
  }
  deriving stock (Eq, Show, Generic, Functor, Foldable, Traversable)

-- Aeson instances
instance ToJSON a => ToJSON (Stats a) where
  toJSON = genericToJSON cardpgJsonDef
instance FromJSON a => FromJSON (Stats a) where
  parseJSON = genericParseJSON cardpgJsonDef
```

### 2. Standard Accessor & Lenses

Provide a utility to access a field by `ResourceType`.

```haskell
getStat :: ResourceType -> Stats a -> a
getStat Red    = (.red)
getStat Yellow = (.yellow)
getStat Blue   = (.blue)

-- Lens support (if needed)
statLens :: ResourceType -> Lens' (Stats a) a
statLens Red    = #red
statLens Yellow = #yellow
statLens Blue   = #blue
```

### 3. Usage Updates

#### `CoreCard`

Update `CoreCardT` to use `Stats Int`.

#### `DefenseDetails` (Wire)

Refactor `DefenseDetails` to group color stats.

```haskell
data DefenseDetails = DefenseDetails
  { values :: Stats Int  -- Was red/yellow/blue flattened
  , impact :: Int
  , consequencesFromDefense :: Int
  , nextSeverity :: Int
  }
```

_Note: This changes the JSON structure sent to the frontend._

#### `SpecialDefend`

Refactor `SpecialDefend` to be `Stats ResourceType`.

```haskell
type SpecialDefend = Stats ResourceType
```

### 4. Logic Refactor (`stackPower`, etc.)

Replace case expressions with `getStat`.

```haskell
-- Old
relevantStat c = case power.source of
  Red -> c.stats.red
  ...

-- New
relevantStat c = getStat power.source c.stats
```

## Benefits

- **Typesafety**: Guarantees all 3 colors are handled.
- **Brevity**: Removes verbose case expressions.
- **Consistency**: Single source of truth for "color-based value container".
- **Flexibility**: Can hold `Int`, `ResourceType`, `Text`, etc.

## Drawbacks / Risks

- **Frontend Breaking Change**: Changing `DefenseDetails` or `CoreCard` JSON structure requires frontend updates.
  - _Mitigation_: We are already updating frontend types via codegen.
- **Migration Effort**: Need to update all construction sites of `Stats` and `DefenseDetails`.

## Implementation Plan

1.  **Backend**:
    - Move/Update `Stats` definition.
    - Add `getStat` accessor.
    - Update `ActorState` / `DefenseDetails` wire types.
    - Update logic in `Combat.hs`.
2.  **Frontend**:
    - Regenerate types (`codegen`).
    - Update `SidebarRight` to access `defenseDetails.values.red` etc.
    - Update `Card` components if `stats` structure changes (it shouldn't if it was already `Stats`).

## Open Questions

- Should `DefenseDetails` keep flattened fields for backward compatibility, or is nested `values` (or `stats`) preferred?
  - _Recommendation_: Nest it. It clarifies that these 3 values are the "color stats".
