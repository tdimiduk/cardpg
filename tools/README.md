# Tools

This directory contains various utility scripts and tools for development, database initialization, game design, and syncing card data.

## Scripts & Tools

### Google Sheets Sync (`gsheet_sync/`)

- **`gsheet_sync/sync-cards-gsheet.py`**: Fetches raw card data from Google Sheets and saves it as JSON definitions in `data/cards/raw/`.
- **Usage**:
  ```bash
  uv run gsheet_sync/sync-cards-gsheet.py --all
  ```

### Haskell Design Tools (`tools-hs/`)

- **`keyword-mod`**: Compiles the keyword glossary into `export/glossary.json`, standardizes and normalizes game keywords into `[[Wikilinks]]`, and supports renaming terms across design documentation.
  ```bash
  cabal run tools-hs:exe:keyword-mod -- export-glossary
  cabal run tools-hs:exe:keyword-mod -- normalize-all [--dry-run]
  cabal run tools-hs:exe:keyword-mod -- normalize <term> [--dry-run]
  cabal run tools-hs:exe:keyword-mod -- rename <old> <new> [--dry-run]
  ```
- **`audit-consequences`**: Audits and verifies consequence taxonomy, tags, and decade-density summary tables.
  ```bash
  cabal run tools-hs:exe:audit-consequences
  ```
- **`audit-index`**: Audits and verifies design index consistency, epistemic frontmatter schema, metadata alignment, and README tables of contents.
  ```bash
  cabal run tools-hs:exe:audit-index [--strict] [--fix]
  ```

### Design Utils (`design_utils/`)

- **`design_utils/scripts/card_stats_summary.py`**: Generates statistical summaries of card distributions and balance metrics.
- **`design_utils/scripts/build_vtt_data.py`**: Compiles card definitions for VTT integration.

### Database Utilities (`db_utils/`)

- **`db_utils/init-db.sh`**: A quick script to initialize or reset the local database.

### Standalone Utilities

- **`svg_sword_generator.py`**: Generates SVG crossed sword icons (modeled after Oakeshott XVII). Originally used for VTT favicon generation.
- **`sync-design-mirror.sh`**: Safely syncs changes from the `design/` and `data/` directories to a shadow repository (`tdimiduk/cardpg-design`).

## Setup

Ensure you have the required development dependencies installed via the Python development shell:

```bash
nix develop
# or inside the tools folder:
nix-shell shell.nix
```
