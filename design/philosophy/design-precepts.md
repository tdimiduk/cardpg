# Design Precepts

## Core Engine Philosophy

These precepts define the fundamental user-facing experience of the game's resolution systems.

### Default to Success at a Cost
**Core Principle:** Actions are presumed to succeed at their immediate goal. The core tension of the game does not come from asking "if" an action works, but "at what cost?" Outright failure is an exceptional outcome that must be explicitly stated on a `Consequence Card`.

**Rationale:** This is the central mechanical implementation of our "Fail Forward & Narrative Momentum" guiding principle. It ensures the story never stalls on a single bad roll.

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

---

## Content & Experience Design

These precepts guide the design of player-facing content like cards, consequences, and advancement systems.

### Apply the Three Core `Color`s as a Universal Framework
**Core Principle:** The three Core `Color`s are the primary framework for categorizing actions and ensuring all character archetypes have meaningful ways to contribute to any challenge across all Pillars of Play.

**Rationale:** This ensures that all characters can meaningfully contribute to any scene, transforming encounters into multi-faceted puzzles for the entire party.

### Model Harm as a Tangible, Multi-Stage Process
**Core Principle:** Harm and its resolution should be modeled as a tangible, multi-stage process that creates new tactical and narrative challenges, never as simple numerical attrition.

**Rationale:** This supports the "Illusion of Lethality" and "Fail Forward" principles by using `Status Cards` to model accumulating wear and `Condition Cards` to represent specific tactical problems. Furthermore, it establishes that character death is the ultimate outcome of a telegraphed *process*, not a random event.

### Design Advancement and Archetypes for Tangibility
**Core Principle:** Character advancement should provide tangible, exciting new tools, not just abstract numerical improvements. Core character fantasies should be supported by specific, active mechanics, not just passive stats.

**Rationale:** This makes advancement feel more meaningful and reinforces the `Grounded Heroism` principle by rewarding players with new, dramatic capabilities.

### Enforce Action on Zero-Value Cards

Enforce Action on Zero-Value Cards

**Core Principle:** Any Status Card with zero stats (0/0/0) should generally have a mechanic that forces it out of the player's hand (for example the Injury card).

**Rationale:** This prevents the "optimal play" problem where players hoard useless cards to keep their draw deck thin and efficient. It ensures that drawing a "dead" card is always an immediate tactical hindrance that must be dealt with, reinforcing the Deck as Life pattern.

---

## Document Purpose

This is a designer-facing document intended for internal use by the design team.

It serves as a technical companion to the [Guiding Principles](guiding-principles.md) document, translating high-level philosophy into concrete, actionable design patterns. Where the `Guiding Principles` explains the **"Why"** of our design and the `Core Rules` explains the **"How,"** this document details the **"How-To"**—the specific techniques, preferred mechanics, and established patterns we use when creating new content.

Its purpose is to ensure mechanical consistency and elegance across all aspects of the game.
