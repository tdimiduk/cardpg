---
description: Update the design manifest to match the filesystem.
---

1.  **Audit the State**
    Run the audit script to identify discrepancies:
    ```bash
    ./design/audit_manifest.py
    ```

2.  **Fix Broken Paths (MISSING)**
    - For each file listed as `[MISSING]`:
    - Check if it was moved or renamed.
    - **Action:** Update the `path` in `design/manifest.yaml` to the new location.
    - If the file was deleted, move its entry to an `archive` section or remove it.

3.  **Index New Content (UNINDEXED)**
    - For each file listed as `[UNINDEXED]`:
    - **Action:** Add a new entry to `design/manifest.yaml` under the appropriate section.
    - **Required Fields:**
        - `name`: Human readable title.
        - `id`: Unique identifier (kebab-case).
        - `path`: Relative path from `design/`.
        - `status`: usually "Leading-Edge" or "Canon".
        - `purpose`: Brief description of what this doc is for.
        - `tags`: Add relevant tags (e.g., `pillar:combat`, `core-concept:armor`).

4.  **Verify**
    - Run `./design/audit_manifest.py` again to ensure a clean state.
