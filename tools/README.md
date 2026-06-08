# Tools

This directory contains various utility scripts and tools for development, database initialization, game design, and syncing card data.

## Scripts & Tools

### Google Sheets Sync (`gsheet_sync/`)

- **`gsheet_sync/sync-cards-gsheet.py`**: Fetches raw card data from Google Sheets and saves it as JSON definitions in `data/cards/raw/`.
- **Usage**:
  ```bash
  uv run gsheet_sync/sync-cards-gsheet.py --all
  ```

### Design Utils (`design_utils/`)

- **`design_utils/scripts/build_vtt_data.py`**: Exports the YAML card data source of truth into cleaned JSON artifacts for VTT ingestion (stripping design-only fields like metadata).
- **`design_utils/keywordMod.py`** & **`design_utils/scripts/keyword_mod.py`**: Helper scripts to perform bulk keyword/action modifications across YAML card files.

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
