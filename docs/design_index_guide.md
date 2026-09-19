# Design Index Maintenance Guide

This document outlines the step-by-step instructions to synchronize the systems design registry (`design/index.yaml`) and its sub-indexes with the physical files in your filesystem.

### Index Architecture

The design registry is split hierarchically:

1.  **[`design/index.yaml`](file:///home/tdimiduk/cardpg/design/index.yaml)**: The root index containing game system rules, guidelines, philosophies, VTT registries, and pointers to sub-indexes.
2.  **[`design/iteration/index.yaml`](file:///home/tdimiduk/cardpg/design/iteration/index.yaml)**: The sub-index for active design explorations, mechanical constraints, proposals, and ideation sketches.
3.  **[`design/research/index.yaml`](file:///home/tdimiduk/cardpg/design/research/index.yaml)**: The sub-index mapping empirical research reports, verisimilitude sources, and research syntheses.
4.  **[`design/archive/index.yaml`](file:///home/tdimiduk/cardpg/design/archive/index.yaml)**: The sub-index preserving archived playtest content, legacy spreadsheets, and superseded research.

The audit script recursively parses the root index and all declared sub-indexes.

---

---

### 1. Automated Sync (`--fix`)

The easiest way to synchronize unindexed markdown files and scaffold missing epistemic frontmatter is using the `--fix` flag:

```bash
python3 tools/audit_index.py --fix
```

This command will:

1. Detect unindexed `.md` files in `design/`.
2. Scaffold valid epistemic frontmatter (title, doc_type, track, origin, epistemic_status) if missing.
3. Automatically derive the document's ID, purpose, and canonical tags.
4. Insert the entry into the appropriate sub-index (`research/index.yaml`, `iteration/index.yaml`, or `index.yaml`).
5. Re-run the audit to verify that all constraints and schema alignments pass.

---

### 2. Manual Audit

To inspect the index without making automated changes:

```bash
python3 tools/audit_index.py
```

Options:

- `--strict`: Treats missing epistemic frontmatter in required directories as fatal errors.
- `--fix`: Automatically scaffolds frontmatter and auto-registers unindexed documents.

Discrepancies are reported under:

- `[MISSING]`: Files registered in the index that do not exist on disk.
- `[UNINDEXED]`: Files present in `design/` not yet registered in an index.
- `[SCHEMA ERRORS]`: Violations of epistemic frontmatter schema.
- `[ALIGNMENT ERRORS]`: Frontmatter title or doc_type mismatches with the index entry.
- `[DEAD LINKS]`: Broken file references in `related_files`.

---

### 3. Fixing Broken Paths (MISSING)

For each file reported as `[MISSING]`:

1. Verify if the file was moved or renamed.
   - **Action:** Update the corresponding `path` value in [`design/index.yaml`](file:///home/tdimiduk/cardpg/design/index.yaml) or the appropriate sub-index.
2. If the file was intentionally deleted:
   - **Action:** Move its entry to the `archive` section in the index, or remove it entirely.

---

### 4. Manual Index Registration (Optional Fine-Tuning)

If you prefer to manually craft an entry or place it in a specialized section:

1. Add the entry to [`design/index.yaml`](file:///home/tdimiduk/cardpg/design/index.yaml) or the relevant sub-index.
2. Required fields:
   - `name`: Descriptive, human-readable title (must match frontmatter `title`).
   - `id`: Unique URL-friendly slug (kebab-case).
   - `path`: Relative path from the `design/` root directory.
   - `purpose`: One-sentence explanation of the document's design role.
   - `tags`: Category labels (e.g., `doc-type:research-synthesis`, `audience:designer-facing`).

---

### 5. Git Pre-Commit Hook

Index integrity is automatically enforced prior to every commit via `git-hooks.nix`.
When any file under `design/` is modified or staged:

- The pre-commit hook runs `tools/audit_index.py`.
- Any unindexed files, broken links, or frontmatter schema violations will block the commit.
- You can also trigger this verification manually anytime alongside code formatting via:
  ```bash
  ./scripts/format
  ```
