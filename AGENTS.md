# CardPG AI Agent Directives

These directives govern AI behavior and subagent orchestration across the `cardpg` project.

## Core Standards & Workflows

1. **Standards:** Always adhere to [.agent/standards/standards.md](file:///.agent/standards/standards.md).
2. **Empirical Research:** For literature retrieval, quantitative synthesis, and verisimilitude auditing, follow [.agent/workflows/empirical_research.md](file:///.agent/workflows/empirical_research.md).
3. **Rules & Game Design:** For game systems design, rules refactoring, and adversarial analysis, follow [.agent/workflows/design.md](file:///.agent/workflows/design.md).
4. **Epistemic Integrity:** Never flip `vetted_by_human` to `true`. Always reset `vetted_by_human: false` upon substantial edits to design documents.

## Subagent Model Routing (`invoke_subagent`)

When spawning subagents via `invoke_subagent`, always explicitly pass the `Model` argument to control resource usage and latency:

- **`Model: "flash"` (Fast, Bounded, Retrieval & Auditing):**
  - `source_harvester`: Literature search, CLI ingestion, extraction verification.
  - `empirical_synthesizer`: Structured parameter extraction from local vault bundles.
  - `verisimilitude_auditor`: Cross-checking rules against empirical synthesis tables.
  - Built-in `research` agent: Codebase exploration, file grepping, index checks.
  - Routine software engineering, test runs, and mechanical refactors.

- **`Model: "inherit"` (Open-Loop Systems Architecture & Stress-Testing):**
  - `game_systems_designer`: Tabletop systems design, probability modeling, 10x Rule.
  - `rulebook_adversary`: Adversarial exploit finding, loop detection, cognitive load.
    _Policy:_ Inherit the parent session's active model tier rather than escalating to unexpected premium tiers.
