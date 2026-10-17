# CardPG AI Agent Directives

These directives govern AI behavior and subagent orchestration across the `cardpg` project.

## Core Standards & Workflows

1. **Standards:** Always adhere to [.agent/standards/standards.md](file:///.agent/standards/standards.md).
2. **Empirical Research:** For literature retrieval, quantitative synthesis, and verisimilitude auditing, follow [.agent/workflows/empirical_research.md](file:///.agent/workflows/empirical_research.md).
3. **Rules & Game Design:** For game systems design, rules refactoring, and adversarial analysis, follow [.agent/workflows/design.md](file:///.agent/workflows/design.md).
4. **Epistemic Integrity:** Never flip `vetted_by_human` to `true`. Always reset `vetted_by_human: false` upon substantial edits to design documents.
5. **Single-Pass File Reads (`view_file`):** `view_file` returns up to 800 lines (46 KB) when `StartLine` and `EndLine` are omitted, and nearly every markdown/code file in this repository is under 800 lines. Omit `StartLine` and `EndLine` to read files in a single tool turn rather than guessing conservative line slices (e.g., `1–100`), unless targeting a specific known line-range anchor or a large generated/vault file (`>800` lines).

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

## Model-Aware Orchestration (Active Session Tier)

Adapt execution strategy based on the parent session's active model (visible via `<USER_SETTINGS_CHANGE>`):

1. **When running on a heavy/premium model (e.g., Argon / Pro):**
   - **Protect quota by offloading multi-step mechanical loops:** Each inline tool call re-processes the entire conversation context at the active model's token rate. If a task requires >3 sequential mechanical tool turns (e.g., multi-file searches, repetitive edits, build-fix-test loops, or index/lint cleanups), delegate the bounded loop to a `Model: "flash"` subagent (`research` or `self`) and review the result in a single turn.
2. **When running on a lightweight model (e.g., Flash):**
   - **Execute bounded work inline:** Perform routine file reads, edits, and test runs directly in the main session unless subagent isolation is needed to keep large raw text files (such as `extracted.txt` vault dumps) out of the main context window.
   - **Flag open-loop `inherit` tasks:** Before launching `game_systems_designer` or `rulebook_adversary` (or performing deep open-loop rules synthesis), briefly alert the user that the session is currently on Flash so `inherit` will also run on Flash, and ask whether to proceed or wait for a model switch.
