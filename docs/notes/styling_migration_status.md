# Haskell-Native Styling System Migration Status

This note outlines the current state of the migration from the legacy Tailwind CSS setup to our type-safe, Haskell-native styling system.

---

## 📊 Summary of Current Status

- **Frontend Codebase:** **100% Migrated**. All widgets, cards, and UI components in the GHC/Reflex frontend now exclusively use the Haskell styling DSL. There are **zero** hardcoded Tailwind class strings in `.hs` files.
- **CSS Generation (`gen-css`):** **Fully Operational**. The Megaparsec scanner successfully extracts both static style atoms and parameterized function calls (e.g., `bg Gray 10`, `w (Mm 63)`) from the codebase, producing a highly optimized `atomic.css` containing **741 unique CSS rules**.
- **App Loading Path:** **Fully Clean**. `headWidget` loads only `open-props` (for design token CSS variables), `base.css` (resets & scrollbar styles), and the generated `atomic.css`. The legacy Tailwind `output.css` is no longer loaded.
- **Build System / `flake.nix`:** **100% Cleaned Up**. The production Nix derivation (`packages.reflex-client-prod`) has been refactored to remove the legacy Tailwind build step, Node.js dependencies, and references to `tailwindcss_4`. It now compiles completely cleanly by generating the `index.html` bootstrapper inline and copying the pre-built `atomic.css` and `base.css` from static assets.

---

## 🛠️ Styling System Architecture

The native system operates as a zero-runtime-overhead class name generator in the browser, with all raw styles built ahead-of-time.

```
Frontend.Style.Core    ➜ Base types (Prop, Style), class name mapping, modifiers
Frontend.Style.DSL     ➜ ~200 atomic utilities, Open Props bindings, and value parameters
Frontend.Style.Common  ➜ Composable combinators (divS, elS) & composite styles
Frontend.Style.Layout  ➜ Grid layouts, overlays, rows, cols, and growing spacers
Frontend.Style         ➜ Game-domain styles (e.g., cardBase, costScreen, stagedActionCard)
```

### How Styling is Applied

Instead of standard HTML classes, elements are declared using style combinators from `Frontend.Style.Common`:

```haskell
-- In Frontend.Card or other widgets
divS (cardClasses settings) $ do
  row $ do
    componentS "name" (nameClasses settings) $ renderNonEmptyText c.name
    spacer
    maybe blank (\c' -> renderHexagon (costClasses settings) (Just $ tshow c')) c.cost
```

---

## 🔍 Detailed Component Audit

Every core UI component has been successfully refactored:

| File / Component                    | Status   | Notes                                                                                                                                        |
| :---------------------------------- | :------- | :------------------------------------------------------------------------------------------------------------------------------------------- |
| **`Frontend/Card.hs`**              | **Done** | Fully uses `Style` configurations for all modes (Full, Print, Row). Handles complex layouts like stats alignment and hexagons cleanly.       |
| **`Frontend/App.hs`**               | **Done** | Layout and placeholder areas structured using row, column, and surface DSL rules.                                                            |
| **`Frontend/UI/Button.hs`**         | **Done** | Dynamic button variants (Primary, Secondary, Ghost, Outline) and sizes (Small, Medium, Large) calculated dynamically using DSL compositions. |
| **`Frontend/Game/Staging.hs`**      | **Done** | Uses backdrop blurs, relative/absolute spacing, and transitions for card interaction.                                                        |
| **`Frontend/Game/SidebarRight.hs`** | **Done** | Side pane layout, chat text input, scrollbars, and customized colors for logs (challenges, defense, errors).                                 |
| **`Frontend/Game/Hand.hs`**         | **Done** | Focus and hover overlaps calculated entirely through parameterized DSL functions.                                                            |
| **`Frontend/Svg.hs`**               | **Done** | Resource hexagons and shapes styled directly using the shared DSL.                                                                           |

---

## 🧩 Statically Defined Base Styles (`base.css`)

`client-reflex/static/base.css` is retained intentionally. It is **not** legacy; it contains rules that are more readable and performant to define globally rather than as atomic classes:

1. **Modern CSS Reset**: Standard box-sizing, display resets for media elements, and font setups.
2. **Scrollbars**: Vendor-prefixed `-webkit-scrollbar` rules for `.custom-scrollbar`.
3. **HTML/Body Defaults**: Global background (`var(--gray-12)`) and text color (`var(--gray-2)`).
4. **Rich Text Margins**: Spacing defaults for `<p>` tags nested inside rules and actions:
   ```css
   .action p,
   .rules p {
     margin-top: 0;
     margin-bottom: 0.1em;
     line-height: 1.25;
   }
   ```

## ✅ Completed Cleanups

### 1. Simplify `flake.nix` Production Build & Bootstrap HTML

The `reflex-client-prod` package has been successfully refactored using the **"Third Way" static index.html pattern**:

- Removed legacy compile dependencies on `pkgs.nodejs` and `pkgs.tailwindcss_4`.
- Created a minimal, clean static bootstrap shell at [client-reflex/static/index.html](file:///home/tdimiduk/cardpg/cardpg/client-reflex/static/index.html).
- Simplified `flake.nix` to perform a straightforward static asset copy from the `static/` directory into the production target, copying `index.html`, `base.css`, and the pre-built `atomic.css` automatically.

### 2. Nix Build & Environment Optimizations

To prevent massive, slow GHC/GHCJS compilations of dependencies and code on environment reloads:

- **Disabled Local Hoogle:** Turned off `withHoogle` in the development shell, preventing Nix from compiling HTML documentation (Haddocks) for every standard dependency in GHC/GHCJS.
- **Granular Source Filter:** Added a `pkgs.lib.cleanSourceWith` filter to `projectSrc` in `flake.nix`. This instructs Nix to completely ignore changes to files/directories that do not contain project source code (e.g., `notes/`, `design/`, `deploy/`, `static/`, `flake.nix`, `flake.lock`, and Markdown documents). Modifying documentation, notes, or static templates will **no longer** invalidate the GHC/GHCJS caches or trigger rebuilds!

---

## 🧹 Cleanup Recommendations (Next Steps)

### 1. Clean Up Redundant GHC/Reflex Imports

As part of the rapid styling DSL refactoring, some files still import redundant helpers or styles that they do not explicitly use (generating compiler warnings). These are harmless but can be tidied up in a future lint pass:

- `Frontend/Game/PlannedAction.hs`: Redundant import of `elS`
- `Frontend/Game/Hand.hs`: Redundant import of `Style`
- `Frontend/App.hs`: Redundant qualified import of `Frontend.Style.DSL`
