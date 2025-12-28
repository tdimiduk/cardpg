# Coding Standards & Practices

This document outlines the architectural patterns and coding standards for the CardPG project. Future development and AI Agents should adhere to these principles to maintain codebase stability, safety, and maintainability.

## 1. Haskell Backend (`cardpg-server`, `cardpg-core`)

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

## 2. TypeScript Frontend (`vtt-react`)

### 2.1 Schema-Driven Development

**Rule**: Trust and use the generated types (`generated/types.ts`).
**Why**: The backend is the source of truth. Manual interfaces drift and break.
**Practice**:

- Run `just gen-types` after changing backend types.
- Use `zod` schemas (if available) or strict casting to generated interfaces.
- Avoid `as unknown` casting unless absolutely necessary for temporary hydration hacks.

### 2.2 Zod Validation (Recommended)

**Rule**: Validate server messages at runtime.
**Practice**:

- Use `generated/types.zod.ts` to parse incoming WebSocket messages.
- Fail fast with clear errors if the server sends unexpected data, rather than crashing in a React render cycle.

## 3. General Architecture

### 3.1 Command Pattern

- Game Actions are strictly typed `Command` enums.
- Each command must carry fully typed payloads (e.g., `uuid` not `string`).

### 3.2 Immutability

- Haskell state is immutable by default.
- React state should use `immer` (via `zustand`) or standard immutable patterns. Avoid mutating refs or objects directly.
