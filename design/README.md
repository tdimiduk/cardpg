# caRdPG Design Repository

Welcome to the central design repository for **caRdPG**, a tabletop role-playing game about how legends are forged: through perseverance, daring, and the will to push forward when the deck is stacked against you.

This repository contains the complete design landscape of the game, from high-level philosophy and factual research to the granular details of rules, mechanics, and card content.

## How This Repository is Organized

The repository is structured into several key directories, each with a distinct purpose.

- **[philosophy](philosophy)**: The "Why." This is the heart of the project's creative vision. Start here to understand the core goals and design patterns that guide all our work.
- **[methodology](methodology)**: The Onboarding & Meta. Guides for TTRPG designers, documentation standards, and the project tagging ontology.
- **[rules](rules)**: The "How." This contains the player-facing and GM-facing rulebooks. [Core Rules](rules/core-rules.md) is the foundational document for the entire game system.
- **[research](research)**: The Factual Bedrock. This directory houses the historical, physiological, and scientific research that grounds our mechanics in "Casual Realism."
- **[authoring](authoring)**: Content Creation & Schemas. Authoring standards, technical specifications, schemas, and content creation guides for cards, hazards, and adventure modules.
- **[iteration](iteration)**: The Workshop. This is the space for active design explorations, brainstorming, and sketching out new mechanics and ideas.

## For AI Partners (Chronicler & Artificer)

Your interaction with this repository is governed by two key documents and a core protocol.

1.  **[index.yaml](index.yaml)**: This file, located in the root, is your single source of truth for the status and purpose of every document in this repository. It is the primary law governing your understanding of canonical design.
2.  **`README.md` Files**: These prose documents provide the "why" and the specific working guidelines for their respective directories. You are to follow a **Cascading Context Protocol**: when working on a task, you will adhere to the guidelines in the `README.md` file "nearest" to your target directory, with this root document serving as the global default.

<!-- BEGIN AUTO-TOC -->

## Directory Catalog

### Foundations & Philosophy

| Document                                                                          | Summary                                                                                                                         |
| :-------------------------------------------------------------------------------- | :------------------------------------------------------------------------------------------------------------------------------ |
| [Guiding Principles](philosophy/guiding-principles.md)                            | The 'Why.' The ultimate authority on the project's creative vision and core philosophies.                                       |
| [Campaign Dimensions: Curating the Experience](philosophy/campaign-dimensions.md) | A designer-facing document explaining how to tune the engine's dimensions of variation to curate play experiences.              |
| [Narrative Baseline: Grounded Heroism](philosophy/narrative-baseline.md)          | The canonical scenario-authoring guide, adventure lifecycle, and evaluation rubric for caRdPG's flagship Grounded Heroism mode. |
| [Design Precepts](philosophy/design-precepts.md)                                  | The 'How-To.' Provides concrete design patterns and case studies for creating new mechanics.                                    |
| [Paradigm Shifts](methodology/paradigm-shifts.md)                                 | An onboarding guide for designers familiar with other TTRPGs detailing core assumptions to un-learn.                            |
| [Documentation Standards](methodology/documentation-standards.md)                 | The official style guide for creating and formatting all design documents in the project.                                       |
| [Tag Glossary](methodology/tag-glossary.md)                                       | The canonical reference for the project's tagging system. Defines the scope and usage of all tags.                              |
| [Introduction](introduction.md)                                                   | The primary player-facing introduction to the game. Sets tone, theme, and core player experience before rules are presented.    |
| [Agent Design Rules](AGENTS.md)                                                   | Operating rules, canonical hierarchies, and subagent delegation instructions for AI assistants working in the design directory. |

### Rules & Mechanics

| Document                                                                                                         | Summary                                                                                                                                                            |
| :--------------------------------------------------------------------------------------------------------------- | :----------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| [Core Rules](rules/core-rules.md)                                                                                | The foundational player-facing rules. The single most important mechanics document.                                                                                |
| [Player's Guide](rules/players-guide.md)                                                                         | Strategic advice, advanced tactics, and detailed play examples complementing core-rules.md.                                                                        |
| [Gamemaster's Guide](rules/gamemaster-guide.md)                                                                  | Instructions, best practices, and advanced guidance for running the game and writing adventures.                                                                   |
| [Designers Guide](authoring/designers-guide.md)                                                                  | Technical specifications, card anatomy schemas, time accounting standards, and mathematical attrition budgets for card and adventure authors.                      |
| [Authoring Guide: Card Schemas and Mini-DSL Syntax](authoring/card-schemas-and-syntax.md)                        | Authoritative data schemas, YAML layouts, and Mini-DSL grammar for CoreCard, ItemCard, NatureCard, and ConsequenceCard definitions.                                |
| [Authoring Guide: Locations, Travel, and Clock Cards](authoring/locations-and-travel.md)                         | Data schemas, card anatomy, and authoring standards for Location Cards, Travel Cards, and Living Clock Decks.                                                      |
| [Advancement and Progression: Emerging Patterns and Design Heuristics](authoring/advancement-and-progression.md) | Emerging design heuristics and exploratory patterns for authoring character advancement, equipment progression, and logistical evolution.                          |
| [Keyword Glossary](rules/keyword-glossary.md)                                                                    | Reference for the keywords in the game.                                                                                                                            |
| [Reading The Cards](rules/reading-the-cards.md)                                                                  | Guide on interpreting card rules and keywords.                                                                                                                     |
| [Authoring Guide: Consequences and Status Conditions](authoring/consequences.md)                                 | This guide provides practical instructions and design principles for authors creating complications, injuries, physical strains, and status cards for \*\*caRdP... |
| [Colors Of Action](rules/colors-of-action.md)                                                                    | An extensive lexicon to guide classifying in-game actions into Red, Yellow, or Blue.                                                                               |
| [Clocks And Fronts](rules/modules/clocks-and-fronts.md)                                                          | Optional rules for dynamic campaign play.                                                                                                                          |
| [Snap Check](rules/modules/snap-check.md)                                                                        | Optional rules for passive checks (like perception).                                                                                                               |
| [Rules Module: Narrative Actions](rules/modules/narrative-actions.md)                                            | This module provides rules for resolving improvised, freeform actions during **Crisis Time**.                                                                      |
| [Rules Module: Selective Commitment](rules/modules/selective-commitment.md)                                      | Optional rules for committing a measured subset of your Ready Hand during Adventuring Time General Actions.                                                        |
| [Rules Module: Hyper-Vigilance](rules/modules/hyper-vigilance.md)                                                | In the core rules, characters maintain **[[Vigilance]]** as a pool of 0 to 4 cards, representing disciplined, sustainable readiness on the road and on watch,...   |

### Domain Catalogs

| Domain        | Directory / Sub-Index                                             | Focus & Scope                                                                                                            |
| :------------ | :---------------------------------------------------------------- | :----------------------------------------------------------------------------------------------------------------------- |
| **Iteration** | [iteration/](iteration/README.md) ([Index](iteration/index.yaml)) | Sub-index for active design explorations, mechanical constraints, proposals, and ideation sketches.                      |
| **Research**  | [research/](research/README.md) ([Index](research/index.yaml))    | Sub-index mapping empirical research reports, verisimilitude sources, living research syntheses, and game design theory. |
| **Archive**   | [archive/](archive/README.md) ([Index](archive/index.yaml))       | Sub-index preserving archived playtest content, legacy spreadsheets, and superseded research.                            |

_Last synced from `design/index.yaml` via `audit-index`._

<!-- END AUTO-TOC -->
