---
name: atomic_css
description: Understanding and using the atomic CSS system in the CardPG project.
---

# Atomic CSS System

This skill provides context and workflows for working with the Haskell-native atomic CSS system in CardPG.

## Overview

The project uses a purpose-built CSS system defined entirely in Haskell. Styles are composable functions of type `Style = [Prop] -> [Prop]` that compose with `(.)` and produce atomic CSS class names at runtime.

CSS rules are generated at **build time** by the `gen-css` executable, which:

1. Enumerates all static style atoms from `Frontend.Style.DSL`
2. Scans `.hs` source files for parameterized `css "name" "prop" "val"` calls
3. Writes `client-reflex/static/atomic.css`

> [!NOTE]
> In the browser, the style system is purely a class-name generator — it reads `Prop` values and produces space-separated class name strings. All actual CSS comes from the pre-generated `atomic.css` file.

## Key Modules

| Module                  | Role                                                                                                                       |
| ----------------------- | -------------------------------------------------------------------------------------------------------------------------- |
| `Frontend.Style.Core`   | Core types (`Prop`, `Style`), rendering (`classNames`, `renderAll`), modifiers (`hover`, `active`, `pseudo`, `media`)      |
| `Frontend.Style.DSL`    | ~200 named atoms (`flexCol`, `bgSlate800`, `p4`, etc.) + parameterized functions (`gap`, `pad`, `fontSize`, `css`, `css'`) |
| `Frontend.Style.Common` | Element helpers (`divS`, `elS`, `elS'`, `componentS`) and composite styles                                                 |
| `Frontend.Style.Layout` | Layout combinators (`row`, `col`, `rowGap`, `colGap`, `spacer`, `overlay`)                                                 |
| `Frontend.Style`        | Component-level style groups (`cardBase`, `cardScreen`, `artBase`, `costBase`, etc.)                                       |

## Usage

### Creating Styled Elements

Use the helpers from `Frontend.Style.Common`:

```haskell
import Frontend.Style.Common (divS, elS, componentS)
import Frontend.Style.DSL (flexCol, bgSlate800, p4, gap2, textSlate200)

myWidget :: (DomBuilder t m) => m ()
myWidget = componentS "my-widget" (flexCol . bgSlate800 . p4 . gap2) $ do
  divS textSlate200 $ text "Hello!"
```

- `divS style child` — Creates a `<div>` with the given style
- `elS tag style child` — Creates an element with the given tag and style
- `componentS name style child` — Like `divS` but adds a `data-testid` attribute

### Composing Styles

Styles compose with regular function composition `(.)`:

```haskell
cardStyle :: Style
cardStyle = flexCol . relative . p2_5mm . overflowHidden . wCard . hCard
```

### Using Modifiers

```haskell
-- Hover effect
hoverStyle = hover bgSlate700

-- Active effect
activeStyle = active (bgSlate600 . scale105)

-- Pseudo-class
focusStyle = pseudo "focus-visible" (ringBlue400 . ring2)

-- Media query
printStyle = media "print" (textBlack . bgWhite)
```

### Custom One-off Styles

For values not in the DSL, use `css` or `css'`:

```haskell
-- Single property
myHeight = css "h-33mm" "height" "33mm"

-- Multiple properties
myPadding = css' "custom-pad" [("padding-left", "1.5rem"), ("padding-right", "1.5rem")]
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

1. **Static enumeration**: All named atoms from `Frontend.Style.DSL` are listed in `GenCss.hs`'s `staticStyles` array
2. **Source scanning**: A Megaparsec parser scans all `.hs` files under `client-reflex/src/` for parameterized calls like `css "name" "prop" "val"` and `css' "name" [("p","v")]`
3. **Variant generation**: For each unique atom, hover and active variants are generated
4. **Deduplication**: Props are deduplicated by class name
5. **Output**: The final CSS is written to `client-reflex/static/atomic.css`

## Adding New Styles

When you need a style that doesn't exist in the DSL:

### Option A: Named Atom (Reusable)

Add it to `Frontend.Style.DSL`:

```haskell
-- In DSL.hs
myNewStyle :: Style
myNewStyle = css "my-new-style" "some-property" "some-value"
```

Then add it to the export list and to the `staticStyles` list in `GenCss.hs`.

### Option B: Inline Custom (One-off)

Use `css` directly in your widget code:

```haskell
divS (css "h-custom" "height" "42px" . flexCol) $ text "Hello"
```

The Megaparsec scanner in `GenCss.hs` will find this and include it in the generated CSS.

## Troubleshooting

**Problem**: My styles are missing (elements look unstyled).

- **Check 1**: Did you run `gen-css`? If using `dev`, it runs automatically.
- **Check 2**: Is your atom in the `staticStyles` list in `GenCss.hs`? (Named atoms only)
- **Check 3**: For inline `css "..."` calls, does the scanner find them? Check `atomic.css` for your class name.
- **Debug**: Run `cabal run gen-css` and grep the output file for your class name.

**Problem**: Hover/active states aren't working.

- **Check**: The current system generates hover/active variants for all atoms. If you're using a custom selector pattern (like `> * + *`), it may need special handling — see `spaceXActionStackOverlap` in `DSL.hs` for an example.
