---
description: Switch context to Haskell backend development
---

# Context: Haskell Backend

- **Directories**: `core` (Core logic), `server` (Backend server), `api` (API definitions)
- **Build**: `cabal build core`, `cabal build server`, `cabal build api`
- **REPL**: `cabal repl core`, `cabal repl server`
- **Testing**: `cabal test core`, `cabal test server`
- **Style**: Functional, strict types. Use `deriveJSON` via Template Haskell where possible.

## Agent Skills

- **`dev_server`**: Manage the env (start/check logs). ALWAYS ensure it's running.
