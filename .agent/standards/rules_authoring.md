# Rules Authoring Standards

This document defines the scope, audience, and editorial boundaries for rulebooks and modules in the `design/rules/` directory.

---

## 1. Document Scope & Audience Boundaries

When authoring or editing rules documents, keep their explicit purpose and target audience distinct. Never allow scope creep across document types.

### `core-rules.md` (Player-Facing Reference)

- **Purpose:** The single document that players need to read and understand to play the game.
- **Tone:** Crisp, authoritative, concise, and procedurally complete.
- **Constraints:**
  - **No GM-Only Advice:** Adjudication baselines, secret pacing tools, NPC handling, and difficulty tables belong in `gamemaster-guide.md`.
  - **No Tactical Essays:** Advice on hand-hoarding risk, archetype builds, and strategic theory belong in `players-guide.md`.
  - **No Narrative Fluff:** Evocative worldbuilding and "how the game should feel" belong in `introduction.md`.
  - **No Optional Subsystems:** Modular mechanics (grid movement, snap checks, rest mechanics, freeform narrative improvisation) belong in `design/rules/modules/`.

### `players-guide.md` (Player Deep Dive & Tactics)

- **Purpose:** Deep dive into strategic play, hand management, tactical archetypes, deck attrition analysis, and play advice.
- **Tone:** Instructional, analytical, and supportive.

### `gamemaster-guide.md` (GM Adjudication & Pacing)

- **Purpose:** Tools for setting difficulty, assigning Color and Strength, handling pacing transitions, adjudicating NPCs, and managing table drama.
- **Tone:** Facilitative, structured, and pedagogical.

### `modules/` (Modular Rule Plug-ins)

- **Purpose:** Self-contained, optional rules modules that tables can adopt or omit without breaking the core engine (e.g., `snap-check.md`, `narrative-actions.md`, `the-breather.md`).
- **Structure:** Each module must contain:
  1. A player-facing rules section.
  2. A GM adjudication section.
  3. Concrete examples of play.

---

## 2. Editorial & Formatting Rules

1. **Tabletop Physicality Over Pseudocode:**
   - Always describe procedures through physical card interactions on the table (grouping stacks, laying out rows, flipping cards).
   - Never write pseudo-code or programmer functions (e.g., `Math: round_up(...)`) in player-facing rules. Tabletop math must be tactile and friction-free.

2. **No Generative Preambles or Filler:**
   - Avoid conversational meta-commentary ("The first step is always...", "In other games you would have...", "The number is more than just a stat; it's a signal...").
   - State rules directly and actively.

3. **No Triple-Redundancy:**
   - Never follow a rule paragraph with a "Note to Players" and a "Note to Gamemasters" that simply repeat the same rule in different voices. State the rule once clearly.

4. **Terminology & Keywords:**
   - Use standardized game terminology (`Strength`, `Defense`, `Resilience`, `Impact`, `Fatigue`, `Burden`, `Crisis Time`, `Adventuring Time`, `Ready Hand`, `Colors`).
   - Distinct game terms must be tagged using double-bracket wikilinks (e.g., `[[Strength]]`, `[[Defense]]`, `[[Colors]]`). All valid terms and their aliases are defined in `design/rules/keyword-glossary.md`.
   - Plurals and inflections should be written inside the brackets if recognized as an alias (e.g. `[[Colors]]`, `[[Consequences]]`, `[[Action Stacks]]`) rather than splitting words with trailing suffixes.
   - Do not use inline code backticks (`` `Term` ``) or bold tags (`**Term**`) for game keywords. Use `cabal run tools-hs:exe:keyword-mod -- normalize-all` to audit and normalize.
