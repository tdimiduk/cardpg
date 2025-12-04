---
description: Switch context to Haskell backend development
---

# Context: Haskell Backend

- **Directories**: `cardpg-core` (Shared logic), `cardpg-server` (Backend)
- **Build**: `cabal build all`
- **REPL**: `cabal repl cardpg-core` or `cabal repl cardpg-server`
- **Testing**: `cabal test all`
- **Style**: Functional, strict types. Use `deriveJSON` via Template Haskell where possible.
