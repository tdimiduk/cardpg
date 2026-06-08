#!/usr/bin/env python3

import json
import sys
import os
import re
import yaml
import gspread
from pathlib import Path
import argparse


INDEX_PATH = Path(__file__).parents[2] / "design/index.yaml"

def load_index():
    with open(INDEX_PATH, 'r') as f:
        return yaml.safe_load(f)

def get_spreadsheet_key_from_url(url):
    # Extract key from URL like https://docs.google.com/spreadsheets/d/KEY/edit...
    match = re.search(r"/d/([a-zA-Z0-9-_]+)", url)
    if match:
        return match.group(1)
    return url # Assume it's already a key if no match

def numericise(value):
    if isinstance(value, str):
        try:
            return int(value)
        except ValueError:
            try:
                return float(value)
            except ValueError:
                return value
    return value

def safe_get_all_records(worksheet):
    # gspread's get_all_records fails if there are duplicate or empty headers.
    # We implement a robust version that ignores columns with empty headers.
    rows = worksheet.get_all_values()
    if not rows:
        return []
    
    headers = rows[0]
    valid_indices = [i for i, h in enumerate(headers) if h.strip()]
    
    # Fields that should always be treated as strings
    text_fields = {
        'actor', 'name', 'action', 'effect', 'details', 
        'keywordProvide', 'flavor', 'tags', 'type', 'status',
        'keywordCost'
    }

    records = []
    for row in rows[1:]:
        record = {}
        for i in valid_indices:
            if i < len(row):
                val = row[i]
                header = headers[i]
                if header in text_fields:
                    record[header] = val
                else:
                    record[header] = numericise(val)
        records.append(record)
    return records

def dump_index_entry(index_entry, output_dir=None):
    gc = gspread.service_account()
    spreadsheet_key = get_spreadsheet_key_from_url(index_entry['path'])
    try:
        spreadsheet = gc.open_by_key(spreadsheet_key)
    except (gspread.exceptions.APIError, gspread.exceptions.SpreadsheetNotFound, PermissionError) as e:
        print(f"Error opening spreadsheet {index_entry['name']}: {e}", file=sys.stderr)
        return

    data = None
    if 'sheets' in index_entry:
        # Dump all sheets defined in index
        result = {}
        for sheet_info in index_entry['sheets']:
            s_name = sheet_info['name']
            try:
                worksheet = spreadsheet.worksheet(s_name)
                result[s_name] = safe_get_all_records(worksheet)
            except gspread.exceptions.WorksheetNotFound:
                print(f"Warning: Worksheet '{s_name}' not found in spreadsheet {index_entry['name']}.", file=sys.stderr)
        data = result
    else:
        # Default to first sheet
        worksheet = spreadsheet.get_worksheet(0)
        data = safe_get_all_records(worksheet)
    
    if output_dir:
        filename = index_entry['id'] + ".json"
        output_path = Path(output_dir) / filename
        with open(output_path, 'w') as f:
            json.dump(data, f, indent=2)
        print(f"Wrote {output_path}")
    else:
        print(json.dumps(data))

def main(key: str | None = None, sheet_name: str | None = None, all: bool = False):
    index = load_index()
    
    if all:
        # Hardcoded output directory for batch mode
        output_dir = Path(__file__).parents[2] / "data/cards/raw"
        output_dir.mkdir(parents=True, exist_ok=True)
        
        # Find all entries of type 'Cards'
        entries_to_sync = []
        for category in index.values():
            if isinstance(category, list):
                for item in category:
                    if item.get('type') == 'Cards':
                        entries_to_sync.append(item)
            elif isinstance(category, dict):
                 for subcategory in category.values():
                    if isinstance(subcategory, list):
                        for item in subcategory:
                            if item.get('type') == 'Cards':
                                entries_to_sync.append(item)
        
        print(f"Syncing {len(entries_to_sync)} entries to {output_dir}...")
        for entry in entries_to_sync:
            print(f"Syncing {entry['name']} ({entry['id']})...")
            dump_index_entry(entry, output_dir=output_dir)
            
    elif key:
        target_id = key
        # Try to find target_id in index
        index_entry = None
        
        # Search in all lists in index
        for category in index.values():
            if isinstance(category, list):
                for item in category:
                    if item.get('id') == target_id:
                        index_entry = item
                        break
            elif isinstance(category, dict):
                 for subcategory in category.values():
                    if isinstance(subcategory, list):
                        for item in subcategory:
                            if item.get('id') == target_id:
                                index_entry = item
                                break
            if index_entry:
                break

        if index_entry:
            dump_index_entry(index_entry)
        else:
            # Assume target_id is a raw key
            gc = gspread.service_account()
            spreadsheet = gc.open_by_key(target_id)
            if sheet_name:
                worksheet = spreadsheet.worksheet(sheet_name)
            else:
                worksheet = spreadsheet.get_worksheet(0)
            
            data = safe_get_all_records(worksheet)
            print(json.dumps(data))
    else:
        print("Error: Must specify either --all or a key/id.", file=sys.stderr)

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Sync Google Sheets to JSON")
    parser.add_argument("key", nargs="?", help="GSheet key or Index ID")
    parser.add_argument("--sheet-name", help="Specific sheet name to sync (only used if key is provided directly)")
    parser.add_argument("--all", action="store_true", help="Sync all cards defined in index")

    args = parser.parse_args()
    main(key=args.key, sheet_name=args.sheet_name, all=args.all)
