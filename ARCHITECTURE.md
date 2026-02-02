# Project Architecture

CardPG is a card-based RPG platform with real-time multiplayer support.

## Technology Stack

- **Language:** Haskell (GHC 9.12)
- **Frontend:** Reflex-DOM (FRP)
- **Build System:**
  - **Dev:** cabal
  - **Prod:** nix
- **Environment and tools management:** flake.nix (devShells.default)

## Directory Structure

```
cardpg/
├── core/               # cardpg-core: Pure game logic library (no IO)
│   └── src/Core/
│       ├── Logic/      # Game state transitions, action processing
│       ├── Rules/      # Rule definitions and evaluation
│       ├── State.hs    # Game state types
│       └── Card.hs     # Card definitions
├── server/             # cardpg-server: WebSocket server
│   └── src/Server/     # Connection handling, game hosting
├── client-reflex/      # cardpg-client-reflex: Haskell/Reflex-DOM frontend
│   └── src/Frontend/   # FRP-based UI components
├── api/                # cardpg-api: Shared types for client-server communication
├── vtt-react/          # Legacy TypeScript/React frontend (only present for reference while we transition to Reflex)
├── data/               # Game content (cards, rule definitions, assets)
├── design/             # Game design documents and research
├── tests/e2e/          # Playwright end-to-end tests
├── scripts/            # Development utilities
└── .agent/             # AI agent workflows and skills
```

## Cabal Packages

| Package                | Purpose                         | Dependencies                |
| ---------------------- | ------------------------------- | --------------------------- |
| `cardpg-core`          | Pure game logic, fully testable | None (pure)                 |
| `cardpg-api`           | Shared API types                | `cardpg-core`               |
| `cardpg-server`        | WebSocket server executable     | `cardpg-core`, `cardpg-api` |
| `cardpg-client-reflex` | GHCJS/Reflex frontend           | `cardpg-core`, `cardpg-api` |

## Key Patterns

- **Pure core / effectful shell** — `cardpg-core` contains no IO; all effects live in `cardpg-server`
- **Command pattern** — Game actions are strictly typed `Command` enums with typed payloads
- **Strong typing** — Use `newtype` for IDs, never stringly-typed identifiers

See [CODING_STANDARDS.md](./CODING_STANDARDS.md) for detailed conventions.

## Development

### Quick Start

You are running inside direnv, so you don't need to run `nix develop`. Ask me to restart antigravity if you need new dependencies picked up.

```bash
# Start all services (server + client + tailwind)
dev
```

### Running Tests

```bash
# Unit tests
cabal test all

# E2E tests (runs it's own dev server)
cd tests/e2e && npx playwright test
```

See `.agent/skills/testing/SKILL.md` for full testing documentation.

### Key Commands

- `dev` — Start dev server, client, and tailwind watcher
- `cabal build all` — Build all packages
- `cabal test all` — Run unit tests

## Related Documentation

- [CODING_STANDARDS.md](./CODING_STANDARDS.md) — Coding conventions and safety rules
- [.agent/workflows/](./.agent/workflows/) — Development workflows (context recovery, testing, etc.)
- [.agent/skills/](./.agent/skills/) — Documented skills (testing, dev_server, scaffold_reflex)
