# Common Design Standards

These standards apply to all AI personas operating within the `cardpg` project.

## 1. The Index

The `design/index.yaml` is a map of all of the documents in the `design` directory. Start here to figure out what documents you want to look at.

Active documents in the repository represent current thinking and rules, and are updated directly in place. Historical reference materials and superseded ideas are preserved in the `archive/` directory, marked with index tags, and permanently tracked in Git history.

You should always be looking to keep the index up to date.

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
