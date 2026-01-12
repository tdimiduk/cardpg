---
description: Guide to working with the Reflex frontend
---

# Context: Reflex Frontend

- **Directory**: `client-reflex`
- **Output**: Generates static HTML and PNGs in `output` directory

## Commands

To generate static assets for styling iteration:

```bash
cabal run cardpg-static -- game data/scenarios/starter.yaml
```

## Development Server

The project uses a `process-compose` based development server that manages both the backend and frontend with hot reloading via `ghciwatch`.

- **Command**: `./scripts/dev` (starts server, client-reflex, and tailwind)
- **Logs**: `./scratch/logs/process-compose.log`

**Agent Instructions**:

1.  **Assume Running**: Provide commands/edits assuming the dev server is already running in the background.
2.  **Check Status**: If you encounter connection errors or need to verify the state, check if the server is running.
3.  **Start if Missing**: If it is NOT running, start it using `./scripts/dev`.
4.  **Debug via Logs**: Tail the log file `./scratch/logs/process-compose.log` to see compilation errors and runtime logs for both client and server.

## Best Practices

- _Avoid promptly functions_: Avoid _Promptly_ functions (e.g., attachPromptlyDyn). Use attach or switch instead to ensure stability and performance.
- _Prefer widgetHold over dyn in recursive contexts_: Prefer widgetHold over dyn when using RecursiveDo to avoid non-rendering loops.
- _Optimize re-renders_: Group data that varies together to minimize widgetHold/dyn calls. Document re-render assumptions with comments.
- _Use records for complex return values_: Return a record instead of a tuple if a function returns more than two items.
- _Avoid partial functions_: do not use `fromJust`, `head` etc
