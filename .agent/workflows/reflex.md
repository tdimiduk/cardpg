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

## Delegating to Subagent

- **`reflex_ui_developer`**: For widget creation, visual refactoring, or pixel-perfect styling using the custom DSL, delegate to the `reflex_ui_developer` subagent. It is highly optimized for typography, glassmorphism, HSL color palettes, and rapid visual feedback loops.

## Agent Skills

- **`dev_server`**: Manage the env. ALWAYS ensure it's running. Check logs for errors.
- **`scaffold_reflex`**: Use this skill when creating NEW widgets to ensure best practices.

## Best Practices

- _Avoid promptly functions_: Avoid _Promptly_ functions (e.g., attachPromptlyDyn). Use attach or switch instead to ensure stability and performance.
- _Prefer widgetHold over dyn in recursive contexts_: Prefer widgetHold over dyn when using RecursiveDo to avoid non-rendering loops.
- _Optimize re-renders_: Group data that varies together to minimize widgetHold/dyn calls. Document re-render assumptions with comments.
- _Use records for complex return values_: Return a record instead of a tuple if a function returns more than two items.
- _Avoid partial functions_: do not use `fromJust`, `head` etc
