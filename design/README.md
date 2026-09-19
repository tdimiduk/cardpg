# caRdPG Design Repository

Welcome to the central design repository for **caRdPG**, a tabletop role-playing game about how legends are forged: through perseverance, daring, and the will to push forward when the deck is stacked against you.

This repository contains the complete design landscape of the game, from high-level philosophy and factual research to the granular details of rules, mechanics, and card content.

## How This Repository is Organized

The repository is structured into several key directories, each with a distinct purpose.

- **[philosophy](philosophy)**: The "Why." This is the heart of the project's creative vision. Start here to understand the core goals and design patterns that guide all our work.
- **[methodology](methodology)**: The Onboarding & Meta. Guides for TTRPG designers, documentation standards, and the project tagging ontology.
- **[rules](rules)**: The "How." This contains the player-facing and GM-facing rulebooks. [Core Rules](rules/core-rules.md) is the foundational document for the entire game system.
- **[research](research)**: The Factual Bedrock. This directory houses the historical, physiological, and scientific research that grounds our mechanics in "Casual Realism."
- **[iteration](iteration)**: The Workshop. This is the space for active design explorations, brainstorming, and sketching out new mechanics and ideas.

## For AI Partners (Chronicler & Artificer)

Your interaction with this repository is governed by two key documents and a core protocol.

1.  **[index.yaml](index.yaml)**: This file, located in the root, is your single source of truth for the status and purpose of every document in this repository. It is the primary law governing your understanding of canonical design.
2.  **`README.md` Files**: These prose documents provide the "why" and the specific working guidelines for their respective directories. You are to follow a **Cascading Context Protocol**: when working on a task, you will adhere to the guidelines in the `README.md` file "nearest" to your target directory, with this root document serving as the global default.

<!-- BEGIN AUTO-TOC -->

## Directory Catalog

### Foundations & Philosophy

| Document                                                          | Type              | Summary                                                                                                                         |
| :---------------------------------------------------------------- | :---------------- | :------------------------------------------------------------------------------------------------------------------------------ |
| [Guiding Principles](philosophy/guiding-principles.md)            | Design Philosophy | The 'Why.' The ultimate authority on the project's creative vision and core philosophies.                                       |
| [Game Settings](philosophy/game-settings.md)                      | Design Philosophy | A designer-facing document explaining how to tune the game's tone and mechanics to create curated play experiences.             |
| [Design Precepts](philosophy/design-precepts.md)                  | Design Patterns   | The 'How-To.' Provides concrete design patterns and case studies for creating new mechanics.                                    |
| [Paradigm Shifts](methodology/paradigm-shifts.md)                 | Meta Document     | An onboarding guide for designers familiar with other TTRPGs detailing core assumptions to un-learn.                            |
| [Documentation Standards](methodology/documentation-standards.md) | Meta Document     | The official style guide for creating and formatting all design documents in the project.                                       |
| [Tag Glossary](methodology/tag-glossary.md)                       | Meta Document     | The canonical reference for the project's tagging system. Defines the scope and usage of all tags.                              |
| [Introduction](introduction.md)                                   | Introductory Text | The primary player-facing introduction to the game. Sets tone, theme, and core player experience before rules are presented.    |
| [Agent Design Rules](AGENTS.md)                                   | Meta Document     | Operating rules, canonical hierarchies, and subagent delegation instructions for AI assistants working in the design directory. |

### Rules & Mechanics

| Document                                                | Type              | Summary                                                                                          |
| :------------------------------------------------------ | :---------------- | :----------------------------------------------------------------------------------------------- |
| [Core Rules](rules/core-rules.md)                       | Game Rules        | The foundational player-facing rules. The single most important mechanics document.              |
| [Player's Guide](rules/players-guide.md)                | Player Guide      | Strategic advice, advanced tactics, and detailed play examples complementing core-rules.md.      |
| [Gamemaster's Guide](rules/gamemaster-guide.md)         | GM Procedures     | Instructions, best practices, and advanced guidance for running the game and writing adventures. |
| [Keyword Glossary](rules/keyword-glossary.md)           | Game Rules        | Reference for the keywords in the game.                                                          |
| [Reading the Cards](rules/reading-the-cards.md)         | Game Rules        | Guide on interpreting card rules and keywords.                                                   |
| [Colors of Action](rules/colors-of-action.md)           | Action Lexicon    | An extensive lexicon to guide classifying in-game actions into Red, Yellow, or Blue.             |
| [Clocks and Fronts](rules/modules/clocks-and-fronts.md) | Game Rules Module | Optional rules for dynamic campaign play.                                                        |
| [Snap Check](rules/modules/snap-check.md)               | Game Rules Module | Optional rules for passive checks (like perception).                                             |

### Domain Catalogs

| Domain        | Directory / Sub-Index                                             | Focus & Scope                                                                                                            |
| :------------ | :---------------------------------------------------------------- | :----------------------------------------------------------------------------------------------------------------------- |
| **Iteration** | [iteration/](iteration/README.md) ([Index](iteration/index.yaml)) | Sub-index for active design explorations, mechanical constraints, proposals, and ideation sketches.                      |
| **Research**  | [research/](research/README.md) ([Index](research/index.yaml))    | Sub-index mapping empirical research reports, verisimilitude sources, living research syntheses, and game design theory. |
| **Archive**   | [archive/](archive/README.md) ([Index](archive/index.yaml))       | Sub-index preserving archived playtest content, legacy spreadsheets, and superseded research.                            |

_Last synced from `design/index.yaml` via `tools/audit_index.py`._

<!-- END AUTO-TOC -->
