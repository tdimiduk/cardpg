---
name: rehydrate
description: Session rehydration runbook.
---

# Session Rehydration Workflow

Use this workflow at the start of a new thread to load context from `scratch/distill/distill-<topic>.md` without premature solutioneering.

---

## Execution Steps

### 1. Read the Distillation

Read the target `scratch/distill/distill-<topic>.md` file (if specified). If no topic was specified by the user, list `scratch/distill/` and read the most recently modified `distill-*.md` file.

### 2. Load Ground-Truth Anchors

Read every file section listed under `## 2. Authoritative File Anchors`.

- **Line Drift Rule:** If a file has been edited since the distillation was written, locate the target by its **Symbol, Type, or `#Heading` name** rather than trusting stale line numbers.
- Confirm whether the disk state still reflects the findings and constraints described in the distillation.

### 3. Hold Solutions & Actions

Do **not** immediately write code, edit design docs, or propose answers to `## 3. Open Questions` on Turn 1 unless the user's prompt explicitly commanded you to execute a specific action item.

### 4. Report Readiness

Output a brief (3–5 bullet) confirmation:

- Confirm that the anchored files match the distilled findings (or flag any drift noticed on disk).
- State the active **[Constraint]** and **[Decision]** items loaded into working memory.
- Ask the user which **Open Question** or **Next Session Action** to tackle first.
