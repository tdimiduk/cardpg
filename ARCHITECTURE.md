# Project Architecture

CardPG is a card-based RPG platform with real-time multiplayer support.

## Technology Stack

- **Language:** Haskell (GHC 9.12)
- **Frontend:** Reflex-DOM (FRP)
- **CSS:** Haskell-native atomic CSS system (`Frontend.Style.*`) with build-time generation
- **Design Tokens:** [Open Props](https://open-props.style/) — CSS custom properties for colors, sizes, shadows, easings
- **Build System:**
  - **Dev:** cabal + ghciwatch + process-compose
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
│   ├── src/Frontend/
│   │   ├── Style/      # Atomic CSS system (Core, DSL, Common, Layout)
│   │   ├── Game/       # Game UI widgets (Hand, Sidebar, Staging, Planning)
│   │   ├── Render/     # Rendering helpers (cards, rules text)
│   │   ├── UI/         # Reusable UI components (Button, Scaler)
│   │   ├── Card.hs     # Card rendering (screen/print modes)
│   │   └── App.hs      # Root application widget
│   ├── app/
│   │   ├── Main.hs     # GHCJS entry point
│   │   ├── StaticMain.hs  # Static HTML/PNG/PDF generation tool
│   │   └── GenCss.hs   # CSS generation build tool
│   └── static/         # Generated CSS, index.html, JS assets
├── api/                # cardpg-api: Shared types for client-server communication
├── data/               # Game content (cards, rule definitions, scenarios)
├── design/             # Game design documents and research
├── tools/              # Python utilities (DB, design sync, SVG generation)
├── tests/e2e/          # Playwright end-to-end tests
├── scripts/            # Development utilities (dev, Watch.hs, deploy)
├── deploy/             # Production deployment (NixOS service, deploy script)
├── output/             # Generated static snapshots (HTML, PNG, PDF)
├── vtt-react/          # Legacy TypeScript/React frontend (reference only)
└── .agent/             # AI agent workflows and skills
```

## Cabal Packages

| Package                | Purpose                         | Dependencies                |
| ---------------------- | ------------------------------- | --------------------------- |
| `cardpg-core`          | Pure game logic, fully testable | None (pure)                 |
| `cardpg-api`           | Shared API types                | `cardpg-core`               |
| `cardpg-server`        | WebSocket server executable     | `cardpg-core`, `cardpg-api` |
| `cardpg-client-reflex` | Reflex frontend + build tools   | `cardpg-core`, `cardpg-api` |

### Executables in `client-reflex`

| Executable      | Purpose                                      |
| --------------- | -------------------------------------------- |
| `client-reflex` | Main frontend (runs via jsaddle-warp in dev) |
| `cardpg-static` | Static HTML/PNG/PDF snapshot generator       |
| `gen-css`       | Atomic CSS generation (run at build time)    |

## Key Patterns

- **Pure core / effectful shell** — `cardpg-core` contains no IO; all effects live in `cardpg-server`
- **Command pattern** — Game actions are strictly typed `Command` enums with typed payloads
- **Strong typing** — Use `newtype` for IDs, never stringly-typed identifiers
- **FRP UI** — Reflex `Dynamic t a` for state, `Event t a` for actions
- **Composable atomic CSS** — Styles compose with `(.)` as `[Prop] -> [Prop]` functions

See [CODING_STANDARDS.md](./CODING_STANDARDS.md) for detailed conventions.

## CSS System

The project uses a **homegrown atomic CSS system** defined entirely in Haskell. This replaces an earlier Tailwind CSS setup.

### Architecture

```
Frontend.Style.Core    → Core types (Prop, Style), rendering, modifiers
Frontend.Style.DSL     → ~200 named atoms + parameterized functions
Frontend.Style.Common  → Element helpers (divS, elS, componentS)
Frontend.Style.Layout  → Layout combinators (row, col, spacer, overlay)
Frontend.Style         → Component-level style groups (card, art, cost, etc.)
Open Props (CDN)       → Design tokens via CSS custom properties (--blue-5, etc.)
```

### Usage Pattern

```haskell
import Frontend.Style.Common (divS, componentS)
import Frontend.Style.DSL (flexCol, bgSlate800, p4, gap2)

myWidget :: (DomBuilder t m) => m ()
myWidget = componentS "my-widget" (flexCol . bgSlate800 . p4 . gap2) $ do
  text "Hello"
```

### Open Props Integration

The project loads [Open Props](https://open-props.style/) via CDN (`<link rel="stylesheet" href="https://unpkg.com/open-props" />`). These provide curated design tokens as CSS custom properties. DSL atoms can reference them as values:

```haskell
-- Using an Open Props color token
textBlue5 = css "text-blue-5" "color" "var(--blue-5)"
```

When adding new styles, prefer Open Props variables (e.g., `var(--size-3)`, `var(--shadow-2)`, `var(--ease-out-3)`) over hardcoded values where a good token exists. This keeps the visual design consistent and tunable.

### CSS Generation

The `gen-css` executable scans source files and enumerates all style atoms to produce `static/atomic.css`. It runs automatically via ghciwatch hooks on every code change during development.

> **Note:** The project is in a transition period where a stale Tailwind `output.css` still ships alongside `atomic.css` to provide CSS resets and a few global styles. See the CSS transition analysis for details on completing this migration.

## Development

### Quick Start

You are running inside direnv, so you don't need to run `nix develop`. Ask me to restart antigravity if you need new dependencies picked up.

```bash
# Start all services (server + client + CSS generation)
dev
```

This runs `process-compose` which starts:

- **server**: ghciwatch watching `server/` and rebuilding on changes
- **client**: ghciwatch watching `client-reflex/` with `gen-css` running before each reload

### Running Tests

```bash
# Unit tests
cabal test all

# E2E tests (runs its own dev server)
cd tests/e2e && npx playwright test
```

See `.agent/skills/testing/SKILL.md` for full testing documentation.

### Static Snapshots

```bash
# Generate game snapshots (HTML + PNG)
cabal run cardpg-static -- game data/scenarios/starter.yaml

# Generate card catalog
cabal run cardpg-static -- catalog
```

Output goes to `./output/`. Useful for visual debugging without a browser.

### Key Commands

- `dev` — Start dev server, client, and CSS generation
- `cabal build all` — Build all packages
- `cabal test all` — Run unit tests
- `cabal run gen-css` — Regenerate atomic.css manually

## Related Documentation

- [CODING_STANDARDS.md](./CODING_STANDARDS.md) — Coding conventions and safety rules
- [.agent/workflows/](./.agent/workflows/) — Development workflows (context recovery, testing, etc.)
- [.agent/skills/](./.agent/skills/) — Documented skills (testing, dev_server, atomic_css, debug_with_mocks)
