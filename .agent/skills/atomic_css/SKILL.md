---
name: atomic_css
description: Understanding and using the atomic CSS system in the CardPG project.
---

# Atomic CSS Implementation

This skill provides context and workflows for working with the atomic CSS system in CardPG. The goal is to move towards using `atomic-css` for type-safe and ergonomic handling of styles everywhere.

## Overview

The project uses a hybrid approach to generate the static `atomic.css` file:

1.  **Static Source Scanning**: Scans `.hs` files for implicit `atom "name" "prop" "val"` usage.
2.  **Runtime Collection (The Preferred Way)**: Executes the UI code with mock data to capture all styles actually used.

We are migrating towards **Runtime Collection** as the standard. This means any style you add using the `Frontend.Style.DSL` must be reachable by the mock execution to be generated.

> [!NOTE]
> When we say "Runtime Collection", we mean the runtime of the _build tool_ (`GenCss`), not the browser runtime. In the actual browser application, style registration is a no-op, and the app uses the pre-generated static `atomic.css` file.

## The Machinery

The system relies on three key components working together:

### 1. The Collector: `Frontend.Style.T`

This module defines `StyleWriterT`, a monad transformer that wraps `ReaderT (IORef CollectedRules) m`.

- It implements the `MonadStyle` typeclass.
- The `registerStyles` function adds rules to the `IORef`.
- This is the "bucket" that catches all styles during execution.

### 2. The Triggers: `Frontend.Style.Common`

This module provides the helper functions used in widget code.

- `classes`: The core function that calls `registerStyles`.
- `elT`, `divT`, `componentT`: Use these helpers! They automatically call `classes` with your styles.
- **Workflow**: When you use `divT (flex . p4) child`, the `flex` and `p4` styles are registered _during the GenCss run_.

### 3. The Generator: `client-reflex/app/GenCss.hs`

This is the executable that produces the CSS file.

- It runs `mockGameWidget` inside `StyleWriterT`.
- It iterates through game phases `[Planning, Resolution]` to capture styles specific to each phase.
- It uses data from `Frontend.MockData.hs` to populate the state.
- **Crucial**: Any code path _not_ exercised by `mockGameWidget` during this run will **not** have its styles generated (unless found by the static scanner fallback).

## Workflow: Adding Styled Components

When adding new UI components or styles, follow this workflow to ensure your styles are generated:

1.  **Use the DSL**: Import atoms from `Frontend.Style.DSL` (e.g., `flex`, `p4`, `textRed500`).
2.  **Use Transformer Helpers**: Use `divT`, `elT`, or compose your own styles with `toStyle`.

    ```haskell
    import Frontend.Style.Common (divT, elT)
    import Frontend.Style.DSL (flex, gap4, textXl)

    myWidget :: (MonadWidget t m) => m ()
    myWidget = do
      divT (flex . gap4) $ do
        elT "span" textXl $ text "Hello!"
    ```

3.  **Ensure Coverage**:
    - Verify that your new widget is reachable from `mockGameWidget` in `GenCss.hs`.
    - If your component appears only in a specific game state (e.g., "Freeform"), ensure `GenCss.hs` iterates over that state or `MockData.hs` provides it.
    - If you add a new `Phase` to `mockGameWidget`, make sure it's included in the traversal list (currently `[Planning, Resolution]`).

## Troubleshooting

**Problem**: My styles are missing in the generated CSS (elements look unstyled).

- **Check**: Is the widget actually being run by `gen-css`?
- **Debug**:
  1.  Look at `client-reflex/app/GenCss.hs`.
  2.  Trace `mockGameWidget` -> `uiWidget` -> your component.
  3.  If your component is behind a `case` expression or `if`, ensure the mock data in `Frontend.MockData.hs` triggers that branch.

**Problem**: I need a dynamic style (e.g., `gap n` where `n` changes) or my style depends on state not always active in mocks.

- **Solution**: You can explicitly register styles that might not be active during the mock run but are needed for the full app.
- **Pattern**: See `Frontend.UI.Button.hs` for a robust example. You can register styles eagerly:
  ```haskell
  -- In your widget code
  registerStyles $ myPossibleStyle mempty
  registerEnumStyles (\variant -> variantStyle variant mempty)
  ```
  This ensures `gen-css` picks up `VariantDestructive` styles even if the mock only ever renders `VariantPrimary`.
