---
title:
  "State Brief: Keyword Rendering & Reflex Static Rules Pipeline (Phase 4 ->
  Phase 5)"
doc_type: iteration
track: ludology
origin: AI drafted
epistemic_status:
  confidence: medium
  vetted_by_human: false
---

# State Brief: Keyword Rendering & Reflex Static Rules Pipeline (Phase 4 -> Phase 5)

**Context Date:** 2026-09-22  
**Related Design Brief:** [`design/iteration/keyword-rendering-and-interactivity-brief.md`](file:///home/tdimiduk/cardpg/cardpg/design/iteration/keyword-rendering-and-interactivity-brief.md)

---

## 1. Executive Summary & Status

Phase 4 of the unified Reflex-native markdown & keyword rendering pipeline is code-complete and verified locally. It replaces Pandoc's legacy raw HTML template export (`rules-template.html`) with Reflex-DOM static page generation (`cardpg-static rules`) using `Frontend.Render.Pandoc` and `Reflex.AtomicCss.DSL`.

- **Unit & Integration Tests:** `cabal test all` passes 100% (core-test: 67/67, client-test: 21/21, reflex-atomic-css-test: 13/13, tools-hs-test: 14/14).
- **Linter & Dead Code:** `./scripts/lint` passes with **zero hints** and clean `weeder`.
- **Local Asset Recompilation:** `./scripts/recompile-assets` executes in ~1s, producing valid `rules.html`, `glossary.html`, and `colors.html` with working wikilink anchors (`glossary.html#{slug}`).
- **Production Nix Derivation:** `flake.nix` is updated to generate AST JSONs and run `cardpg-static rules --output-dir $out --no-snapshot`. The build was in-flight when a reboot occurred and was taken over in the user's terminal.

---

## 2. Key Architectural Changes & Non-Obvious Nuances

### A. Dual CLI Options Handling in `cardpg-static` (`client/app/StaticMain.hs`)

- **Nuance:** In `optparse-applicative`, options declared before a subparser (such as `--output-dir`) are ordinarily required before the command (`cardpg-static --output-dir DIR rules`). However, shell scripts and nix derivations naturally invoke commands with the subcommand first (`cardpg-static rules --output-dir DIR --no-snapshot`).
- **Solution:** `Rules` in `Mode` accepts an optional `outputDirOverride :: Maybe FilePath`. `main` resolves `outDir = fromMaybe opts.outputDir mOutDir`, ensuring both invocations work identically without syntax errors.

### B. Safe Directory Setup in `setupOutputDir` (`client/app/StaticMain.hs`)

- **Nuance:** `setupOutputDir` historically symlinked `base.css` and `atomic.css` relative to `output/` using `.. </> "client" </> "static" </> name`. When `outDir` was set to `client/static` or to `$out` in Nix, this deleted the source CSS file and replaced it with a dangling/broken symlink.
- **Solution:** `setupOutputDir` now checks `absOutDir == absStaticDir`. If `outDir` is already `client/static`, it skips symlink creation. Furthermore, if the file in `outDir` already exists and is not a symlink (e.g. copied into `$out` during a Nix derivation), it preserves it.

### C. Nix Flake Sandbox Invariant (Git Tracking Required)

- **Nuance:** Nix flakes isolate builds using Git tracking. Any untracked file or directory is invisible inside the Nix build sandbox.
- **Critical Context:** `tools-hs/src/Design/` and `tools-hs/app/audit-index/` were present in the workspace but untracked in Git. As a result, `keyword-mod` and `audit-index` failed inside Nix derivations with missing module errors (`can't find source for Design/Audit`). They have been staged with `git add` and must remain tracked.

### D. Styling DSL Additions (`Reflex.AtomicCss.DSL`)

- **Added Atoms:**
  - `minHScreen :: Style` (`min-h-screen`, `min-height: 100vh`)
  - `maxW4Xl :: Style` (`max-w-4xl`, `max-width: 56rem`)
  - `mxAuto :: Style` (`mx-auto`, `margin-left: auto; margin-right: auto`)
  - `bgStone900 :: Style` (`bg-stone-900`, `background-color: var(--color-stone-dark)`)
  - `textStone100 :: Style` (`text-stone-100`, `color: var(--color-silver-bright)`)
- **Registered:** In `Reflex.AtomicCss.Parser`'s `staticStyles`.
- **Generated:** Regenerated into `client/static/atomic.css` via `cabal run reflex-atomic-css:gen-css` (now 381 rules).
- **Template Integration:** In `StaticMain.hs`, `renderDocPage` derives its nav, body, and main container classes directly via `classNames`, guaranteeing exact alignment between Haskell DSL and the emitted HTML.
- **Scrolling Behavior:** Added `overflowYAuto` (`overflow-y-auto`) to the documentation body shell, ensuring multi-page static rules documents can scroll even though `base.css` sets `body { overflow: hidden }` for the single-screen game UI.

### E. Retirement of Pandoc HTML Template

- `client/static/rules-template.html` has been removed via `git rm`. Pandoc is now strictly used as an AST parser (`-f markdown+wikilinks_title_after_pipe -t json`).

---

## 3. Git Status & Modified Files

### Staged for Commit:

- `client/static/rules-template.html` (deleted)
- `tools-hs/src/Design/` (new files: `Audit.hs`, `Frontmatter.hs`, `Index.hs`, `TOC.hs`, `Types.hs`)
- `tools-hs/app/audit-index/Main.hs` (new file)

### Modified Working Tree Files:

- [`client/app/StaticMain.hs`](file:///home/tdimiduk/cardpg/cardpg/client/app/StaticMain.hs): Added `rules` mode, `generateRules`, `renderDocPage`, `findFirstFile`, safe `setupOutputDir`.
- [`scripts/recompile-assets`](file:///home/tdimiduk/cardpg/cardpg/scripts/recompile-assets): Updated to run `keyword-mod export-glossary`, AST JSON generation, and `cardpg-static rules`.
- [`flake.nix`](file:///home/tdimiduk/cardpg/cardpg/flake.nix): Updated `reflex-client-prod` derivation.
- [`reflex-atomic-css/src/Reflex/AtomicCss/DSL.hs`](file:///home/tdimiduk/cardpg/cardpg/reflex-atomic-css/src/Reflex/AtomicCss/DSL.hs): Added layout and color tokens.
- [`reflex-atomic-css/src/Reflex/AtomicCss/Parser.hs`](file:///home/tdimiduk/cardpg/cardpg/reflex-atomic-css/src/Reflex/AtomicCss/Parser.hs): Registered new static styles.
- [`tools-hs/tools-hs.cabal`](file:///home/tdimiduk/cardpg/cardpg/tools-hs/tools-hs.cabal): Added `containers`, `directory`, `filepath` dependencies to `audit-index`.
- [`tools-hs/tests/Main.hs`](file:///home/tdimiduk/cardpg/cardpg/tools-hs/tests/Main.hs): Simplified `isInfixOfStr` to satisfy `hlint`.
- `client/static/atomic.css`: Rebuilt with 381 CSS rules.
- `export/glossary.json` & `client/static/glossary.json`: Generated via `keyword-mod export-glossary`.
- `client/static/{rules,glossary-ast,colors}.json`: Generated via Pandoc AST JSON export.

---

## 4. Next Steps & Phase 5 Transition

1. **Phase 4 Exit Verification:** Completed. `result/rules.html`, `result/glossary.html`, and `result/colors.html` verified in Nix build. Committed in `df1e358`.
2. **Phase 5 Execution Brief:** Created clean, forward-looking execution spec at [`design/iteration/in-app-rules-and-keyword-tooltips-brief.md`](file:///home/tdimiduk/cardpg/cardpg/design/iteration/in-app-rules-and-keyword-tooltips-brief.md).
3. **Execute Phase 5 in Fresh Session:**
   - Implement `Frontend.Rules.Data` compile-time embedding.
   - Implement `Frontend.Rules.Viewer` modal/drawer with tabbed Pandoc rendering.
   - Wire sidebar toggle in `Frontend.Game.Sidebar` and `Frontend.App`.
   - Upgrade `Frontend.Render.Rules.renderInline` to display interactive tooltips for card wikilinks.
