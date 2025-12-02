#!/usr/bin/env python3

import os
import sys
import subprocess
import yaml
from pathlib import Path

# Paths
# We assume this script is run from the tools directory or we can resolve relative to it.
# If run as `uv run run_pipeline.py` from `tools/`, __file__ is `run_pipeline.py` (or absolute).
SCRIPT_DIR = Path(__file__).resolve().parent
ROOT_DIR = SCRIPT_DIR.parent
MANIFEST_PATH = ROOT_DIR / "design/manifest.yaml"
DATA_DIR = ROOT_DIR / "data/cards"
RAW_DIR = DATA_DIR / "raw"
PC_DIR = DATA_DIR / "pc"
MONSTER_DIR = DATA_DIR / "monsters"
SYNC_SCRIPT = SCRIPT_DIR / "gsheet_sync/sync-cards-gsheet.py"
COMPILER_DIR = SCRIPT_DIR / "card-compiler"

def load_manifest():
    with open(MANIFEST_PATH, 'r') as f:
        return yaml.safe_load(f)

def run_sync():
    print("Syncing data from Google Sheets...")
    # Ensure raw directory exists
    RAW_DIR.mkdir(parents=True, exist_ok=True)
    
    # Run sync script using the current python interpreter (assuming uv run set it up)
    cmd = [sys.executable, str(SYNC_SCRIPT), "--all", "true"]
    subprocess.check_call(cmd)

def run_compiler(json_file, output_dir, tag=None):
    print(f"Compiling {json_file.name} to {output_dir}...")
    output_dir.mkdir(parents=True, exist_ok=True)
    
    # Run using cabal run from the compiler directory
    # We need to pass absolute paths for input and output because we change cwd
    cmd = ["cabal", "run", "card-compiler", "--", str(json_file.resolve()), str(output_dir.resolve())]
    if tag:
        cmd.append(tag)
    
    subprocess.check_call(cmd, cwd=COMPILER_DIR)

import argparse

# ... imports ...

def main():
    parser = argparse.ArgumentParser(description="Run the CardPG data pipeline.")
    parser.add_argument("--sync", action="store_true", help="Sync data from Google Sheets.")
    parser.add_argument("--skip-sync", action="store_true", help="[DEPRECATED] Skip syncing data from Google Sheets (now the default).")
    args = parser.parse_args()

    # 1. Sync
    if args.skip_sync:
        print("Warning: --skip-sync is deprecated. Syncing is now disabled by default. Use --sync to enable it.")

    if args.sync:
        run_sync()
    else:
        print("Skipping sync step (use --sync to enable)...")
    
    # 2. Compile
    manifest = load_manifest()
    
    # Find all Cards entries
    entries = []
    for category in manifest.values():
        if isinstance(category, list):
            entries.extend([item for item in category if item.get('type') == 'Cards'])
        elif isinstance(category, dict):
            for subcategory in category.values():
                if isinstance(subcategory, list):
                    entries.extend([item for item in subcategory if item.get('type') == 'Cards'])
    
    generated_yamls = []
    for entry in entries:
        json_filename = entry['id'] + ".json"
        json_path = RAW_DIR / json_filename
        
        if not json_path.exists():
            print(f"Warning: Expected JSON file {json_path} not found. Skipping compilation for {entry['name']}.")
            continue
        
        tags = entry.get('tags', [])
        if "type:pc-deck" in tags:
            run_compiler(json_path, PC_DIR, "pc")
            # Assume output filename based on entry id or name? 
            # The compiler uses the actor name from the JSON.
            # We can find the generated YAMLs by listing the directory later.
        elif "type:monster-deck" in tags:
            run_compiler(json_path, MONSTER_DIR, "monster")
        else:
            print(f"Skipping compilation for {entry['name']} (no type:pc-deck or type:monster-deck tag).")

    # 3. Export VTT JSON
    print("Exporting VTT JSON...")
    vtt_output = ROOT_DIR / "vtt-react/src/data/generated_cards.json"
    
    # Collect all YAML files from PC and Monster directories
    yaml_files = list(PC_DIR.glob("*.yaml")) + list(MONSTER_DIR.glob("*.yaml"))
    
    if yaml_files:
        cmd = ["cabal", "run", "card-compiler", "--", "export-vtt", str(vtt_output)] + [str(f) for f in yaml_files]
        subprocess.check_call(cmd, cwd=COMPILER_DIR)
    else:
        print("No YAML files found to export.")

if __name__ == "__main__":
    main()
