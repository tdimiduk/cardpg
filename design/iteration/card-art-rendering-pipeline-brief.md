---
title: "Brief: Inline Card Art Rendering & Embedding Pipeline"
doc_type: iteration
track: ludology
origin: AI drafted
epistemic_status:
  confidence: medium
  vetted_by_human: false
---

# Brief: Inline Card Art Rendering & Embedding Pipeline

## Objective

Establish a seamless pipeline to embed live, high-fidelity card layouts directly into rules documentation from YAML source definitions in `data/cards/`, replacing legacy image placeholders (`Figure: ...`) with native Reflex card components.

---

## Architecture: Native Reflex Card Embedding

Earlier proposals considered exporting cards as external SVG or PNG files via a headless browser or vector rasterizer, then embedding them with Markdown image tags (`![card:id](...)`).

With the adoption of the unified Reflex Pandoc AST pipeline (see [`keyword-rendering-and-interactivity-brief.md`](keyword-rendering-and-interactivity-brief.md)), **external image generation is obsolete**. The canonical card rendering engine already lives in [`Frontend.Card`](../../client/src/Frontend/Card.hs). We embed cards directly into the DOM flow at build time (`cardpg-static`) and runtime (`client`).

````
design/rules/*.md
   │
   └── "```card attack_basic```"
          │
          ▼  `pandoc -t json`
     Pandoc CodeBlock (_, ["card"], _) "attack_basic"
          │
          ▼  Frontend.Render.Pandoc
     Card Registry Lookup (`data/cards/**/*.yaml`)
          │
          ▼
     Frontend.Card.renderCoreCardWith (CardSettings CardPrint) card
          │
          ├──> Inline semantic HTML in static `rules.html` (zero external images)
          └──> Interactive card widget in in-app rules viewer
````

---

## Technical Specifications

### 1. Markdown Embedding Syntax

In documentation source files (`design/rules/*.md`), authors use standard fenced code blocks tagged with `card`:

````markdown
### Attack Actions

```card
attack_basic
```

When executing an attack, the card's printed modifier modifies the attack strength.
````

Optional attributes can configure display mode or side-by-side arrangement:

````markdown
```card mode=full align=center
squire:power_attack
```
````

### 2. Card Resolution & Loading

In `client` / `cardpg-static`:

1. **Card Registry Indexer:** Provide a loader (leveraging existing YAML parsers in `StaticMain.hs` and `Core.Card`) that indexes cards by:
   - Unique ID or Slug (e.g., `squire:power_attack`, `fatigue`, `injury`).
   - Standard card name match (e.g., `Attack`, `Fatigue`).
2. **Card Type Support:** Support embedding:
   - `CoreCard` via `renderCoreCardWith`
   - `ItemCard` via `renderItemCardWith`
   - `NatureCard` via `renderNatureCardWith`
   - `ConsequenceCard` via `renderConsequenceCardWith`

### 3. AST Handler in `Frontend.Render.Pandoc`

```haskell
renderBlock = \case
  CodeBlock (_, ["card"], keyvals) cardRef ->
    divS (S.my S.S4 <> S.flex <> S.justifyCenter) $ do
      case lookupCard cardRef cardRegistry of
        Just (AnyCardCore c) ->
          renderCoreCardWith (CardSettings CardPrint) c
        Just (AnyCardItem item) ->
          renderItemCardWith (CardSettings CardPrint) item
        Just (AnyCardConsequence con) ->
          renderConsequenceCardWith (CardSettings CardPrint) con
        Nothing ->
          divS (S.p S.S2 <> S.border S.Red 5 <> S.text S.Red 4) $
            text ("Card not found: " <> cardRef)
  ...
```

### 4. Layout & Print Styling

- **Rules Document Container:** Cards embedded in rules use `CardPrint` mode by default, which renders clean, high-contrast borders and text suitable for reading in document flow.
- **Centering & Sizing:** Embedded cards are wrapped in a flex container with appropriate margins and maximum dimensions so they do not stretch across full-width prose.
- **Card Groups:** Allow multi-card layouts (e.g., illustrating an Action Stack with an Action card and 2 resource cards) using fenced `card-stack` blocks.

---

## Sequencing & Next Threads

1. **Prerequisite:** Implement the AST renderer in [`keyword-rendering-and-interactivity-brief.md`](keyword-rendering-and-interactivity-brief.md) (`Frontend.Render.Pandoc`).
2. **Card Registry:** Consolidate the card loading logic from `client/app/StaticMain.hs` into a reusable `Client.CardRegistry` module.
3. **AST Integration:** Connect the `CodeBlock (_, ["card"], _)` handler in `Frontend.Render.Pandoc`.
4. **Rules Update:** Replace all `Figure: ...` notes in `design/rules/` with live ` ```card ... ``` ` embeds.
