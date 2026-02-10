---
name: debug_with_mocks
description: Using static generation and mocks to iterate on UI/CSS without a browser.
---

# Debugging with Mocks

This skill outlines how to use the project's static generation infrastructure to debug UI and CSS changes rapidly. Instead of running a full browser environment, you can generate static HTML and screenshots of your widget states.

## Overview

The `cardpg-static` tool (defined in `client-reflex/app/StaticMain.hs`) generates static snapshots of the game. It uses the SAME mock data as the CSS generator (`GenCss.hs`), making it the perfect way to:

1.  Verify that your `MockData.hs` changes actually look correct.
2.  Iterate on styling (atomic CSS) with a fast feedback loop.
3.  Ensure your new UI states are being "seen" by the CSS generation machinery.

## Workflow

### 1. Update Mock Data

Edit `client-reflex/src/Frontend/MockData.hs` to include the state you want to visualize.

- Add a specific `LogEntry` if you are styling logs.
- Add a specific `CoreCard` or `CardInstance` if you are styling cards.
- Add a new `Phase` or `ActorState` configuration if testing game flow.

### 2. Run the Static Generator

Run the `cardpg-static` executable. You usually want the `game` mode, which renders the game board.

```bash
cabal run cardpg-static -- game data/scenarios/starter.yaml
```

- **Note**: `data/scenarios/starter.yaml` is a real scenario file that satisfies the CLI; the tool _also_ explicitly generates views based on `MockData.hs` (e.g., `game_MockHero_planning.html`).

### 3. Inspect Output

Check the `output/` directory (created in the root).

- **Images**: `output/game_MockHero_planning.png` (and `_resolution.png`). Open these to see exactly what the UI looks like.
- **Html**: `output/game_MockHero_planning.html`. Useful for inspecting structure if needed.

### 4. Iterate

1.  Make a change to `MockData.hs` or your component styling.
2.  Rerun the command.
3.  Check the PNG.

## Connection to Atomic CSS

If you see your component in the `output/game_*.png` screenshots, congratulations! This guarantees that `GenCss` (which runs the same `mockGameWidget`) has also "seen" your component and generated the necessary atomic CSS rules for it.

If your component is missing from the screenshots, it is likely missing from the CSS generation too.

## Troubleshooting

**Problem**: "I don't see my specific mock state in the output."

- **Check**: `StaticMain.hs` processes `Mock.mockActorId` in both `Planning` and `Resolution` phases.
  ```haskell
  gen "MockHero_planning" (Just Mock.mockActorId) Planning
  gen "MockHero_resolution" (Just Mock.mockActorId) Resolution
  ```
- **Fix**: If you added a new `Phase` (e.g., `Freeform`), you might need to modify `StaticMain.hs` to explicitly generate a snapshot for it:
  ```haskell
  gen "MockHero_freeform" (Just Mock.mockActorId) Freeform
  ```
