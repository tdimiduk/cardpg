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
