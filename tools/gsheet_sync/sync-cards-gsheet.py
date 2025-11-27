#!/usr/bin/env python3

import json
import sys
import os
import re
import yaml
import gspread
from pathlib import Path
import clifun


MANIFEST_PATH = Path(__file__).parents[2] / "design/manifest.yaml"

def load_manifest():
    with open(MANIFEST_PATH, 'r') as f:
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
    
    records = []
    for row in rows[1:]:
        record = {}
        for i in valid_indices:
            if i < len(row):
                val = row[i]
                record[headers[i]] = numericise(val)
        records.append(record)
    return records

def main(key: str, sheet_name: str | None = None):
    target_id = key
    
    manifest = load_manifest()
    
    # Try to find target_id in manifest
    manifest_entry = None
    
    # Search in all lists in manifest
    for category in manifest.values():
        if isinstance(category, list):
            for item in category:
                if item.get('id') == target_id:
                    manifest_entry = item
                    break
        elif isinstance(category, dict):
             for subcategory in category.values():
                if isinstance(subcategory, list):
                    for item in subcategory:
                        if item.get('id') == target_id:
                            manifest_entry = item
                            break
        if manifest_entry:
            break

    gc = gspread.service_account()

    if manifest_entry:
        spreadsheet_key = get_spreadsheet_key_from_url(manifest_entry['path'])
        spreadsheet = gc.open_by_key(spreadsheet_key)
        
        if sheet_name:
            # Dump specific sheet
            worksheet = spreadsheet.worksheet(sheet_name)
            data = safe_get_all_records(worksheet)
            print(json.dumps(data))
        elif 'sheets' in manifest_entry:
            # Dump all sheets defined in manifest
            result = {}
            for sheet_info in manifest_entry['sheets']:
                s_name = sheet_info['name']
                try:
                    worksheet = spreadsheet.worksheet(s_name)
                    result[s_name] = safe_get_all_records(worksheet)
                except gspread.exceptions.WorksheetNotFound:
                    print(f"Warning: Worksheet '{s_name}' not found in spreadsheet.", file=sys.stderr)
            print(json.dumps(result))
        else:
            # Default to first sheet
            worksheet = spreadsheet.get_worksheet(0)
            data = safe_get_all_records(worksheet)
            print(json.dumps(data))
            
    else:
        # Assume target_id is a raw key
        spreadsheet = gc.open_by_key(target_id)
        if sheet_name:
            worksheet = spreadsheet.worksheet(sheet_name)
        else:
            worksheet = spreadsheet.get_worksheet(0)
        
        data = safe_get_all_records(worksheet)
        print(json.dumps(data))

if __name__ == "__main__":
    clifun.call(main)
