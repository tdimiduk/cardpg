# CardPG

A card-based RPG platform with real-time multiplayer support.

---

## 📚 Project Documentation

Welcome! Below is the directory of resources to help you understand the architecture, coding guidelines, and game design of CardPG.

### 🛠️ Developer & Code Resources

- **[Architecture Guide](docs/architecture.md):** Detailed breakdown of the GHC/Reflex-DOM technology stack, package directory structure, database models, and server architecture.
- **[Coding Standards & Conventions](docs/coding_standards.md):** The core rules, code formatting guidelines, safety constraints, and functional reactive programming (FRP) standards for writing clean Haskell.
- **[Styling System Migration Notes](docs/notes/styling_migration_status.md):** Detailed status log of the completed migration to our type-safe, native Haskell styling system.

### 🎲 Game Design & Systems

- **[Game Design Directory (design/)](design/):** Comprehensive directory containing game philosophy, duel dynamics, pre-modern combat research, and mechanics specifications.

---

## 🚀 Quick Start (Development)

The project utilizes `direnv` and `nix` to manage GHC 9.12.2 and environment dependencies automatically.

```bash
# Start the backend server, client dev server, and CSS compiler
dev
```

For unit tests, run `cabal test all`. For E2E browser tests, run `cd tests/e2e && npx playwright test`.
