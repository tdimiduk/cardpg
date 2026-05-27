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

### Prerequisites & Execution

The E2E tests run against the **production build** of the reflex client. You must build it first:

```bash
nix build .#reflex-client-prod
```

To run the full E2E suite (starts servers, runs tests, stops servers):

```bash
./scripts/test-e2e
```

To run tests against an already running development server (faster iteration, assumes port 3000):

```bash
./scripts/test-e2e --no-server
# OR run playwright directly:
cd tests/e2e && npx playwright test
```

### Directory Structure

- `tests/e2e/*.spec.ts` - Test specifications.
- `tests/e2e/fixtures.ts` - Shared fixtures (e.g., `loadedPage`).
- `tests/e2e/config.ts` - Centralized port and endpoint configurations.
- `tests/e2e/playwright.config.ts` - Playwright global settings.
- `tests/e2e/process-compose.yaml` - Orchestration for running test servers.

### Writing E2E Tests with Fixtures

Always import from `fixtures.ts` instead of `@playwright/test` to use the pre-loaded page fixture (`loadedPage`), which opens the application and waits for the container to become visible:

```typescript
import { test, expect } from "./fixtures";

test("example test", async ({ loadedPage }) => {
  // loadedPage has already completed page.goto("/") and verified the app loaded
  const sidebar = loadedPage.getByTestId("game-log");
  await expect(sidebar).toBeVisible();
});
```

### Element Selection & Test IDs

Target UI components using the `data-testid` attribute to ensure tests are decoupled from changing style classes or text labels.

#### Pre-defined Test IDs in the App:

- `app-container` - Main application root
- `main-content` - Main dashboard/content area
- `game-board` - Game board container
- `game-log` - The game logs sidebar panel
- `chat-input` - Message input textbox
- `chat-send` - Chat send button
- `log-entry-chat` - Individual chat log records
- `log-entry-message` - The text content within log entries

#### Adding Test IDs in Haskell Frontend code:

Use the `component` helper, which automatically attaches a `data-testid` attribute:

```haskell
component "my-component-id" [styles] $ do
  -- child widgets here
```

Or add it directly to standard elements using the `testId` helper:

```haskell
elAttr "div" ("class" =: classes styles <> testId "my-component-id") $ ...
```

### Diagnostics & Debugging

#### HTML Test Reports

Playwright generates detailed HTML reports. If tests fail, view the report:

```bash
cd tests/e2e && npx playwright show-report
```

By default, this serves the report at `http://localhost:9323`.

#### Viewing Test Traces & Recordings

Failed tests record execution traces under `tests/e2e/test-results/`. Open these traces using the Playwright Trace Viewer to step through actions visually.

#### Troubleshooting Common Issues

- **Element Not Found:** Ensure you have rebuilt the production client (`nix build .#reflex-client-prod`) if you made frontend HTML/Widget modifications, or run with `--no-server` against your active dev server.

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
