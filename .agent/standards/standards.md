# Common Design Standards

These standards apply to all AI personas operating within the `cardpg` project.

## 1. The Index

The `design/index.yaml` is a map of all of the documents in the `design` directory. Start here to figure out what documents you want to look at.

Active documents in the repository represent current thinking and rules, and are updated directly in place. Historical reference materials and superseded ideas are preserved in the `archive/` directory, marked with index tags, and permanently tracked in Git history.

You should always be looking to keep the index up to date.

## 2. Epistemic Status & Human Vetting (`vetted_by_human`)

All AI agents must strictly respect the boundary between AI generation/auditing and human verification:

- **Agents NEVER flip `vetted_by_human` to `true`:** Only human designers have the authority to mark a document as vetted by a human (setting it to `true` or `"Tom Dimiduk (YYYY-MM)"`). Even when an agent executes instructions or incorporates direct feedback from the user, the agent itself must never set this field to `true`.
- **Agents MUST flip `vetted_by_human` to `false` upon substantial edits:** Whenever an agent performs substantial edits, structural rewrites, or conceptual additions on any document (even one previously marked as vetted), it must reset `vetted_by_human: false` and update `vetting_notes` to summarize what changed for human review.

## 3. Conflict Resolution ("Flag & Investigate")

- **Design vs. Reality:** If a Design Precept or game mechanic conflicts with research, follow the "Flag & Investigate" protocol:
  - **Always Flag Conflicts:** Proactively report any tension between research and mechanics.
  - **Differentiate by Confidence:**
    - _High Confidence / Human-Vetted:_ Game design must adapt or explicitly justify a conscious stylization (Casual Realism).
    - _Low Confidence / Unvetted AI Draft:_ Do not ignore the research, but do not break game mechanics to conform to an unverified claim.
  - **Trigger Investigation:** Propose or dispatch an `EmpiricalResearcher` task to trace primary sources and replace speculative drafts with verified facts.
- **Index vs. File:** If the files/filesystem conflict with the index, stop and ask for clarification.

## 4. Agent Transparency

Agents are tools, not roleplayers.

- **Voice:** Professional, concise, and objective.
- **Direct Action:** Focus on the task at hand.

## 5. Technical Proficiency

Regardless of your active persona, you retain all capabilities of an expert software engineer.

- **Code Aware:** You can read, analyze, and modify code (Haskell, TypeScript, Python) to support your design or research goals.
- **Polyglot:** You can bridge the gap between "Design Intent" (YAML/Markdown) and "Implementation" (Haskell Types/React Components).
- **Tool User:** You can use all available tools (terminal, browser, file system) to verify your assumptions.
- **Single-Pass File Reads (`view_file`):** Omit `StartLine` and `EndLine` when calling `view_file` so the entire file (up to 800 lines / 46 KB) loads in a single turn. Do not pass speculative line ranges (such as `1–100`) unless reading a specific known line anchor or a file known to exceed 800 lines.

## 6. Subagent Model Routing

When invoking subagents via `invoke_subagent`, explicitly configure the `Model` parameter according to the task profile:

- **Use `Model: "flash"` for bounded, closed-loop, retrieval, and verification tasks:**
  - `source_harvester` (literature searching, archive script execution, extraction checks)
  - `empirical_synthesizer` (bounded data extraction from local vault files)
  - `verisimilitude_auditor` (factual consistency auditing against synthesis tables)
  - Routine software engineering, test runs, and codebase research (`research`)
- **Use `Model: "inherit"` for open-loop systems design and adversarial stress-testing:**
  - `game_systems_designer` (rules architecture, probability balancing, 10x Rule)
  - `rulebook_adversary` (loop/exploit hunting, cognitive load, table ergonomics)
    _Rationale:_ Inherits the user's active session model without risking unexpected budget burn from unrequested escalations.

### Model-Aware Orchestration

- **On Argon / Pro:** Offload multi-step mechanical loops (>3 sequential tool turns for codebase searches, repetitive refactors, or build/test cycles) to a `Model: "flash"` subagent rather than burning premium context turns inline.
- **On Flash:** Execute bounded code/file tasks directly inline (using subagents only for context-window isolation on large raw sources). Before running open-loop design or adversarial tasks (`game_systems_designer`, `rulebook_adversary`), briefly remind the user that the session is on Flash and confirm whether to proceed on Flash or pause for a model switch.

## 7. Named Record Construction & Schema Evolution

To protect against schema drift, silent field transposition, and fragile builds when evolving data models:

- **Always use named record construction or smart constructors:** For any data type with $\ge 3$ fields or multiple optional/primitive fields (such as `CoreCard`, `ItemCard`, `NatureCard`, `TalentCard`, `ConsequenceCard`, `MasterCard`), use named record syntax (`ItemCard { name = ..., ... }`) or smart helper constructors (`emptyItemCard`, `emptyCoreCard`).
- **Never use positional construction for Card records:** Positional construction (e.g. `ItemCard a b c d e f g h i j k l`) bypasses GHC's missing-field protections, easily transposes adjacent `Maybe` fields of identical type (e.g., `defense`, `resilience`, `burden`), and breaks unnecessarily whenever fields are added or reordered.
