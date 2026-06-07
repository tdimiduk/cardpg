# Tag Glossary & Ontology

## Document Purpose

This is a designer-facing document intended for internal use.

Its purpose is to serve as the single source of truth for the project's tagging system. It defines the scope, meaning, and intended use of each tag category and provides a list of canonical tags. This ensures that as the project grows, its metadata remains consistent, structured, and queryable. All new documents added to `index.yaml` should be tagged in accordance with this glossary.

---

## Tagging Categories

Tags are organized into four primary categories, each serving a distinct filtering and organizational purpose.

### `doc-type`

This tag describes the fundamental nature or format of the document. It answers the question: "What _is_ this file?"

- **`doc-type:rules`**: The document contains formal, player- or GM-facing game rules.
- **`doc-type:module`**: An optional, self-contained set of rules that can be added to the core game.
- **`doc-type:philosophy`**: A high-level document explaining the "Why" behind the game's design.
- **`doc-type:research-report`**: A deep-dive analysis of external, real-world factual data.
- **`doc-type:research-synthesis`**: A document that translates raw research into actionable design insights.
- **`doc-type:content-library`**: A collection of game content, such as cards, items, or lexicon entries.
- **`doc-type:meta`**: A document about the design process or project structure itself, like this glossary.

### `audience`

This tag describes the primary intended reader of the document. It answers the question: "Who is this written for?"

- **`audience:player-facing`**: The content is intended to be read by players.
- **`audience:gm-facing`**: The content is intended for the Gamemaster.
- **`audience:designer-facing`**: The content is for the internal design team and discusses process, rationale, or factual basis.

### `pillar`

This tag connects a document to one of the four core pillars of play as defined in `philosophy/guiding-principles.md`. A document can have multiple pillar tags. It answers the question: "Which part of the game does this relate to?"

- **`pillar:combat`**: Relates to the combat system and associated actions.
- **`pillar:exploration`**: Relates to travel, discovery, and overcoming environmental challenges.
- **`pillar:social`**: Relates to social interaction, intrigue, and negotiation.
- **`pillar:downtime`**: Relates to activities, recovery, and world progression between active adventures.

### `core-concept`

This is the most granular and important tag category. It pinpoints the specific mechanical, systemic, or narrative concepts a document addresses. This list is expected to grow over time. It answers the question: "What specific ideas are in this document?"

- **`core-concept:action-resolution`**: The fundamental mechanics of how actions are performed and resolved.
- **`core-concept:armor`**: The mechanics and design principles related to armor.
- **`core-concept:consequences`**: The system for negative outcomes from actions.
- **`core-concept:fatigue`**: The mechanics of tiredness, exhaustion, and the `Fatigue` card.
- **`core-concept:harm`**: The system for modeling physical injury and wounds.
- **`core-concept:lethality`**: Concepts related to character death and dying states.
- **`core-concept:movement`**: Mechanics and principles related to tactical movement and positioning.
- **`core-concept:pacing`**: The rhythm and tempo of gameplay, especially in combat.
- **`core-concept:reach`**: The concept of weapon lengths and threat zones.
- **`core-concept:verisimilitude`**: The principle of grounding design in real-world data.
- **`core-concept:disengagement`**: Mechanics and principles for creating separation and safely leaving a combat encounter.
- **`core-concept:hand-management`**: Principles regarding the optimal size, retention, and cycling of a player's hand of cards.
- **`core-concept:status-cards`**: Design rules and mechanics for cards representing negative states (Fatigue, Minor Wound, etc.) added to a deck.
