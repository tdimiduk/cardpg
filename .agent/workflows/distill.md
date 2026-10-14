---
description: Extract durable context, discovered findings, and open questions from a working session into a clean scratch distillation
---

# Session Distillation Workflow

Use this workflow to compress and preserve the high-value signal from an active conversation into a focused, durable artifact in `scratch/distill/` for future sessions.

---

## Core Principles

### 1. Silent Omission ("Just Let It Go")

The default handling for any idea decided to be flawed, discarded, or out of scope is to **omit it completely**.

- Do **not** narrate the failed attempt or debate it in the text.
- Do **not** leave negative warnings or disclaimers (e.g. _"Ignore concept X which was hallucinated"_). Merely mentioning discarded concepts poisons future LLM attention and resurrects them.
- If the durable findings stand on their own, let bad ideas drop entirely. If a concept is not mentioned, future agents will never be anchored by it.

### 2. Zero Chronology (Anti-Narrative)

Do **not** write chronological meeting minutes or conversational narration (_"First we explored X, then the user noticed Y, so we tried Z..."_).

- Future threads only care about **what is true now**, **what is broken**, and **what must be done next**.
- Present conclusions and findings directly and objectively.

### 3. Zero Generative Solutioneering

Do **not** invent new mechanics, card text, formulas, or implementation code unless the user explicitly requested a concrete solution.

- Agents frequently misfire by jumping from an accurate diagnosis to an unprompted, premature solution.
- Keep the diagnosis sharp and frame unresolved areas as **open design questions** or **research tensions**.

### 4. No Dogmatic Inversions

Never convert a discarded exploration into an invented absolute negative rule.

- If a candidate approach was dropped because it was flawed, do not declare that the underlying design goal is forbidden.
- Frame the problem space as an open question to explore with fresh eyes.

---

## Execution Steps

### 1. Identify Durable Content

Extract only:

- **Verified Facts & Discoveries:** Concrete bugs in code, schema omissions, rule contradictions, or physical tabletop friction uncovered.
- **Authoritative Anchors:** Exact file paths and line ranges for the affected systems.
- **Open Questions & Research Tensions:** Unresolved trade-offs or missing empirical data needed before designing.
- **Next Steps:** Actionable items for the subsequent session.

### 2. Write to `scratch/distill/`

- Target path: `scratch/distill/distill-<topic>.md`
- Notice that `scratch/` is outside `design/` and git-ignored by the main project, while containing its own standalone git repository. Distillations here never trigger `audit-index` errors, require no YAML cataloging, and do not pollute main project history.

### 3. Standard Distillation Template

```markdown
# Distilled Context: <Topic>

## 1. Discovered Findings & Friction

- <Specific bug, schema omission, or tabletop ergonomics clash>
- <Explain the root cause and why it causes friction>

## 2. Authoritative File Anchors

- [<File basename>](file:///<absolute_path>#L<start>-L<end>): <Specific role or affected schema/rule>

## 3. Open Questions & Research Tensions

- <Core trade-off or empirical evidence needed before designing>
- <Design question framed neutrally without premature solutioneering>

## 4. Next Session Actions

- [ ] <Action item 1>
- [ ] <Action item 2>
```

### 4. Commit to Local Distill Repo

After writing the file, commit it in the `scratch/distill` standalone git repo:

```bash
git -C scratch/distill add distill-<topic>.md
git -C scratch/distill commit -m "distill: <topic>"
```
