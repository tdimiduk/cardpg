# Tools

This directory contains various utility scripts and tools for the CardPG project.

## Scripts

### `run_pipeline.py`

The master orchestration script for the data pipeline.

- **Usage**: `uv run tools/run_pipeline.py [--skip-sync]` (in `tools` directory)
- **Function**: Syncs data from Google Sheets and compiles it into YAML files in `data/cards/`. Use `--skip-sync` to skip the Google Sheets fetch step.

### `gsheet_sync/sync-cards-gsheet.py`

Fetches card data from Google Sheets.

- **Usage**: `uv run gsheet_sync/gsheet_sync/sync-cards-gsheet.py --all` (in `tools` directory)
- **Output**: JSON files in `data/cards/raw/`.

### `hs-card-compiler`

Haskell tool to convert JSON card definitions to YAML.

- **Usage**: `cabal run hs-card-compiler <input.json> <output_dir>` (in `tools/hs-card-compiler` directory)

## Setup

Ensure you have the required dependencies installed (see root `shell.nix` or `pyproject.toml`).
