---
name: rehydrate
description: Session rehydration runbook.
---

# Session Rehydration Workflow

Use this workflow at the start of a new thread to load context from `scratch/distill/` (`distill-<topic>.md` or `plan-<topic>.md`) without premature solutioneering or unnecessary context bloat.

---

## Modes

- **Default (`/rehydrate [<topic-or-path>]`):** Fast continuation for a fresh distillation or plan. Reads **only** the target file in `scratch/distill/` on Turn 1 and treats file anchors as an on-demand index.
- **Drift Check (`/rehydrate check [<topic-or-path>]`):** Verification mode for older files that may have drifted from disk state. Audits active file anchors against the current workspace before starting work.

---

## Execution Steps

### 1. Read the Target File

Read the specified `scratch/distill/distill-<topic>.md` or `scratch/distill/plan-<topic>.md` file (matching `<topic>` against either prefix if a bare name was given). If no topic or path was specified by the user, list `scratch/distill/` and read the most recently modified `*.md` file.

### 2. Handle Ground-Truth Anchors (By Profile & Mode)

- **Active Anchor Scope (By Profile):**
  - **Topic Queue (`distill-<topic>.md`):** Scope is `## 2. Authoritative File Anchors`.
  - **Phased Plan (`plan-<topic>.md`):** Scope is **only** `## 1. Architectural Decisions` plus the **first remaining `### Thread N`** (`**Scope:**` and inline links). Ignore file links in later threads (`### Thread N+1...`) so the session neither loads nor drift-audits files for future phases.
- **Default Mode (Lazy Loading):**
  - Assume the file is current on Turn 1: do **not** read the anchored files up front.
  - Treat active anchors as an on-demand lookup table. Once a specific question, action item, or execution thread is started, read the relevant anchored file(s) before proposing edits, apply the **Line Drift Rule**, and flag any unexpected discrepancy between disk state and the specification.
- **`check` Mode (Up-Front Drift Audit):**
  - Verify every entry in the **Active Anchor Scope** against current disk state on Turn 1.
  - Confirm whether disk state still matches the invariants/contracts, or whether any open questions, action items, or steps in the next `### Thread N` have already been resolved or invalidated.
  - **Context Protection (Argon / Pro):** If `check` mode requires inspecting >3 anchored files on a heavy model tier, delegate the drift audit to a `Model: "flash"` `research` subagent and return a concise drift summary rather than loading every file into the main context window.
- **Line Drift Rule (Both Modes):** Whenever opening an anchored file, if it has been edited since the file was written, locate the target by its **Symbol, Type, or `#Heading` name** rather than trusting stale line numbers.

### 3. Hold Solutions & Actions

Do **not** immediately write code, edit design docs, or propose answers to Open Questions on Turn 1 unless the user's prompt explicitly commanded you to execute a specific action item or thread.

### 4. Report Readiness & Evaluate Candidate Guidelines

Output a brief (3–5 bullet) confirmation:

- State the loaded file and active **[Constraint]** / **[Decision]** items (or architectural invariants + the next active `### Thread N` title and scope for a Phased Plan). Do **not** load **[Candidate Guideline]** items as active constraints.
- If run in **`check` mode**, report whether the active anchored files match the specification or flag any drift noticed on disk.
- Ask the user which **Open Question**, **Candidate Guideline**, or **Next Session Action / Thread** to tackle first.

**Evaluating `[Candidate Guideline]` Items (Fresh-Context Gate):**

- Whenever the user selects a `**[Candidate Guideline]**` to evaluate—or immediately on Turn 1 if `**[Candidate Guideline]**` items are present on a Phased Plan before starting `### Thread N`, or are the **only** items remaining in a Topic Queue—use `ask_question` to interview the user on how to resolve it:
  1. **Drop as one-off:** Needs no rule (already prevented by types/tests or unlikely to recur).
  2. **Localize (preferred when needed):** Add a brief Haddock or code comment directly on the relevant symbol/function rather than growing global agent rules.
  3. **Document in domain guide / standards:** Agree on narrow, non-dogmatic wording and explicit scope boundaries before editing `design/authoring/` or [`.agent/standards/standards.md`](file:///.agent/standards/standards.md).
