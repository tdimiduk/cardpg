---
description: Switch context to Haskell backend development
---

# Context: Haskell Backend

- **Directories**: `cardpg-core` (Shared logic), `cardpg-server` (Backend)
- **Build**: `just build-core` or `just build-server` (or `just build` for everything)
- **REPL**: `just repl-core` or `just repl-server`
- **Testing**: `just test-core` (or `just test` for everything)
- **Style**: Functional, strict types. Use `deriveJSON` via Template Haskell where possible.
