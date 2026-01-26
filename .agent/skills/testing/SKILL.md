---
name: testing
description: Run various tests for the CardPG project (Unit, Lint, E2E, Static)
---

# Testing Skill

This skill outlines the various testing tools available in the CardPG repository.

## 1. Unit Tests (Haskell)

To run unit tests for all Haskell projects (`core`, `server`, `client-reflex`, `api`):

```bash
cabal test all
```

To run tests for a specific project:

```bash
cabal test core
cabal test server
# etc.
```

**Notes:**

- Validated to be relatively fast once compiled.

## 2. Linting

To run the project's linting suite (primarily `hlint`):

```bash
./scripts/lint
```

**Notes:**

- Fast execution.

## 3. End-to-End (E2E) Tests

Playwright-based E2E tests are located in `tests/e2e`.

### Prerequisites

The E2E tests run against the **production build** of the reflex client. You must build it first:

```bash
nix build .#reflex-client-prod
```

_This builds the production assets into `./result`._

### Running Tests

To run the full E2E suite (automatically manages backend server and Caddy proxy):

```bash
./scripts/test-e2e
```

**Notes:**

- Takes a minute or two (build + test execution).
- Uses `process-compose` to spin up `exe:server` (backend) and `caddy` (serving `./result`).

### Running Manually

If you already have the servers running (e.g., via `run-prod-proxy.sh` or manual start), you can run just the tests:

```bash
./scripts/test-e2e --no-server
# OR directly
cd tests/e2e && npx playwright test
```

## 4. Static HTML Inspection

For inspecting the static HTML output of the Reflex app.

> **Agent Tip:** This is the preferred way to quickly verify how UI components are rendering without needing to spin up the full server stack (which is slower). Use this to check your HTML structure/content.

```bash
cabal run client-reflex:exe:cardpg-static
```

**Notes:**

- **Screenshots**: By default, this tool uses `chromium` to generate PNG screenshots of the rendered HTML. Check the output directory (default: `output/`).
- Fast if dependencies are built.
- Outputs the generated HTML which can be piped to a file or inspected.
