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
- **Verifying Complex States**: Use saved game YAML files (e.g., `data/saved_games/ui_preview.yaml`) to force the UI into specific edge cases (e.g., long names, empty hands, many consequences).

## Overview

The `cardpg-static` tool (defined in `client-reflex/app/StaticMain.hs`) generates static snapshots of the game. It uses saved games (like `data/saved_games/ui_preview.yaml`) to populate the UI, making it the perfect way to:

1.  Verify that styling changes look correct without launching a browser.
2.  Iterate on the styling DSL with a fast feedback loop.
3.  Ensure new UI states are being rendered correctly.

Since `gen-css` runs before each ghciwatch reload (and you can run it manually), the generated `atomic.css` will include styles for any code path that uses parameterized DSL functions (like `bg`, `text`, `p`, `w`, `h`) or named DSL atoms.

## Workflow

### 1. Update Saved Game State

Edit `data/saved_games/ui_preview.yaml` (or create a new saved game YAML file) to include the state you want to visualize.

- Add a specific `LogEntry` in the `history` list if you are styling logs.
- Add a specific `CoreCard` to an actor's `deck`, `hand`, or `discard` list if you are styling cards.
- Adjust an actor's `phase` or status attributes if testing game flow.

### 2. Regenerate CSS (if needed)

If you've added new styles, regenerate the CSS first:

```bash
cabal run gen-css
```

(This happens automatically during `dev` mode via `ghciwatch` hooks in `scripts/Watch.hs`.)

### 3. Run the Static Generator

Run the `cardpg-static` executable. The `game` mode renders the full game board:

```bash
cabal run cardpg-static -- game data/saved_games/ui_preview.yaml
```

- This generates views for all actors in the loaded saved game.
- It automatically detects whether a file is a standard Scenario or a Saved Game (`GameState`). If a Saved Game like `ui_preview.yaml` is loaded, it generates snapshots for the player's planned, staging, and modal states (such as `game_MockHero_staging.html`).

Other modes:

```bash
# Card catalog (all cards)
cabal run cardpg-static -- catalog

# Single actor's deck
cabal run cardpg-static -- deck data/cards/pc/berserker.yaml
```

### 4. Inspect Output

Check the `output/` directory (created in the project root).

- **PNGs**: `output/game_Vallhach_planning.png` — Open to see what the UI looks like.
- **HTML**: `output/game_Vallhach_planning.html` — Inspect structure in a browser's dev tools.
- **PDFs**: Generated for deck mode (for print-ready card sheets).

### 5. Iterate

1. Make a change to your saved game YAML file, your widget code, or DSL styles.
2. Run `cabal run gen-css` (or let ghciwatch do it).
3. Run `cabal run cardpg-static -- game data/saved_games/ui_preview.yaml`.
4. Check the PNG.

## Connection to CSS Generation

The static snapshots load `atomic.css` (and `base.css` for reset/base styles). If your component appears correctly in the `output/game_*.png` screenshots, your styles are being generated correctly.

If your component is missing or unstyled:

- Check that any new named atoms are in the `staticStyles` list in [Parser.hs](file:///home/tdimiduk/cardpg/cardpg/reflex-atomic-css/src/Reflex/AtomicCss/Parser.hs).
- For parameterized functions, ensure they are in the `knownParams` list in [Parser.hs](file:///home/tdimiduk/cardpg/cardpg/reflex-atomic-css/src/Reflex/AtomicCss/Parser.hs) and that the Megaparsec scanner is picking up your call sites.

## Testing and Extending the Style Parser

If you add a new styling function, modify parser logic, or suspect a parsing issue, use the dedicated QuickCheck test suite.

### Running Parser Tests

To run the style parser unit tests:

```bash
cabal test reflex-atomic-css
```

### Extending the Tests

Instead of writing custom verification scripts, add test coverage directly to the QuickCheck suite:

1. Extend the QuickCheck properties or add a conventional test case in [Main.hs (tests)](file:///home/tdimiduk/cardpg/cardpg/reflex-atomic-css/tests/Main.hs).
2. Fix the parser in [Parser.hs](file:///home/tdimiduk/cardpg/cardpg/reflex-atomic-css/src/Reflex/AtomicCss/Parser.hs) and verify that the tests pass.

## Troubleshooting

**Problem**: "I don't see my specific saved game preview state in the output."

- **Check**: `StaticMain.hs` dynamically searches for the player actor (e.g., `"vallhach"`) and dynamically stages/renders components (like `Vallhach_staging` or `Vallhach_deckview`):
  ```haskell
  genWith (mockGameWidgetWithStaging gameState) (playerActorName <> "_staging")
  ```
- **Fix**: Ensure that the name of the player actor or cards in `ui_preview.yaml` matches the names evaluated in `StaticMain.hs`.

**Problem**: "My styles look wrong in the snapshot."

- **Check**: Run `cabal run gen-css` first to ensure `atomic.css` is up-to-date.
- **Check**: Look at the HTML source — verify the class names are what you expect.
- **Check**: Search `client-reflex/static/atomic.css` for your class name to confirm the CSS rule exists and has the right values.

## Debugging Regressions

If you notice a visual regression, you can use the static generator to isolate the cause:

1. **Generate current snapshots**: Run `cabal run cardpg-static -- game data/saved_games/ui_preview.yaml`.
2. **Save current snapshots**: `cp -r output/ regression_current/`.
3. **Switch to a "known good" version**: `git checkout <commit_hash>`.
4. **Generate "known good" snapshots**: Run `cabal run cardpg-static -- game data/saved_games/ui_preview.yaml`.
5. **Compare**:
   - Compare the PNGs visually.
   - Compare the HTML files: `diff output/game_Vallhach_planning.html regression_current/game_Vallhach_planning.html`.
   - Compare the CSS: `diff client-reflex/static/atomic.css regression_current/atomic.css`.

This workflow is much faster than trying to reproduce regressions in a live browser session.
