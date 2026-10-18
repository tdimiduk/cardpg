---
name: distill
description: Session distillation runbook.
---

# Session Distillation Workflow

Use this workflow to maintain `scratch/distill/` as a lean, forward-looking **active work queue** across two document profiles:

1. **Topic Queue (`scratch/distill/distill-<topic>.md`):** Rules design, empirical research, and bug triage.
2. **Phased Implementation Plan (`scratch/distill/plan-<topic>.md`):** Multi-thread code & architecture plans organized into ordered `### Thread N` phases.

**Scope Rule:** Never edit canonical repository files (`design/`, `.agent/standards/`, or source code) during `/distill`. Only modify `scratch/distill/` (if distilling a standalone plan in `scratch/*.md`, migrate it to `scratch/distill/plan-<topic>.md`).

Execute these steps strictly in order. Do not narrate the session history.

---

## Step 1: Full-Thread & Existing-File Scan (Forward-Only State)

Scan the **entire** session from Turn 1 to the present alongside the existing target file in `scratch/distill/`. Partition everything into **Remaining Work** vs. **Completed Work**:

1. **Prune Completed Work & Propagate Contracts Forward:**
   - **Both Profiles:** Remove every action item completed during this session, every open question resolved and applied, and any **Finding**, **Constraint**, **Decision**, or **Authoritative File Anchor** that existed solely to support completed items or whose fix is now live in the codebase.
   - **Phased Plans (`plan-<topic>.md`):**
     - **Delete completed `### Thread N` sections completely.** Never keep `COMPLETE` headers, `- [x]` checklists, or retrospective `Lessons Learned` blocks under finished phases.
     - **Audit remaining `### Thread N+1...` sections in place:**
       - Delete any sub-step in a later thread that was pulled forward and already implemented in Thread $N$.
       - Fold concrete API contracts, helper names, and `[Symbol](file:///...#L...)` links created in Thread $N$ **directly into the specific step of Thread $N+1...$ that consumes them** (or into `## 1. Architectural Decisions` if cross-cutting).
2. **Surface Non-Obvious Traps as Candidate Guidelines (Default to Skepticism):**
   - Most completed work needs no new rules (especially if already enforced by types, tests, or existing docs).
   - If completed work uncovered a genuinely non-obvious codebase or design trap likely to recur beyond the specific steps of this plan, **do not** draft a generalized rule, write a `Lessons Learned` essay, or add an imperative action item to edit `standards.md`. End-of-thread recency bias leads to overly rigid rules.
   - Instead, record only the **concrete episode** as a `**[Candidate Guideline]**` (see templates in Step 3) so the next fresh session can evaluate it with the user before starting work.
3. **Collect Remaining Forward-Looking Signal:**
   - **Verified Facts & Friction:** Unresolved bugs, schema gaps, rule contradictions, or tabletop ergonomic clashes that still need fixing.
   - **Discovered Invariants & Unapplied Decisions:** Positive constraints and settled directions that govern the **remaining** open questions or execution threads.
   - **Authoritative File Anchors:** Exact paths, line ranges, and symbol/heading names needed to execute the **remaining** work.
   - **Open Questions:** Unresolved trade-offs framed neutrally.

---

## Step 2: Strict Filtering Rules (Hard Bans)

When drafting or updating the file, obey these five hard constraints:

1. **BAN Completed Items & Changelog Cruft:** Never keep checked checkboxes (`- [x]`), `COMPLETE` thread sections, `Lessons Learned` retrospectives, `[Settled]` tags under Open Questions, or summaries of work already landed on disk. Every file in `scratch/distill/` is a remaining-work specification, never a session log or victory lap.
2. **BAN Dead Ideas (Silent Omission):** Omit discarded proposals completely. Never write _"We tried X and dropped it"_ or _"Do not use X"_. Merely mentioning rejected concepts anchors future sessions on them. If durable findings stand on their own, let bad ideas drop entirely.
3. **BAN Chronology (Anti-Narrative):** Never use narrative phrasing (_"First we looked at..."_, _"Then the user noted..."_, _"In Thread 1 we added..."_). Write only timeless present-tense facts describing **what is true on disk now**, **what is still broken**, and **what must be done next**.
4. **BAN Unprompted Solutions & Premature Rules (Zero Solutioneering):**
   - In a **Topic Queue (`distill-<topic>.md`)**, do not invent new mechanics, formulas, card text, or code to solve open questions.
   - In a **Phased Plan (`plan-<topic>.md`)**, preserve agreed-upon architecture diagrams, data structures, and function signatures in remaining threads, but do not invent unprompted scope or generalize from a single bug into project-wide standards. Frame unresolved design trade-offs as `**[Question]**` and potential durable lessons as `**[Candidate Guideline]**`.
5. **BAN Dogmatic Inversions:** If one specific candidate failed, do not state that the broader design goal is impossible or forbidden. Frame the problem space neutrally to explore with fresh eyes.

---

## Step 3: Write or Retire (`distill-<topic>.md` or `plan-<topic>.md`)

> [!NOTE]
> `scratch/` is outside `design/` and git-ignored by the main project, while `scratch/distill/` contains its own standalone git repository. Files here never trigger `audit-index` errors, require no YAML cataloging, and do not pollute main project history.

If zero open questions, zero candidate guidelines, and zero remaining action items or execution threads remain, report that the file is complete and ask the user whether to retire (`git -C scratch/distill rm`) it.

Otherwise, overwrite the target file using the matching profile structure:

### Profile A: Topic Queue (`scratch/distill/distill-<topic>.md`)

_(Omit Section 1, 3, or 4 if no active bullets remain for that section.)_

```markdown
# Distilled Context: <Topic>

## 1. Findings, Constraints & Settled Decisions

- **[Finding]** <Unresolved bug, schema gap, or tabletop friction and its root cause>
- **[Constraint]** <Positive invariant or boundary condition governing remaining work>
- **[Decision]** <Explicitly agreed-upon direction from this session not yet applied to main repo>

## 2. Authoritative File Anchors

- [<File basename>](file:///<absolute_path>#L<start>-L<end>) (`<Symbol, Type, or #Heading>`): <Why this location matters for remaining work>

## 3. Open Questions & Research Tensions

- **[Question]** <Neutral framing of an unresolved trade-off or missing empirical design data>
- **[Candidate Guideline]** <Concrete case observed during completed work and why it was non-obvious> — evaluate whether to drop as a one-off, note in a local Haddock/code comment, or generalize into <candidate doc>

## 4. Next Session Actions

- [ ] <Concrete remaining action item 1 (specify target files or workflows)>
- [ ] <Concrete remaining action item 2>
```

### Profile B: Phased Implementation Plan (`scratch/distill/plan-<topic>.md`)

_(Keep only remaining unexecuted `### Thread N` sections. Omit Section 4 if no active questions or candidate guidelines exist.)_

```markdown
# Implementation Plan: <Topic>

## 1. Architectural Decisions & State Flow

<Cross-cutting architectural invariants and optional Mermaid state/data-flow diagram>

## 2. Execution Threads

### Thread <N>: <Phase Title>

**Scope:** [<File basename>](file:///<absolute_path>), ...

1. **<Step Group>**:
   - <Concrete implementation instruction with inline [Symbol](file:///<absolute_path>#L<start>-L<end>) contracts from already-landed code>

## 3. Verification Plan

1. **<Test Suite / Target>**: <Remaining verification checks>

## 4. Open Questions & Candidate Guidelines

- **[Question]** <Unresolved design/implementation question blocking an upcoming thread>
- **[Candidate Guideline]** <Concrete case observed during completed thread and why it was non-obvious> — evaluate whether to drop as a one-off, note in a local Haddock/code comment, or generalize into <candidate doc>
```

---

## Step 4: Self-Audit & Commit (When Writing/Updating)

1. **Self-Audit:** Verify the written file before committing:
   - Are there any `- [x]` items, `COMPLETE` threads, `Lessons Learned` sections, `[Settled]` questions, or findings/anchors that only mattered for already-completed tasks? Strip them.
   - _(Phased Plans)_ Does any upcoming `### Thread` still instruct the agent to implement something that was pulled forward into an earlier thread, or lack the inline `[Symbol](file:///...)` link for a helper created in the just-completed thread? Update the upcoming thread steps in place.
   - Did any `**[Candidate Guideline]**` sneak into Section 1 as a hard `[Constraint]` or into an execution step as an imperative doc-edit action? Move it to `Open Questions & Candidate Guidelines` and strip dogmatic phrasing.
   - Are there any rejected ideas, chronological narratives, or unprompted solutions? Strip them.
2. **Commit to the standalone scratch git repository:**

```bash
mkdir -p scratch/distill
[ -d scratch/distill/.git ] || git -C scratch/distill init
git -C scratch/distill add <filename>.md
git -C scratch/distill commit -m "distill: <topic>"
```
