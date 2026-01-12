---
description: Switch context to Haskell backend development
---

# Context: Haskell Backend

- **Directories**: `core` (Core logic), `server` (Backend server), `api` (API definitions)
- **Build**: `cabal build core`, `cabal build server`, `cabal build api`
- **REPL**: `cabal repl core`, `cabal repl server`
- **Testing**: `cabal test core`, `cabal test server`
- **Style**: Functional, strict types. Use `deriveJSON` via Template Haskell where possible.

## Development Server

The project uses a `process-compose` based development server that manages both the backend and frontend with hot reloading via `ghciwatch`.

- **Command**: `./scripts/dev`
- **Logs**: `./scratch/logs/process-compose.log`

**Agent Instructions**:

1.  **Assume Running**: Provide commands/edits assuming the dev server is already running in the background.
2.  **Check Status**: If you encounter connection errors or need to verify the state, check if the server is running.
3.  **Start if Missing**: If it is NOT running, start it using `./scripts/dev`.
4.  **Debug via Logs**: Tail the log file `./scratch/logs/process-compose.log` to see compilation errors and runtime logs.
