---
description: Run end-to-end Playwright tests for the application
---

# Running E2E Tests

E2E tests use Playwright to test the full web application. The test infrastructure uses Nix-installed dependencies and process-compose to manage test servers.

## Quick Start

// turbo

1. Run all e2e tests (starts fresh servers):

```bash
./scripts/test-e2e
```

This command:

- Starts a fresh server instance on port 3001
- Starts Caddy proxy on port 3000
- Runs Playwright tests
- Automatically stops servers when tests complete

## Important Notes

### Production vs Development Testing

The e2e tests run against the **production Nix build** (`./result`), not the development server. This tests the actual deployed artifacts.

- **To test code changes**: You must rebuild the production bundle first:

  ```bash
  nix build .#reflex-client-prod
  ```

- **Or for faster iteration**: Use the development server with `--no-server` flag (below)

// turbo

### Running Tests Against Dev Server

If you already have the dev server running (`./scripts/dev`), you can run tests without starting new servers:

```bash
./scripts/test-e2e --no-server
```

**Warning**: This assumes the dev server is running on port 3000. Only use this for development iteration.

## Test Files

- Test specs: `tests/e2e/*.spec.ts`
- Playwright config: `tests/e2e/playwright.config.ts`
- Process Compose config: `tests/e2e/process-compose.yaml`
- **Shared fixtures**: `tests/e2e/fixtures.ts` - Provides `loadedPage` fixture with pre-loaded app
- **Config**: `tests/e2e/config.ts` - Centralized port configuration

## Common Test Patterns

### Using the Shared Fixture

Import from `fixtures.ts` instead of `@playwright/test` to get the `loadedPage` fixture:

```typescript
import { test, expect } from "./fixtures";

test("my test", async ({ loadedPage }) => {
  // loadedPage already has: page.goto("/") + wait for app-container visible
  const element = loadedPage.getByTestId("my-element");
});
```

Use `{ page }` for tests that don't need the full app loaded (e.g., just checking title).

### Finding Elements

Use `data-testid` attributes for reliable element selection:

```typescript
const chatInput = page.getByTestId("chat-input");
const sendButton = page.getByTestId("chat-send");
```

Available test IDs in the app:

- `app-container` - Main app root
- `main-content` - Main content area
- `game-board` - Game board area
- `game-log` - The game log panel
- `chat-input` - Chat message input field
- `chat-send` - Send button
- `log-entry-chat` - Individual chat log entries
- `log-entry-message` - The message text within a log entry

### Adding New Test IDs

In Haskell, use the `component` helper which adds `data-testid`:

```haskell
component "my-component" [styles] $ do
  -- child widgets
```

Or add directly to elements:

```haskell
elAttr "div" ("class" =: classes styles <> testId "my-element") $ ...
```

## Troubleshooting

### "Element not found" errors

1. Check if the testid exists in the current production build
2. If testing code changes, rebuild with `nix build .#reflex-client-prod`
3. Use `--no-server` with dev server for faster iteration

### Viewing Test Reports

After tests run, Playwright serves an HTML report. The URL is shown in the output:

```
Serving HTML report at http://localhost:9323
```

### Viewing Test Recordings

Failed tests save traces to `tests/e2e/test-results/`. View with:

```bash
cd tests/e2e && npx playwright show-report
```
