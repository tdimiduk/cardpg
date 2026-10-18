---
name: distill
description: Session distillation runbook.
---

# Session Distillation Workflow

Use this workflow to maintain `scratch/distill/` as a lean, forward-looking **active work queue**. Each `distill-<topic>.md` file tracks only **unresolved** design tensions, **unapplied** decisions, and **remaining** action items—plus the minimum context needed to execute them.

**Scope Rule:** Never edit canonical repository files (`design/`, `.agent/standards/`, or source code) during `/distill`. Only modify `scratch/distill/`.

Execute these steps strictly in order. Do not narrate the session history.

---

## Step 1: Full-Thread & Existing-File Scan (Forward-Only State)

Scan the **entire** session from Turn 1 to the present alongside the existing `scratch/distill/distill-<topic>.md` (if updating). Partition everything into **Remaining Work** vs. **Completed Work**:

1. **Prune Completed Work & Its Scaffolding:**
   - Remove every action item completed during this session and every open question resolved and applied.
   - Remove any **Finding**, **Constraint**, **Decision**, or **Authoritative File Anchor** that existed solely to support those completed items or whose fix is now live in the codebase.
2. **Surface Non-Obvious Traps as Candidate Guidelines (Default to Skepticism):**
   - Most completed work needs no new rules (especially if already enforced by types, tests, or existing docs).
   - If completed work uncovered a genuinely non-obvious trap likely to recur elsewhere, **do not** draft a generalized rule or add an imperative action item to edit `standards.md`. End-of-thread recency bias leads to overly rigid rules.
   - Instead, record only the **concrete episode** under `## 3. Open Questions & Research Tensions` as a `**[Candidate Guideline]**` (see template in Step 3) so a fresh session can evaluate it with the user.
3. **Collect Remaining Forward-Looking Signal:**
   - **Verified Facts & Friction:** Unresolved bugs, schema gaps, rule contradictions, or tabletop ergonomic clashes that still need fixing.
   - **Discovered Invariants & Unapplied Decisions:** Positive constraints and settled directions that govern the **remaining** open questions or action items.
   - **Authoritative File Anchors:** Exact relative paths, line ranges, and symbol/heading names needed to execute the **remaining** work.
   - **Open Questions:** Unresolved trade-offs framed neutrally.

---

## Step 2: Strict Filtering Rules (Hard Bans)

When drafting or updating the distillation, obey these five hard constraints:

1. **BAN Completed Items & Changelog Cruft:** Never keep checked checkboxes (`- [x]`), `[Settled]` tags under Open Questions, or summaries of work already landed on disk. A distillation is a remaining-work specification, never a session log or victory lap.
2. **BAN Dead Ideas (Silent Omission):** Omit discarded proposals completely. Never write _"We tried X and dropped it"_ or _"Do not use X"_. Merely mentioning rejected concepts anchors future sessions on them. If durable findings stand on their own, let bad ideas drop entirely.
3. **BAN Chronology (Anti-Narrative):** Never use narrative phrasing (_"First we looked at..."_, _"Then the user noted..."_, _"In the previous session..."_). Write only timeless present-tense facts describing **what is true on disk now**, **what is still broken**, and **what must be done next**.
4. **BAN Unprompted Solutions & Premature Rules (Zero Solutioneering):** Do not invent new mechanics, formulas, card text, code, or project-wide standards to solve open questions or generalize from a single bug. Frame unresolved design trade-offs as `**[Question]**` and potential durable lessons as `**[Candidate Guideline]**`.
5. **BAN Dogmatic Inversions:** If one specific candidate failed, do not state that the broader design goal is impossible or forbidden. Frame the problem space neutrally to explore with fresh eyes.

---

## Step 3: Write or Retire `scratch/distill/distill-<topic>.md`

> [!NOTE]
> `scratch/` is outside `design/` and git-ignored by the main project, while containing its own standalone git repository. Distillations here never trigger `audit-index` errors, require no YAML cataloging, and do not pollute main project history.

If zero open questions, zero candidate guidelines, and zero action items remain, report that `distill-<topic>.md` is complete and ask the user whether to retire (`git -C scratch/distill rm`) it.

Otherwise, overwrite `scratch/distill/distill-<topic>.md` using this structure (omit Section 1, 3, or 4 if no active bullets remain for that section):

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

---

## Step 4: Self-Audit & Commit (When Writing/Updating)

1. **Self-Audit:** Verify the written file before committing:
   - Are there any `- [x]` items, `[Settled]` questions, or findings/anchors that only mattered for already-completed tasks? Strip them.
   - Did any `**[Candidate Guideline]**` sneak into Section 1 as a hard `[Constraint]` or Section 4 as an imperative doc-edit action? Move it to Section 3 and strip dogmatic phrasing.
   - Are there any rejected ideas, chronological narratives, or unprompted solutions? Strip them.
2. **Commit to the standalone scratch git repository:**

```bash
mkdir -p scratch/distill
[ -d scratch/distill/.git ] || git -C scratch/distill init
git -C scratch/distill add distill-<topic>.md
git -C scratch/distill commit -m "distill: <topic>"
```
