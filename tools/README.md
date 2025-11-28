# CardPG Tools

This directory contains various utility scripts and tools for the CardPG project.

## Python Tools

We use `uv` to manage Python dependencies and environments.

### Usage

To run a script, use `uv run` from the `tools` directory:

```bash
cd tools
uv run gsheet_sync/sync-cards-gsheet.py --key <MANIFEST_ID_OR_URL> [--sheet_name <SHEET_NAME>]
```

**Note:** The argument is `--sheet_name` (with an underscore), not `--sheet-name`.

### Scripts

- **`gsheet_sync/sync-cards-gsheet.py`**: Fetches card data from Google Sheets.
  - `--key`: The ID from `design/manifest.yaml` (e.g., `gdoc-cards-v004`) or a full Google Sheet URL.
  - `--sheet_name`: (Optional) The specific tab name to fetch. If omitted, dumps all sheets defined in the manifest or the first sheet.

## Haskell Tools

- **`hs-card-compiler`**: A Haskell-based tool to compile JSON card definitions (from `gsheet_sync`) into YAML files for the game engine.
  - Located in `hs-card-compiler/`.
  - Run with `cabal run hs-card-compiler -- <input.json> <output_dir>`.
