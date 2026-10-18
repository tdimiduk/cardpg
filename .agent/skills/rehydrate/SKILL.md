---
name: rehydrate
description: Session rehydration runbook.
---

# Session Rehydration Workflow

Use this workflow at the start of a new thread to load context from `scratch/distill/distill-<topic>.md` without premature solutioneering or unnecessary context bloat.

---

## Modes

- **Default (`/rehydrate [<topic-or-path>]`):** Fast continuation for a fresh distillation. Reads **only** the distillation file on Turn 1 and treats file anchors as an on-demand index.
- **Drift Check (`/rehydrate check [<topic-or-path>]`):** Verification mode for older distillations that may have drifted from disk state. Audits all file anchors against the current workspace before starting work.

---

## Execution Steps

### 1. Read the Distillation

Read the target `scratch/distill/distill-<topic>.md` file (if specified). If no topic or path was specified by the user, list `scratch/distill/` and read the most recently modified `distill-*.md` file.

### 2. Handle Ground-Truth Anchors (By Mode)

- **Default Mode (Lazy Loading):**
  - Assume the distillation is current on Turn 1: do **not** read the files listed under `## 2. Authoritative File Anchors` up front.
  - Treat Section 2 as an on-demand lookup table. Once a specific question or action item is selected, read the relevant anchored file(s) before proposing edits, apply the **Line Drift Rule**, and flag any unexpected discrepancy between disk state and the distillation.
- **`check` Mode (Up-Front Drift Audit):**
  - Verify every entry under `## 2. Authoritative File Anchors` against current disk state on Turn 1.
  - Confirm whether disk state still matches the distilled findings/constraints, or whether any open questions/action items have already been resolved or invalidated.
  - **Context Protection (Argon / Pro):** If `check` mode requires inspecting >3 anchored files on a heavy model tier, delegate the drift audit to a `Model: "flash"` `research` subagent and return a concise drift summary rather than loading every file into the main context window.
- **Line Drift Rule (Both Modes):** Whenever opening an anchored file, if it has been edited since the distillation was written, locate the target by its **Symbol, Type, or `#Heading` name** rather than trusting stale line numbers.

### 3. Hold Solutions & Actions

Do **not** immediately write code, edit design docs, or propose answers to `## 3. Open Questions` on Turn 1 unless the user's prompt explicitly commanded you to execute a specific action item.

### 4. Report Readiness

Output a brief (3–5 bullet) confirmation:

- State the loaded distillation file and active **[Constraint]** / **[Decision]** items in working memory.
- If run in **`check` mode**, report whether the anchored files match the distillation or flag any drift noticed on disk.
- Ask the user which **Open Question** or **Next Session Action** to tackle first.
