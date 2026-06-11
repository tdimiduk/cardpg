---
name: haskell_frontend_styling_dsl
description: Comprehensive guide to the Haskell-native styling DSL. Use this for ALL frontend styling, layout, and UI work. DO NOT use Tailwind CSS or external stylesheets; all styles must be defined via this DSL to ensure correct build-time generation.
---

# Haskell Frontend Styling DSL

This skill provides the definitive guide for styling and layout in the CardPG project using the native Haskell CSS DSL.

> [!IMPORTANT]
> **This is the ONLY way to style elements in the project.** The project does not use Tailwind CSS or manual CSS files. Any style you use must be available in or added to the DSL to ensure it is captured by the `gen-css` tool during build time.

## When to Use

- **ANY styling task**: Changing colors, spacing, typography, or shadows.
- **Layout changes**: Adding flex containers, centering items, or managing overlays.
- **Creating new components**: Defining the visual structure of a new widget.
- **Adding design tokens**: Extending the DSL with new reusable atoms or parameterized functions.
- **Fixing layout bugs**: Investigating why an element doesn't look as expected.

## Overview

The project uses a purpose-built CSS system defined entirely in Haskell. Styles are composable functions of type `Style = [Prop] -> [Prop]` that compose with `(.)` and produce atomic CSS class names at runtime.

CSS rules are generated at **build time** by the `gen-css` executable, which:

1.  Enumerates all static style atoms from `Frontend.Style.DSL` (e.g., `flexCol`, `justifyCenter`).
2.  Scans `.hs` source files for parameterized calls like `bg Color Int`, `text Color Int`, `p Size`, `gap Size`, etc.
3.  Scans for low-level `css` and `css'` calls.
4.  Writes `client-reflex/static/atomic.css`.

> [!NOTE]
> In the browser, the style system is purely a class-name generator — it reads `Prop` values and produces space-separated class name strings. All actual CSS comes from the pre-generated `atomic.css` file.

## Key Modules

| Module                  | Role                                                                                                                                    |
| ----------------------- | --------------------------------------------------------------------------------------------------------------------------------------- |
| `Frontend.Style.Core`   | Core types (`Prop`, `Style`), rendering (`classNames`, `renderAll`), modifiers (`hover`, `active`, `pseudo`, `media`).                  |
| `Frontend.Style.DSL`    | The primary utility library. Contains `Size` and `Color` ADTs, parameterized functions (`bg`, `p`, `w`, `gap`), and static style atoms. |
| `Frontend.Style.Common` | Element helpers (`divS`, `elS`, `elS'`, `componentS`) and composite styles.                                                             |
| `Frontend.Style.Layout` | Layout combinators (`row`, `col`, `rowGap`, `colGap`, `spacer`, `overlay`).                                                             |
| `Frontend.Style`        | Component-level style groups (`cardBase`, `cardScreen`, `artBase`, `costBase`, etc.).                                                   |

## Usage

### Creating Styled Elements

Use the helpers from `Frontend.Style.Common` and the DSL from `Frontend.Style.DSL` (usually imported as `S`):

```haskell
import Frontend.Style.Common (divS, elS, componentS)
import Frontend.Style.DSL qualified as S

myWidget :: (DomBuilder t m) => m ()
myWidget = componentS "my-widget" (S.flexCol . S.bg S.Gray 1 . S.p S.S4 . S.gap S.S2) $ do
  divS (S.text S.Gray 11) $ text "Hello!"
```

- `divS style child` — Creates a `<div>` with the given style
- `elS tag style child` — Creates an element with the given tag and style
- `componentS name style child` — Like `divS` but adds a `data-testid` attribute

### Parameterized Styles (Size and Color)

Most spacing and color styles are parameterized via ADTs:

- **Size**: `S.S0` through `S.S15` (design tokens), `S.Rem Double`, `S.Mm Double`, `S.Px Double`, `S.Vh Double`.
- **Color**: `S.Gray`, `S.Red`, `S.Blue`, `S.Indigo`, `S.Yellow`, `S.Amber`, `S.White`, `S.Black`, `S.Transparent`.

```haskell
-- Spacing
padding = S.p S.S4
margin  = S.mt (S.Rem 1.5)
width   = S.w (S.Mm 63)

-- Colors
background = S.bg S.Gray 10
textColor  = S.text S.Blue 5
ringColor  = S.ring S.Amber 4
```

### Composing Styles

Styles compose with regular function composition `(.)`:

```haskell
cardStyle :: Style
cardStyle = S.flexCol . S.relative . S.p (S.Mm 2.5) . S.overflowHidden . S.wCard . S.hCard
```

### Using Modifiers

```haskell
-- Hover effect
hoverStyle = S.hover (S.bg S.Gray 9)

-- Active effect
activeStyle = S.active (S.bg S.Gray 8 . S.scale105)

-- Pseudo-class
focusStyle = S.pseudo "focus-visible" (S.ring S.Blue 5 . S.ring2)

-- Media query
printStyle = S.media "print" (S.text S.Black 12 . S.bg S.White 0)
```

### Custom One-off Styles

For values not in the DSL, use `css` or `css'`:

```haskell
-- Single property
myHeight = S.css "h-33mm" "height" "33mm"

-- Multiple properties
myPadding = S.css' "custom-pad" [("padding-left", "1.5rem"), ("padding-right", "1.5rem")]
```

## CSS Generation

### Automatic (Development)

During development, `gen-css` runs automatically via `ghciwatch` hooks (before startup, reload, and restart). You don't need to run it manually.

### Manual

```bash
cabal run gen-css
```

This writes to `client-reflex/static/atomic.css`.

### How GenCss Works

1. **Static enumeration**: Named atoms (zero-argument functions) from `Frontend.Style.DSL` are listed in [Parser.hs](file:///home/tdimiduk/cardpg/cardpg/reflex-atomic-css/src/Reflex/AtomicCss/Parser.hs)'s `staticStyles` array.
2. **Source scanning**: A Megaparsec parser scans all `.hs` files under `client-reflex/src/` for:
   - Parameterized calls like `bg Gray 10`, `p S4`, `gap (Rem 1)`.
   - Low-level `css` and `css'` calls.
3. **Variant generation**: For each unique atom found or scanned, hover and active variants are generated if they are used in the source with `hover` or `active`.
4. **Deduplication**: Props are deduplicated by class name.
5. **Output**: The final CSS is written to `client-reflex/static/atomic.css`.

## Adding New Styles

When you need a style that doesn't exist in the DSL:

### Option A: Named Atom (Reusable)

Add it to `Frontend.Style.DSL`:

```haskell
-- In DSL.hs
myNewStyle :: Style
myNewStyle = css "my-new-style" "some-property" "some-value"
```

Then add it to the export list and to the `staticStyles` list in [Parser.hs](file:///home/tdimiduk/cardpg/cardpg/reflex-atomic-css/src/Reflex/AtomicCss/Parser.hs).

### Option B: Inline Custom (One-off)

Use `css` directly in your widget code:

```haskell
divS (S.css "h-custom" "height" "42px" . S.flexCol) $ text "Hello"
```

The Megaparsec scanner will find this and include it in the generated CSS.

## Troubleshooting

**Problem**: My styles are missing (elements look unstyled).

- **Check 1**: Did you run `gen-css`? If using `dev`, it runs automatically.
- **Check 2**: Is your atom in the `staticStyles` list in [Parser.hs](file:///home/tdimiduk/cardpg/cardpg/reflex-atomic-css/src/Reflex/AtomicCss/Parser.hs)? (For static, zero-argument atoms only).
- **Check 3**: For parameterized calls (like `bg Gray 10`), is the Megaparsec scanner picking them up? Ensure you are using standard `S.bg S.Gray 10` or `bg Gray 10` patterns.
- **Debug**: Run `cabal run gen-css` and grep the output file for your class name.
- **Visual Verification**: Use the @[ui_css_static_debugging] skill to generate snapshots and verify the rendered HTML/CSS structure without a browser.

**Problem**: Hover/active states aren't working.

- **Check**: The current system generates hover/active variants for atoms only when it detects `hover <atom>` or `active <atom>` in the source (or if they are in the static variants list). If you're using a custom selector pattern (like `> * + *`), it may need special handling — see `spaceXActionStackOverlap` in `DSL.hs` for an example.
