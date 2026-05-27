---
description: Switch context to Haskell backend development
---

# Context: Haskell Backend

- **Directories**: `core` (Core logic), `server` (Backend server), `api` (API definitions)
- **Build**: `cabal build core`, `cabal build server`, `cabal build api`
- **REPL**: `cabal repl core`, `cabal repl server`
- **Testing**: `cabal test core`, `cabal test server`
- **Style**: Functional, strict types. Use `deriveJSON` via Template Haskell where possible.

## Delegating to Subagent

For extensive backend refactoring, domain modeling, DB schema migrations, or pure functional adjustments, delegate to the `haskell_backend_developer` subagent. Spawning this agent in a parallel `branch` workspace prevents editor thread locks and terminal clutter.

If the subagent is not yet defined in this conversation, define it first using `define_subagent` with the following configuration:

- **Name**: `haskell_backend_developer`
- **Description**: Specialized in Haskell backend engineering, functional domain modeling, database migrations, and Cabal builds.
- **System Prompt**:

  ```markdown
  You are the Lead Backend Developer for CardPG. You are an expert in pure functional programming, strict typing, and Cabal-based Haskell architectures.

  ### Scope & Duties:

  - Implement core logic under `core/`.
  - Modify the backend server under `server/` and API definitions under `api/`.
  - Ensure clean compilation using `cabal build`.
  - Run backend unit tests using `cabal test`.

  ### Standards:

  - Maintain a functional, strictly typed architecture.
  - Use `deriveJSON` via Template Haskell for serializations where possible.
  - Format all files with `fourmolu` (per `fourmolu.yaml`).
  - Lint all files with `hlint` (per `.hlint.yaml`).
  - Retain existing code documentation and comments unless explicitly asked to modify them.
  ```

- **Tool Access**: Enable Write Tools: `true`, MCP Tools: `true`, Subagent Tools: `false`

## Agent Skills

- **`dev_server`**: Manage the env (start/check logs). ALWAYS ensure it's running.

## Code Formatting and Linting

Before committing any backend code changes, ensure proper styling:

- **Lint**: Run `./scripts/lint` to analyze the code with `hlint` (config defined in `.hlint.yaml`).
- **Format**: Format all Haskell code files using `fourmolu` (config defined in `fourmolu.yaml`) to maintain consistent styling.
