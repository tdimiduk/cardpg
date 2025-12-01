# Tools

This directory contains various utility scripts and tools for the CardPG project.

## Scripts

### `run_pipeline.py`

The master orchestration script for the data pipeline.

## Usage

Run the full pipeline:

```bash
# Default: skips Google Sheets sync, runs compiler, exports VTT JSON
python3 run_pipeline.py

# With sync enabled:
python3 run_pipeline.py --sync
```

The pipeline performs the following steps:

1.  **Sync (Optional):** Fetches data from Google Sheets and saves it as JSON in `data/cards/raw`. This step is skipped by default and can be enabled with `--sync`.
2.  **Compile:** Converts the raw JSON data into YAML card definitions in `data/cards/pc` and `data/cards/monsters`.
3.  **Export:** Generates `vtt-react/data/generated_cards.json` for the VTT.Sheets.

### `gsheet_sync/sync-cards-gsheet.py`

Fetches card data from Google Sheets.

- **Usage**: `uv run gsheet_sync/gsheet_sync/sync-cards-gsheet.py --all` (in `tools` directory)
- **Output**: JSON files in `data/cards/raw/`.

### `hs-card-compiler`

Haskell tool to convert JSON card definitions to YAML.

- **Usage**: `cabal run hs-card-compiler <input.json> <output_dir>` (in `tools/hs-card-compiler` directory)

## Setup

Ensure you have the required dependencies installed (see root `shell.nix` or `pyproject.toml`).
