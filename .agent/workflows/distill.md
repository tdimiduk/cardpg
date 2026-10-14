---
description: Compress durable findings, file anchors, and open questions from a working session into scratch/distill/
---

# Session Distillation Workflow

Use this workflow to compress and preserve the high-value signal from an active conversation into a focused, durable artifact in `scratch/distill/` for future sessions.

Execute these steps strictly in order. Do not narrate the session history.

---

## Step 1: Full-Thread Scan (Countering Recency Bias)

Before writing, scan the **entire** session from Turn 1 to the present—not just the final turns. Collect only:

1. **Verified Facts & Friction:** Concrete code bugs, schema gaps, rule contradictions, or tabletop ergonomic clashes.
2. **Discovered Invariants:** Subtle constraints uncovered when an approach failed (record the **positive invariant**, drop the failed proposal).
3. **Settled Decisions:** Design or code directions explicitly agreed upon by the user during this session.
4. **Authoritative File Anchors:** Exact relative paths, line ranges, and symbol/heading names inspected or modified.
5. **Open Questions:** Unresolved trade-offs framed neutrally.

---

## Step 2: Strict Filtering Rules (Hard Bans)

When drafting the distillation, obey these four hard constraints:

1. **BAN Dead Ideas (Silent Omission):** Omit discarded proposals completely. Never write _"We tried X and dropped it"_ or _"Do not use X"_. Merely mentioning rejected concepts anchors future sessions on them. If durable findings stand on their own, let bad ideas drop entirely.
2. **BAN Chronology (Anti-Narrative):** Never use narrative phrasing (_"First we looked at..."_, _"Then the user noted..."_, _"Earlier in the thread..."_). Write only timeless present-tense facts. Future threads only care about **what is true now**, **what is broken**, and **what must be done next**.
3. **BAN Unprompted Solutions (Zero Solutioneering):** Do not invent new mechanics, formulas, card text, or code to solve open questions. If it was not explicitly settled in this thread, frame it as an **open design question** or **research tension**.
4. **BAN Dogmatic Inversions:** If one specific candidate failed, do not state that the broader design goal is impossible or forbidden. Frame the problem space neutrally to explore with fresh eyes.

---

## Step 3: Write to `scratch/distill/distill-<topic>.md`

Overwrite `scratch/distill/distill-<topic>.md` if it already exists.

> [!NOTE]
> `scratch/` is outside `design/` and git-ignored by the main project, while containing its own standalone git repository. Distillations here never trigger `audit-index` errors, require no YAML cataloging, and do not pollute main project history.

Use this exact structure and bullet prefixes:

```markdown
# Distilled Context: <Topic>

## 1. Findings, Constraints & Settled Decisions

- **[Finding]** <Concrete bug, schema gap, or tabletop friction and its root cause>
- **[Constraint]** <Positive invariant or boundary condition that any future design must satisfy>
- **[Decision]** <Explicitly agreed-upon direction from this session not yet applied to main repo>

## 2. Authoritative File Anchors

- [<File basename>](file:///<absolute_path>#L<start>-L<end>) (`<Symbol, Type, or #Heading>`): <Why this location matters>

## 3. Open Questions & Research Tensions

- **[Question]** <Neutral framing of an unresolved trade-off or missing empirical design data>

## 4. Next Session Actions

- [ ] <Concrete action item 1 (specify target files or workflows)>
- [ ] <Concrete action item 2>
```

---

## Step 4: Self-Audit & Commit

1. **Self-Audit:** Check your written file before committing. If it contains any mention of a rejected idea, any chronological storytelling, or any unprompted solution, edit the file immediately to strip it.
2. **Commit to the standalone scratch git repository:**

```bash
mkdir -p scratch/distill
[ -d scratch/distill/.git ] || git -C scratch/distill init
git -C scratch/distill add distill-<topic>.md
git -C scratch/distill commit -m "distill: <topic>"
```
