# Coding Standards & Practices

This document outlines the architectural patterns and coding standards for the CardPG project. Future development and AI Agents should adhere to these principles to maintain codebase stability, safety, and maintainability.

## 1. Haskell General

### 1.1 Strong Typing Over Strings

**Rule**: Never use `String` or `Text` for identifiers, keys, or enumerations.
**Why**: Stringly-typed code is prone to runtime errors and invalid states.
**Practice**:

- Use `newtype` for IDs (e.g., `CardInstanceId`, `ActorId`).
- Derive `FromJSON`/`ToJSON` via Aeson to handle serialization.
- Use generic `Game.hs` logic that accepts these typed identifiers.

### 1.2 Safe Parsing & Input Handling

**Rule**: **NEVER** use `read` on external input (Client messages, files, env vars).
**Why**: `read` throws exceptions on failure, causing the server to crash.
**Practice**:

- Use `readMaybe` for simple text parsing with explicit error handling.
- Prefer `Aeson` (`decode`, `FromJSON`) for structured data.
- Validate inputs at the boundary (e.g., inside `Types.hs` or the API layer) before passing them to `Logic`.

### 1.3 State Encapsulation

**Rule**: Logic functions should operate on specific sub-states, not the entire `GameState` if possible.
**Practice**:

- Functions in `Logic.hs` should use `GameM` but accept specific arguments (e.g., `CardInstanceId`) rather than extracting them manually from raw inputs inside the logic.

### 1.4 OverloadedRecordDot

**Rule**: Use record dot syntax for field access.
**Why**: Cleaner, more readable code; avoids field accessor name collisions.
**Practice**:

```haskell
-- Preferred: dot syntax
actor.coreState.planned

-- Avoid: selector functions
planned (coreState actor)
```

- `OverloadedRecordDot` is enabled project-wide in all `.cabal` files.
- For nested updates, continue using lenses (see §1.5).

### 1.5 Lenses for State Updates

**Rule**: Use `Control.Lens` operators for nested state updates in `Logic` modules.
**Why**: Immutable updates to deeply nested state are verbose without lenses.
**Practice**:

```haskell
-- Reading with dot syntax
actor.coreState.hand

-- Updating with lenses
actor & coreState . hand %~ (card :)
```

- Use dot syntax for reads, lenses for writes.
- Import `Control.Lens` qualified or with explicit imports to avoid namespace pollution.

---

## 2. Reflex Frontend (`client`)

### 2.1 FRP Principles

**Rule**: Think in terms of `Event`s and `Dynamic`s, not callbacks.
**Why**: FRP provides declarative, composable UI logic.
**Practice**:

- `Dynamic t a` — time-varying values (use for state)
- `Event t a` — discrete occurrences (use for actions/triggers)
- Avoid `performEvent_` for pure transformations; use `fmap`/`ffor`.

### 2.2 API Requests with Requester

**Rule**: Use `Requester t m` constraint with `ApiRequest` GADT for server communication.
**Why**: Type-safe request/response pairing via `reflex-gadt-api`.
**Practice**:

```haskell
-- Constraint alias from Frontend.Util
type ApiRequester t m = (Requester t m, Request m ~ ApiRequest, Response m ~ Either Text)

-- Making requests and handling responses
let msgEvt = ... -- Event t Text
responses <- requesting $ SendChat actorId <$> msgEvt
let (errors, successes) = fanEither responses
```

- Requests are defined in `Api.Request` as a GADT.
- Responses are automatically typed based on the request constructor.

### 2.3 Widget Signatures

**Rule**: Use constraint-based signatures for widgets, not concrete monad stacks.
**Practice**:

```haskell
myWidget
  :: ( DomBuilder t m
     , PostBuild t m
     , MonadHold t m
     , MonadFix m
     , ApiRequester t m
     )
  => Dynamic t SomeState
  -> m (Event t SomeAction)
```

- This enables widget reuse and testing.
- Common constraints: `DomBuilder`, `PostBuild`, `MonadHold`, `MonadFix`.

### 2.4 Widget Config Pattern

**Rule**: Bundle required data into a config type; validate availability _before_ rendering.
**Why**: Widgets shouldn't do messy `Maybe` checks for data that must be present to render.
**Practice**:

```haskell
-- Define a config with all required data
data PhaseDisplayConfig t = PhaseDisplayConfig
  { phase :: Dynamic t Phase
  , readyCount :: Dynamic t Int
  , totalCount :: Dynamic t Int
  }

-- Widget receives validated, non-Maybe data
phaseDisplayWidget :: (...) => PhaseDisplayConfig t -> m ()
phaseDisplayWidget config = do
  dynText $ tshow <$> config.phase  -- No Maybe checks needed
```

- Construct the config at a higher level where you can gate on data availability.
- The widget can assume all fields are present and focus on rendering logic.

---

## 3. Server (`cardpg-server`)

### 3.1 Database with Beam

**Rule**: Use Beam for type-safe database queries.
**Why**: Compile-time query validation, no raw SQL strings.
**Practice**:

```haskell
-- Table definition
data GameT f = Game
  { gameId :: C f Text
  , gameState :: C f (PgJSONB Value)
  , ...
  }
  deriving (Generic, Beamable)

-- Queries
runSelectReturningOne $ select $
  filter_ (\g -> gameId g ==. val_ gId) (all_ (games cardpgDb))
```

- Use `beam-automigrate` for schema migrations.
- Store complex state as `PgJSONB Value` when full normalization isn't warranted.

### 3.2 Connection Pooling

**Rule**: Always use connection pools, never raw connections.
**Practice**:

```haskell
withResource pool $ \conn -> do
  runBeamPostgres conn $ ...
```

---

## 4. Architecture Patterns

### 4.1 Command Pattern

- Game actions are strictly typed `Command` enums.
- Each command carries fully typed payloads (e.g., `CardInstanceId` not `String`).

### 4.2 Pure Core / Effectful Shell

- `cardpg-core` contains **no IO** — all logic is pure and testable.
- `cardpg-server` handles all effects (WebSocket, DB, file IO).

### 4.3 GADT-Based APIs

- Client-server API uses GADTs (`ApiRequest`) for type-safe request/response pairing.
- Each request constructor determines its response type.
