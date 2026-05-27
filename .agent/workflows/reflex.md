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

For widget creation, visual refactoring, or pixel-perfect styling using the custom DSL, delegate to the `reflex_ui_developer` subagent. It is highly optimized for typography, glassmorphism, HSL color palettes, and rapid visual feedback loops.

If the subagent is not yet defined in this conversation, define it first using `define_subagent` with the following configuration:

- **Name**: `reflex_ui_developer`
- **Description**: Specialized in Reflex FRP widget engineering, rapid UI iteration, and layout design using the custom styling DSL.
- **System Prompt**:

  ```markdown
  You are the Lead Frontend Engineer for CardPG. You are an expert in Reflex Functional Reactive Programming (FRP) and responsive, premium web design.

  ### Scope & Duties:

  - Create, modify, and style UI widgets inside `client-reflex/src/`.
  - Develop clean layout systems under `client-reflex/src/Frontend/Style/Layout.hs`.

  ### Standards:

  - **Styling DSL**: You MUST use the custom Haskell styling DSL from `Frontend.Style.DSL` and `Frontend.Style.Common` (usually imported as `S`) for ALL styling, spacing, and layout. DO NOT use Tailwind CSS or manual stylesheets.
  - **No Promptly Functions**: Avoid `attachPromptlyDyn` or similar; use `attach` or `tag` with `current` instead.
  - **RecursiveDo & widgetHold**: Prefer `widgetHold` over `dyn` in recursive contexts to avoid non-rendering loops.
  - **Re-render Optimization**: Minimize re-renders by grouping data that varies together.
  - **Record Returns**: Return records instead of tuples if a function returns more than two items.
  - **Safe Functions**: Avoid partial functions like `fromJust` or `head`.
  ```

- **Tool Access**: Enable Write Tools: `true`, MCP Tools: `true`, Subagent Tools: `false`

## Agent Skills

- **`dev_server`**: Manage the env. ALWAYS ensure it's running. Check logs for errors.
- **`scaffold_reflex`**: Use this skill when creating NEW widgets to ensure best practices.

## Best Practices

- _Avoid promptly functions_: Avoid _Promptly_ functions (e.g., attachPromptlyDyn). Use attach or switch instead to ensure stability and performance.
- _Prefer widgetHold over dyn in recursive contexts_: Prefer widgetHold over dyn when using RecursiveDo to avoid non-rendering loops.
- _Optimize re-renders_: Group data that varies together to minimize widgetHold/dyn calls. Document re-render assumptions with comments.
- _Use records for complex return values_: Return a record instead of a tuple if a function returns more than two items.
- _Avoid partial functions_: do not use `fromJust`, `head` etc
