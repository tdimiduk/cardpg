#!/usr/bin/env python3
import yaml
import os
from pathlib import Path

def load_index(index_path):
    with open(index_path, 'r') as f:
        return yaml.safe_load(f)

def load_all_index_files(root_dir, index_path, loaded_paths=None):
    if loaded_paths is None:
        loaded_paths = set()
        
    abs_index_path = os.path.abspath(index_path)
    if abs_index_path in loaded_paths:
        return set(), []
    
    loaded_paths.add(abs_index_path)
    
    if not os.path.exists(index_path):
        return set(), [index_path]
    
    try:
        index_data = load_index(index_path)
    except Exception as e:
        print(f"Error parsing index file at {index_path}: {e}")
        return set(), []
    
    files = set()
    sub_indexes_to_load = []
    
    def extract_paths(data):
        if isinstance(data, dict):
            if 'path' in data:
                p = Path(data['path'])
                # We only care about local files for this audit
                if 'source_type' not in data or data['source_type'] == 'local_file':
                     rel_path = str(p).replace('\\', '/')
                     files.add(rel_path)
                     if data.get('type') == 'Index':
                         sub_indexes_to_load.append(rel_path)
            
            if 'components' in data and isinstance(data['components'], dict):
                for comp_key, comp_path in data['components'].items():
                    if isinstance(comp_path, str):
                         files.add(str(Path(comp_path)).replace('\\', '/'))

            for key, value in data.items():
                extract_paths(value)
        elif isinstance(data, list):
            for item in data:
                extract_paths(item)

    extract_paths(index_data)
    
    # Recursively load sub-indexes
    all_files = set(files)
    missing_indexes = []
    for sub_path in sub_indexes_to_load:
        full_sub_path = os.path.join(root_dir, sub_path)
        sub_files, sub_missing = load_all_index_files(root_dir, full_sub_path, loaded_paths)
        all_files.update(sub_files)
        missing_indexes.extend(sub_missing)
        
    return all_files, missing_indexes

def get_repo_files(root_dir):
    files = set()
    skip_dirs = {'.git', '.gemini', 'node_modules', '__pycache__'}
    
    for root, dirs, filenames in os.walk(root_dir):
        # Modify dirs in-place to skip ignored directories
        dirs[:] = [d for d in dirs if d not in skip_dirs]
        
        for filename in filenames:
            if filename == 'index.yaml': # Skip index files
                continue
            
            full_path = os.path.join(root, filename)
            rel_path = os.path.relpath(full_path, root_dir)
            files.add(rel_path.replace('\\', '/'))
            
    return files

def main():
    # Use script location as the anchor
    script_dir = os.path.dirname(os.path.abspath(__file__))
    root_dir = script_dir  # We want to scan the design directory (where the script is)
    
    index_path = os.path.join(root_dir, 'index.yaml')
    
    if not os.path.exists(index_path):
        print(f"Error: index.yaml not found at {index_path}")
        return

    index_files, missing_indexes = load_all_index_files(root_dir, index_path)
    repo_files = get_repo_files(root_dir)

    # 1. Check for Missing Files (In Index, Not on Disk)
    missing_from_disk = set()
    for file_path in index_files:
        # index paths are relative to design/ (root_dir)
        # They might contain ../ to go up a level
        full_path = os.path.join(root_dir, file_path)
        if not os.path.exists(full_path):
            missing_from_disk.add(file_path)
            
    for missing_idx in missing_indexes:
        rel_missing = os.path.relpath(missing_idx, root_dir).replace('\\', '/')
        missing_from_disk.add(rel_missing)

    # 2. Check for Unindexed Files (In Design Dir, Not in Index)
    # We only care about unindexed files inside the design directory itself
    # So we filter index_files to only those starting with neither / nor ..
    index_files_in_design = {f for f in index_files if not f.startswith('..') and not os.path.isabs(f)}
    unindexed_in_repo = repo_files - index_files_in_design

    print("--- Audit Results ---")
    
    if missing_from_disk:
        print(f"\n[MISSING] Files in index but not found on disk ({len(missing_from_disk)}):")
        for f in sorted(missing_from_disk):
            print(f"  - {f}")
    else:
        print("\n[OK] All index files found on disk.")

    if unindexed_in_repo:
        print(f"\n[UNINDEXED] Files in design/ but not in index ({len(unindexed_in_repo)}):")
        for f in sorted(unindexed_in_repo):
            print(f"  - {f}")
    else:
        print("\n[OK] All design/ files are indexed in index.")

if __name__ == "__main__":
    main()
