---
name: ui_css_static_debugging
description: Rapid UI and CSS development using static snapshots and mock data. Use this for styling, visual verification, and debugging layout regressions without a browser.
---

# Debugging UI and CSS with Mocks

This skill outlines how to use the project's static generation infrastructure to debug UI and CSS changes rapidly. Instead of running a full browser environment, you can generate static HTML and screenshots of your widget states.

## When to Use

- **Developing new UI components**: Quickly see changes without navigating the game state in a browser.
- **Styling with the Frontend DSL**: Verify that your @[haskell_frontend_styling_dsl] calls are generating the expected classes and rules.
- **Debugging Visual Regressions**: Compare current renderings against "known good" snapshots.
- **Verifying Complex States**: Use `MockData.hs` to force the UI into specific edge cases (e.g., long names, empty hands, many consequences).

## Overview

The `cardpg-static` tool (defined in `client-reflex/app/StaticMain.hs`) generates static snapshots of the game. It uses mock data from `Frontend.MockData.hs` to populate the UI, making it the perfect way to:

1.  Verify that styling changes look correct without launching a browser.
2.  Iterate on the styling DSL with a fast feedback loop.
3.  Ensure new UI states are being rendered correctly.

Since `gen-css` runs before each ghciwatch reload (and you can run it manually), the generated `atomic.css` will include styles for any code path that uses parameterized DSL functions (like `bg`, `text`, `p`, `w`, `h`) or named DSL atoms.

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

(This happens automatically during `dev` mode via `ghciwatch` hooks in `scripts/Watch.hs`.)

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
cabal run cardpg-static -- deck data/cards/pc/berserker.yaml
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

The static snapshots load `atomic.css` (and `base.css` for reset/base styles). If your component appears correctly in the `output/game_*.png` screenshots, your styles are being generated correctly.

If your component is missing or unstyled:

- Check that any new named atoms are in the `staticStyles` list in `GenCss.hs`.
- For parameterized functions, ensure they are in the `knownParams` list in `GenCss.hs` and that the Megaparsec scanner is picking up your call sites.

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

## Debugging Regressions

If you notice a visual regression, you can use the static generator to isolate the cause:

1. **Generate current snapshots**: Run `cabal run cardpg-static -- game data/scenarios/starter.yaml`.
2. **Save current snapshots**: `cp -r output/ regression_current/`.
3. **Switch to a "known good" version**: `git checkout <commit_hash>`.
4. **Generate "known good" snapshots**: Run `cabal run cardpg-static -- game data/scenarios/starter.yaml`.
5. **Compare**:
   - Compare the PNGs visually.
   - Compare the HTML files: `diff output/game_MockHero_planning.html regression_current/game_MockHero_planning.html`.
   - Compare the CSS: `diff client-reflex/static/atomic.css regression_current/atomic.css`.

This workflow is much faster than trying to reproduce regressions in a live browser session.
