---
description: Select relevant design/rules/data files via index.yaml, generate a self-contained bundle for web/external discussion, and apply the return proposal back to the repository.
---

# Topic Context Bundler & Web Discussion Handoff (`/bundle-topic`)

This workflow manages the round-trip between Antigravity (local codebase curation and edits) and an external web LLM session (high-level design debate, ludology exploration, and synthesis).

---

## Phase 1: Exporting Context for Web Discussion

### Step 1: Index-Driven File Selection

Read the lightweight index files to locate all documents related to the user's topic:

- `design/index.yaml`
- `design/iteration/index.yaml` (and any relevant subdirectory `index.yaml`)
- `design/research/index.yaml`
- `data/cards/_manifest.yaml`

Select a focused set of 5–15 files across four buckets:

1. **Baseline Law**: `design/philosophy/design-precepts.md`, `data/math-baseline.md`, `.agent/standards/systems_design_standards.md`, and relevant files in `design/rules/`.
2. **Active Iteration**: The specific proposal, schema, or trace files in `design/iteration/` under discussion.
3. **Research Synthesis**: Matching domain files in `design/research/synthesis/` (prefer synthesis over full `reports/` unless deep empirical data is explicitly requested).
4. **Data / Engine Grounding**: 1–2 representative YAML files from `data/cards/` (or `core/src/Core/` Haskell types if AST/resolution constraints are involved).

_Guardrail_: Never include generated bloat (`client/static/*.json`, `export/glossary.json`, `Core/Glossary/Generated.hs`, or `.outdated` files) unless explicitly requested.

### Step 2: Formulate Framing & Run `scripts/bundle-topic`

Write the discussion framing to a temporary file (`export/.framing.tmp`) containing:

1. The core mechanical or ludonarrative question to resolve.
2. Which iteration proposal is being evaluated against which canonical rules.
3. Specific mathematical or tabletop constraints to respect.

Invoke the bundler CLI:

```bash
./scripts/bundle-topic \
  --topic "<Concise Topic Title>" \
  --output "export/bundle-<topic-slug>.md" \
  --framing-file "export/.framing.tmp" \
  <file1> <file2> <file3> ...
```

### Step 3: Stop Immediately

Once `scripts/bundle-topic` prints its completion summary to stdout:

1. Report the output path, included file list, and token estimate to the user.
2. Remind the user they can drag-and-drop `export/bundle-<topic-slug>.md` directly into their web LLM session and say _"Address the questions in Section 2"_, then conclude with _"Wrap this up into the final proposal block"_ when done.
3. **Stop immediately**. Do NOT open, read back, or annotate the generated bundle in Antigravity.

---

## Phase 2: Ingesting the Return Proposal

When the user returns from the web session and pastes the proposal into `design/iteration/<topic>/proposal.md` (or asks you to ingest a proposal from a scratch file):

1. **Read the Proposal File**: Inspect the decisions, mechanical changes, and target files listed in the proposal.
2. **Apply Surgical Edits**:
   - Use `replace_file_content` or `write_to_file` to update canonical files under `design/rules/`, `data/cards/`, or `design/iteration/`.
   - Maintain documentation integrity and preserve unrelated existing text.
3. **Index & Metadata Updates**:
   - If a new document or iteration folder was created, add its entry and tags to the nearest `index.yaml`.
   - Update frontmatter epistemic status if transitioning from exploration to review.
4. **Verification & Formatting**:
   - Run `./scripts/format`
   - Run `./scripts/audit-index`
   - Run `cabal test tools-hs-test` (and `cabal test core-test` if engine code was touched).
5. **Summarize**: Present the diffs and verification results cleanly to the user.
