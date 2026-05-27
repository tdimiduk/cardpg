# Design Manifest Maintenance Guide

This document outlines the step-by-step instructions to synchronize the systems design registry (`design/manifest.yaml`) with the physical files in your filesystem.

---

### 1. Audit the State

Run the manifest audit script from the root of the project to identify files that are out of sync:

```bash
./design/audit_manifest.py
```

This script will report discrepancies under two main categories:

- `[MISSING]`: Files registered in the manifest that do not exist at the specified path.
- `[UNINDEXED]`: Files present in the filesystem under `design/` that have not yet been registered.

---

### 2. Fix Broken Paths (MISSING)

For each file reported as `[MISSING]`:

1.  Verify if the file was moved or renamed.
    - **Action:** Update the corresponding `path` value under its entry in [`design/manifest.yaml`](file:///home/tdimiduk/cardpg/cardpg/design/manifest.yaml).
2.  If the file was intentionally deleted:
    - **Action:** Move its entry to the `archive` section in the manifest, or remove it entirely.

---

### 3. Index New Content (UNINDEXED)

For each file reported as `[UNINDEXED]`:

1.  **Action:** Create a new entry in [`design/manifest.yaml`](file:///home/tdimiduk/cardpg/cardpg/design/manifest.yaml) under the appropriate section.
2.  Fill in the **Required Fields**:
    - `name`: A descriptive, human-readable title.
    - `id`: A unique, URL-friendly slug (kebab-case).
    - `path`: The relative path from the `design/` root directory.
    - `status`: Current lifecycle phase of the design document (typically `"Leading-Edge"` or `"Canon"`).
    - `purpose`: A brief, one-sentence explanation of the document's design role.
    - `tags`: Category labels for quick filtering (e.g., `pillar:combat`, `core-concept:armor`).

---

### 4. Verify

After making changes, run the audit script once more to confirm a clean state:

```bash
./design/audit_manifest.py
```

You should see no missing or unindexed file alerts in the terminal output.
