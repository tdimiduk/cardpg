---
description: Run end-to-end Playwright tests for the application
---

# Running E2E Tests

E2E tests use Playwright to test the full web application. The test infrastructure uses Nix-installed dependencies and process-compose to manage test servers.

## Delegating to Subagent

E2E browser tests and Nix builds can be highly compute-intensive and generate extensive output. Delegate full-suite runs or visual regression diagnostics to the `e2e_testing_suite` subagent, preferably using a `branch` or `share` workspace to keep your primary environment uninterrupted.

If the subagent is not yet defined in this conversation, define it first using `define_subagent` with the following configuration:

- **Name**: `e2e_testing_suite`
- **Description**: Specialized in Playwright E2E browser tests, visual regression verification, and Nix-packaged environments.
- **System Prompt**:

  ```markdown
  You are the E2E Testing Suite subagent for CardPG. You are an expert in automated browser testing, visual diagnostics, and reproducible Nix build validation.

  ### Scope & Duties:

  - Run and write Playwright tests under `tests/e2e/`.
  - Diagnose visual layout regressions and integration failures.
  - Run Nix builds to verify production bundling.

  ### Standards:

  - Always use the shared fixtures from `fixtures.ts` (e.g., `loadedPage`).
  - Target components using their `data-testid` attribute (e.g., `app-container`, `chat-input`).
  - For faster iteration, use `./scripts/test-e2e --no-server` against a running dev server on port 3000.
  ```

- **Tool Access**: Enable Write Tools: `true`, MCP Tools: `true`, Subagent Tools: `false`

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

## Detailed References & Test Writing

For concrete details on:

- Directory structures and config parameters
- Writing Playwright test files and using TypeScript fixtures (`loadedPage`)
- Using `data-testid` values in frontend code (both Haskell and TypeScript)
- Reviewing HTML test reports and interactive execution traces
- Troubleshooting "element not found" and target failures

Refer directly to the **@[testing]** skill guide ([`SKILL.md`](file:///home/tdimiduk/cardpg/cardpg/.agent/skills/testing/SKILL.md#3-end-to-end-e2e-tests)).
