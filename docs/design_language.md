# CardPG Design Language Reference

This document outlines the visual design language, aesthetic guidelines, typography system, and rendering standards for the CardPG client frontend. Refer to this when creating new widgets, adjusting styles, or expanding gameplay layouts.

---

## 🌌 Core Theme: "Dark Fantasy & Mystical Altar"

CardPG is styled as an immersive, premium **Dark Fantasy & Mystical** tabletop experience. The user interface does not use flat modern panels; instead, it is designed to feel like physical stone slabs, glowing magical gemstones, and calligraphic parchments resting on a dark obsidian altar surrounded by mist.

---

## 🎨 Color System & Tokens

Our color token system is defined as custom CSS variables in `base.css` and mapped dynamically.

### 1. Base Materials (Obsidian & Granite)

- `--color-obsidian`: `#090706` (The absolute deep stone-black background).
- `--color-stone-dark`: `#141211` (Deep granite slate gray for panels and cards).
- `--color-stone-light`: `#211d1c` (Igneous igneous-gray accents and dividers).

### 2. Metal Highlights & Frames

- `--color-gold-bright`: `#f59e0b` (Vibrant gold highlight; used for glows, hover states, and active staging buttons).
- `--color-gold-muted`: `#b45309` (Weathered antique gold for card borders and inactive details).
- `--color-gold-glow`: `rgba(245, 158, 11, 0.12)` (Soft ambient light emanating from cards).
- `--color-silver`: `#cbd5e1` (Platinum/silver highlight for items, traits, and secondary dividers).

### 3. Magical States

- `--color-crimson`: `#991b1b` (Blood red for cursed consequences and active corruption).
- `--color-mystic-indigo`: `#4338ca` (Mystical indigo for passive traits, equipped slot halos, or mana pools).

---

## ✍️ Typography Pairings

We use a carefully chosen three-tiered typography system to balance high readability with strong thematic immersion:

```
┌────────────────────────────────────────────────────────┐
│                        CINZEL                          │  ◄── Card Titles & Major Headers
│               (Epic Roman Stone-Chiseled)              │
├────────────────────────────────────────────────────────┤
│                         LORA                           │  ◄── Rules Text & Journal Logs
│              (Scholarly, High-Legibility)              │
├────────────────────────────────────────────────────────┤
│                       ALMENDRA                         │  ◄── Gemstone & Cost Digits
│            (Gothic Calligraphic, Bold 700)             │
└────────────────────────────────────────────────────────┘
```

1. **Card Titles & Headers (`Cinzel`)**
   - **Vibe**: Legendary, chiseled stone-slab Roman capitals.
   - **Usage**: Used for main section headers, sidebar titles, and uppercase card names (`uppercase`, `letter-spacing: 0.05em`).
2. **Rules & Body Text (`Lora`)**
   - **Vibe**: Traditional scholarly print, comfortable on the eyes over long play sessions.
   - **Usage**: Used for card rules, text descriptions, history logs, and standard UI instructions.
3. **Resource & Stat Digits (`Almendra`, Bold 700)**
   - **Vibe**: Celtic-gothic manuscript style with outstanding fantasy character.
   - **Usage**: Used exclusively for numbers printed inside all circular, square, diamond, and hexagonal SVG resource nodes.
   - **Rationale**: Selected specifically because its bold `700` weight features a solid, closed-loop `4` and highly distinct digits (like `2`, `7`, and `8`) that do not bleed or blur when outlined at small sizes.

---

## 💎 High-Contrast Gemstone Rendering

To satisfy the strict requirement of perfect visual legibility without sacrificing the premium volumetric details of the resource nodes, we employ a **stroke-under-fill** SVG text layering technique in `Svg.hs`.

### 1. Shape Profiles & Gradients

- **Ruby (Red)**: A square-rounded rect (`x=12.5`, `y=12.5`, `rx=12`) rendered using a volumetric radial gradient (`#ffa8a8` center to `#c92a2a` dark edge) framed with antique gold.
- **Topaz (Yellow)**: A perfect circle (`r=40`) using a warm spherical gradient (`#ffec99` center to `#b45309` amber edge) framed in vibrant gold.
- **Sapphire (Blue)**: A rotated diamond rect (`x=19`, `y=19`, `rx=8`, `transform="rotate(45 50 50)"`) using a deep sapphire gradient (`#a5d8ff` to `#1c7ed6`) framed in silver.
- **Cost Hexagon**: An obsidian runic polygon (`points="50,5 95,27.5 95,72.5 50,95 5,72.5 5,27.5"`) using a linear dark-metallic gradient (`#1c1917` to `#0c0a09`) framed in vibrant gold.

### 2. Typography Outline (Crucial implementation detail)

When text is centered over highly colorful radial gradients, a standard black stroke will eat into the inner fill, choking the letter and making numbers like `4`, `8`, or `9` unreadable.
To prevent this, `renderLabel` utilizes **SVG `paint-order`**:

```haskell
svgEl "text"
  (  "font-family" =: "'Almendra', Georgia, serif"
  <> "font-weight" =: "700"
  <> "fill" =: "#ffffff"        -- High-contrast white center
  <> "stroke" =: "#090706"      -- Deep obsidian outline
  <> "stroke-width" =: "10"     -- Extra-thick border
  <> "paint-order" =: "stroke fill" -- Stroke is painted behind the fill
  )
```

- `paint-order: stroke fill` ensures that GHC paints the full 10px black outline _first_, and then overlays the pristine, sharp white vector text _over_ it. The letters remain thick, white, and fully readable.
- The numbers are centered on **`y="53"`** to account for the precise baseline metrics of the Almendra font.

---

## 🏰 Widget & Component Conventions

When designing new components, follow these architectural styles:

### 1. Card Container Structure

- Background is deep obsidian black (`--color-obsidian`).
- Border is a **double-framed outline**: a thick weathered gold outer border and a thin slate-gray inner border.
- Rule textbox utilizes a semi-transparent granite slab (`rgba(20, 18, 17, 0.85)`) to let a trace of the background shine through.

### 2. Altars & Overlay Modals

- Designed as a heavy **Obsidian Altar** floating over the board.
- Applies a backdrop filter blur (`backdrop-filter: blur(16px)`) with heavy dark stone drop-shadows and vibrant glowing gold halos.

### 3. Equipment & Status Sidebars

- Carved as solid granite slabs.
- Equipped items sit inside warm gold-inlaid borders (`--color-gold-muted`).
- Active debuffs/consequences render as **cracked, cursed lava-stones** (crimson borders, soft red text, glowing red box shadows representing physical corruption).
