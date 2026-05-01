---
name: debug_with_mocks
description: Using static generation and mocks to iterate on UI/CSS without a browser.
---

# Debugging with Mocks

This skill outlines how to use the project's static generation infrastructure to debug UI and CSS changes rapidly. Instead of running a full browser environment, you can generate static HTML and screenshots of your widget states.

## Overview

The `cardpg-static` tool (defined in `client-reflex/app/StaticMain.hs`) generates static snapshots of the game. It uses mock data from `Frontend.MockData.hs` to populate the UI, making it the perfect way to:

1.  Verify that styling changes look correct without launching a browser.
2.  Iterate on the atomic CSS system with a fast feedback loop.
3.  Ensure new UI states are being rendered correctly.

Since `gen-css` runs before each ghciwatch reload (and you can run it manually), the generated `atomic.css` will include styles for any code path that uses the `css`/`css'` functions or named DSL atoms.

## Workflow

### 1. Update Mock Data

Edit `client-reflex/src/Frontend/MockData.hs` to include the state you want to visualize.

- Add a specific `LogEntry` if you are styling logs.
- Add a specific `CoreCard` or `CardInstance` if you are styling cards.
- Add a new `Phase` or `ActorState` configuration if testing game flow.

### 2. Regenerate CSS (if needed)

If you've added new styles, regenerate the CSS first:

```bash
cabal run gen-css
```

(This happens automatically during `dev` mode via ghciwatch hooks.)

### 3. Run the Static Generator

Run the `cardpg-static` executable. The `game` mode renders the full game board:

```bash
cabal run cardpg-static -- game data/scenarios/starter.yaml
```

- This generates views for all actors in the scenario file.
- It **also** explicitly generates views based on `MockData.hs` (e.g., `game_MockHero_planning.html`).

Other modes:

```bash
# Card catalog (all cards)
cabal run cardpg-static -- catalog

# Single actor's deck
cabal run cardpg-static -- deck data/cards/some_actor.yaml
```

### 4. Inspect Output

Check the `output/` directory (created in the project root).

- **PNGs**: `output/game_MockHero_planning.png` — Open to see what the UI looks like.
- **HTML**: `output/game_MockHero_planning.html` — Inspect structure in a browser's dev tools.
- **PDFs**: Generated for deck mode (for print-ready card sheets).

### 5. Iterate

1. Make a change to `MockData.hs`, your widget code, or DSL styles.
2. Run `cabal run gen-css` (or let ghciwatch do it).
3. Run `cabal run cardpg-static -- game data/scenarios/starter.yaml`.
4. Check the PNG.

## Connection to CSS Generation

The static snapshots load `atomic.css` (and currently `output.css` for base styles). If your component appears correctly in the `output/game_*.png` screenshots, your styles are being generated correctly.

If your component is missing or unstyled:

- Check that any new named atoms are in the `staticStyles` list in `GenCss.hs`
- Check that inline `css "..." "..." "..."` calls are being found by the Megaparsec scanner

## Troubleshooting

**Problem**: "I don't see my specific mock state in the output."

- **Check**: `StaticMain.hs` processes `Mock.mockActorId` in both `Planning` and `Resolution` phases:
  ```haskell
  gen "MockHero_planning" (Just Mock.mockActorId) Planning
  gen "MockHero_resolution" (Just Mock.mockActorId) Resolution
  ```
- **Fix**: If you added a new `Phase`, modify `StaticMain.hs` to generate a snapshot for it.

**Problem**: "My styles look wrong in the snapshot."

- **Check**: Run `cabal run gen-css` first to ensure `atomic.css` is up-to-date.
- **Check**: Look at the HTML source — verify the class names are what you expect.
- **Check**: Search `client-reflex/static/atomic.css` for your class name to confirm the CSS rule exists and has the right values.
