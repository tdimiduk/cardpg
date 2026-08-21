# Design Precepts

## Core Engine Philosophy

These precepts define the fundamental user-facing experience of the game's resolution systems.

### Default to Success at a Cost

**Core Principle:** Actions are presumed to succeed at their immediate goal. The core tension of the game does not come from asking "if" an action works, but "at what cost?" Outright failure is an exceptional outcome that must be explicitly stated on a `Consequence Card`.

**Rationale:** This is the central mechanical implementation of our "Fail Forward & Narrative Momentum" guiding principle. It ensures the story never stalls on a single bad roll.

**Design Nuance:** "Success at a cost" must never feel like a flat mechanical tax. The game must provide clear pathways for players to actively mitigate or bypass these costs through clever positioning, proactive planning, and tactical restraint. The cost should feel like a natural consequence of a deliberate choice, not an unavoidable punishment for playing.

### Design for Narrative Possibility, Not Game States

**Core Principle:** An action's viability should be determined by its narrative context and its cost, not by an abstract game state. If a player can describe how their character performs an action and is willing to pay the associated costs and risk the consequences, the rules should facilitate that action.

**Rationale:** This is a direct implementation of our **Ludonarrative Harmony** principle. It prevents dissonant, "gamey" player behavior and ensures that the mechanically optimal choice aligns with what makes sense in the story.

### Frame Extreme States as High-Risk Tradeoffs

**Core Principle:** When the core math of the game produces an extreme, high-risk outcome, do not treat it as a bug to be "fixed" with a limiting rule. Instead, frame it as a deliberate, high-stakes tactical choice for the player.

**Rationale:** This precept is a direct application of our "Player Agency" and "Meaningful Choices Emerge from Tradeoffs" guiding principles. It creates more dramatic and memorable play by allowing players to push the system to its limits and face the natural, emergent consequences.

---

## Mechanical Implementation

These precepts define the non-negotiable architectural patterns of the core game engine.

### Differentiate Primarily Through Core Math

**Core Principle:** The most elegant design is one where the distinctiveness and power of a game element "fall out" as a natural consequence of its core numerical stats. New keywords and special rules should be reserved for representing truly unique tactical functions that the core math cannot adequately represent.

**Case Study: Translating "Immunity" into High-Cost Thresholds**
When our research describes a defense as "Functionally Immune," this is modeled with very high, but finite, numerical stats (like `Defense`), not a binary "Immune" keyword. This keeps the core mechanic consistent and creates design space for supernatural attacks to feel exceptional.

### Mandate Simultaneous Action Resolution

**Core Principle:** During `Crisis Time`, all player and enemy actions are declared simultaneously and resolved simultaneously. This is a non-negotiable core of the action system.

**Rationale:** This precept is the primary mechanical support for the Combat pillar's goal of being "fast-paced and decisive" by eliminating player downtime.

### Integrate Movement and Intent into Unified Actions

**Core Principle:** Movement is an integral component of an action, not a separate tactical choice. The act of moving, striking, and defending should be modeled as a single, unified maneuver.

**Rationale:** This precept is a direct application of our "Casual Realism" and "Ludonarrative Harmony" principles, creating a more fluid and intuitive system that avoids the feel of a separate move/action economy.

### Frame Disengagement as a Tactical Problem

**Core Principle:** Disengaging from an active opponent is a difficult tactical problem that must be solved, not a default action that can be taken without consequence.

**Rationale:** This precept implements our "Casual Realism" and "Player Agency" principles. It ensures clever tactical maneuvers are rewarded while still providing a "desperate retreat" option as a safety valve.

### Respect the 10x Rule of Core Complexity

**Core Principle:** Complexity in the core rulebook costs **10x** as much as complexity distributed on specific cards. The core engine procedures in `core-rules.md` must remain minimal, tactile, and intuitive to teach in two minutes. Nuance, situational mechanics, weapon dynamics, and recovery arcs should live on self-contained cards (Consequence cards, Action cards, Stance/Item cards) rather than extensive rulebook glossaries.

**Rationale:** This precept enforces our **Mechanical Elegance** and **Modular Design** guiding principles. It keeps the barrier to entry low while allowing physical cards to carry rich tactical depth and verisimilitude.

### Design for Tabletop Ergonomics and Low Cognitive Load

**Core Principle:** Resolution mechanics must be physically tactile and computationally lightweight at the table. Avoid mechanics that reward players for tracking the exact remaining card composition of their 24-card deck (card-counting), calculating complex probability curves during mid-turn choices (Anti-Analysis Paralysis), or converting multiple layers of fractional math and token currencies.

**Rationale:** This directly supports our **Casual Realism** and **Fun** principles. It ensures that player attention stays focused on dramatic tactical choices and narrative stakes rather than mental arithmetic and procedural bookkeeping.

---

## Content & Experience Design

These precepts guide the design of player-facing content like cards, consequences, and advancement systems.

### Apply the Three Core `Color`s as a Universal Framework

**Core Principle:** The three Core `Color`s are the primary framework for categorizing actions and ensuring all character archetypes have meaningful ways to contribute to any challenge across all Pillars of Play.

**Rationale:** This ensures that all characters can meaningfully contribute to any scene, transforming encounters into multi-faceted puzzles for the entire party.

### Model Harm as a Tangible, Multi-Stage Process

**Core Principle:** Harm and its resolution should be modeled as a tangible, multi-stage process that creates new tactical and narrative challenges, never as simple numerical attrition.

**Rationale:** This supports the "Tension Through Informed Risk" and "Fail Forward" principles by using `Status Cards` to model accumulating wear and `Condition Cards` to represent specific tactical problems. Furthermore, it establishes that character death is the ultimate outcome of a telegraphed _process_, not a random event.

**Design Nuance:** While injuries are tactile and impactful, they are structurally designed to be mended. In the default game mode, injuries are temporary narrative hurdles that drive the plot of recovery, rather than permanent, disabling scars.

### Design Advancement and Archetypes for Tangibility

**Core Principle:** Character advancement should provide tangible, exciting new tools, not just abstract numerical improvements. Core character fantasies should be supported by specific, active mechanics, not just passive stats.

**Rationale:** This makes advancement feel more meaningful and reinforces the `Grounded Heroism` principle by rewarding players with new, dramatic capabilities.

### Enforce Action on Zero-Value Cards

**Core Principle:** Any Status Card with zero stats (0/0/0) should generally have a mechanic that forces it out of the player's hand (for example the Minor Wound card).

**Rationale:** This prevents the "optimal play" problem where players hoard useless cards to keep their draw deck thin and efficient. It ensures that drawing a "dead" card is always an immediate tactical hindrance that must be dealt with, reinforcing the Deck as Life pattern.

### Treat Removing Cards from Cycling as an Active Cost

**Core Principle:** Taking cards out of a character's cycling deck into other zones (holding them in hand, placing them in ongoing tableaus, or attaching them to targets) actively shrinks the draw pile and accelerates fatigue / risks defensive collapse. Removing cards from circulation is fundamentally an _active cost and systemic liability_ for that character.

**Rationale:** Card designs, items, and resolution mechanics should only remove cards from circulation when deliberately intending to impose an endurance cost or high-stakes trade-off on a character, never as a superficial bookkeeping shorthand.

### Use "Cards as Fuel" for Basic Tactical Recoveries in Content

**Core Principle:** When designing recovery tasks or tactical maneuvers on Condition Cards or specific actions (e.g., getting up from prone or clearing an immediate hindrance), specify costs as placing or expending generic cards from hand (e.g., _"Place a card from your hand into your expended pile to stand up"_).

**Rationale:** This gives players a viable tactical use for `Fatigue` or low-value cards in hand while maintaining ludonarrative harmony (an exhausted hero spends their remaining effort to struggle back to their feet). It embeds tactical flexibility directly into card content without cluttering the core rulebook with a rigid list of global basic action rules.

### Core vs. Modular Design (The Pillars of Play Metric)

**Core Principle:** A mechanic belongs in the **Core Rules** if its removal would fundamentally break or diminish one of the four established Pillars of Play (Combat, Exploration, Social, Downtime). A mechanic belongs in an **Optional Module** if it adds a self-contained layer of depth or flavor to a pillar that already functions without it (e.g., `Clocks & Fronts`, `Snap Checks`).

**Rationale:** This maintains the project's focus on **Mechanical Elegance** and **Modular Design**, keeping the core engine minimal while allowing groups to curate their desired level of granularity.

---

## Document Purpose

This is a designer-facing document intended for internal use by the design team.

It serves as a technical companion to the [Guiding Principles](guiding-principles.md) document, translating high-level philosophy into concrete, actionable design patterns. Where the `Guiding Principles` explains the **"Why"** of our design and the `Core Rules` explains the **"How,"** this document details the **"How-To"**—the specific techniques, preferred mechanics, and established patterns we use when creating new content.

Its purpose is to ensure mechanical consistency and elegance across all aspects of the game.
