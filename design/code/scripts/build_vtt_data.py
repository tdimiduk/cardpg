#!/usr/bin/env python3
# code/scripts/build_vtt_data.py
# Purpose: Transmutes the YAML data source of truth into JSON artifacts for VTT ingestion.
#          Now includes a transformation layer to strip design-only metadata.

import json
import sys
from pathlib import Path
from typing import Any, List, Dict

import yaml
import clifun

# Locate Project Root relative to this script
PROJECT_ROOT = Path(__file__).resolve().parents[2]
DATA_DIR = PROJECT_ROOT / "data" / "cards"
EXPORT_DIR = PROJECT_ROOT / "export" / "vtt"

def load_yaml(path: Path) -> List[Dict[str, Any]]:
    """Safely loads a YAML file, ensuring it returns a list of dicts."""
    if not path.exists():
        print(f"Error: Source file not found at {path}", file=sys.stderr)
        sys.exit(1)
    
    with open(path, "r", encoding="utf-8") as f:
        try:
            data = yaml.safe_load(f)
            if data is None:
                return []
            if not isinstance(data, list):
                print(f"Warning: Expected list root in {path}, found {type(data)}", file=sys.stderr)
                return [data]
            return data
        except yaml.YAMLError as e:
            print(f"Error parsing YAML {path}: {e}", file=sys.stderr)
            sys.exit(1)

def clean_card_data(cards: List[Dict[str, Any]]) -> List[Dict[str, Any]]:
    """
    Filters out design-only fields to keep the VTT payload lightweight.
    Removes: type, tags, notes
    """
    # Fields irrelevant to the VTT runtime
    EXCLUDED_KEYS = {"type", "tags", "notes"}
    
    cleaned_cards = []
    for card in cards:
        # Create a new dict with only the keys NOT in the exclude set
        cleaned_card = {k: v for k, v in card.items() if k not in EXCLUDED_KEYS}
        cleaned_cards.append(cleaned_card)
    
    return cleaned_cards

def save_json(data: Any, path: Path) -> None:
    """Saves data structure to JSON, creating parent directories if needed."""
    path.parent.mkdir(parents=True, exist_ok=True)
    
    with open(path, "w", encoding="utf-8") as f:
        json.dump(data, f, indent=2, ensure_ascii=False)
    print(f"Generated: {path.relative_to(PROJECT_ROOT)}")

def build_consequences() -> None:
    """Pipeline step for Consequence cards."""
    source_file = DATA_DIR / "consequences" / "baseline.yaml"
    target_file = EXPORT_DIR / "consequences_baseline.json"
    
    print(f"Processing {source_file.relative_to(PROJECT_ROOT)}...")
    
    raw_data = load_yaml(source_file)
    
    # Transformation Layer
    vtt_data = clean_card_data(raw_data)
    
    save_json(vtt_data, target_file)

def main() -> None:
    """Entry point for the VTT Data Build Pipeline."""
    print(f"--- VTT Data Export ---")
    print(f"Root: {PROJECT_ROOT}")
    
    build_consequences()
    
    print("--- Export Complete ---")

if __name__ == "__main__":
    clifun.call(main)
