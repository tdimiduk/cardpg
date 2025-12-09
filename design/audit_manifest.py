#!/usr/bin/env python3
import yaml
import os
from pathlib import Path

def load_manifest(manifest_path):
    with open(manifest_path, 'r') as f:
        return yaml.safe_load(f)

def get_manifest_files(manifest_data):
    files = set()
    
    def extract_paths(data):
        if isinstance(data, dict):
            if 'path' in data:
                # Normalize path separators
                p = Path(data['path'])
                # We only care about local files for this audit
                if 'source_type' not in data or data['source_type'] == 'local_file':
                     files.add(str(p).replace('\\', '/'))
            
            if 'components' in data and isinstance(data['components'], dict):
                for comp_key, comp_path in data['components'].items():
                    if isinstance(comp_path, str):
                         files.add(str(Path(comp_path)).replace('\\', '/'))

            for key, value in data.items():
                extract_paths(value)
        elif isinstance(data, list):
            for item in data:
                extract_paths(item)

    extract_paths(manifest_data)
    return files

def get_repo_files(root_dir):
    files = set()
    skip_dirs = {'.git', '.gemini', 'node_modules', '__pycache__'}
    
    for root, dirs, filenames in os.walk(root_dir):
        # Modify dirs in-place to skip ignored directories
        dirs[:] = [d for d in dirs if d not in skip_dirs]
        
        for filename in filenames:
            if filename == 'manifest.yaml': # Skip the manifest itself
                continue
            
            full_path = os.path.join(root, filename)
            rel_path = os.path.relpath(full_path, root_dir)
            files.add(rel_path.replace('\\', '/'))
            
    return files

def main():
    # Use script location as the anchor
    script_dir = os.path.dirname(os.path.abspath(__file__))
    root_dir = script_dir  # We want to scan the design directory (where the script is)
    
    manifest_path = os.path.join(root_dir, 'manifest.yaml')
    
    if not os.path.exists(manifest_path):
        print(f"Error: manifest.yaml not found at {manifest_path}")
        return

    try:
        manifest_data = load_manifest(manifest_path)
    except Exception as e:
        print(f"Error parsing manifest.yaml: {e}")
        return

    manifest_files = get_manifest_files(manifest_data)
    repo_files = get_repo_files(root_dir)

    # 1. Check for Missing Files (In Manifest, Not on Disk)
    missing_from_disk = set()
    for file_path in manifest_files:
        # manifest paths are relative to design/ (root_dir)
        # They might contain ../ to go up a level
        full_path = os.path.join(root_dir, file_path)
        if not os.path.exists(full_path):
            missing_from_disk.add(file_path)

    # 2. Check for Unindexed Files (In Design Dir, Not in Manifest)
    # We only care about unindexed files inside the design directory itself
    # So we filter manifest_files to only those starting with neither / nor ..
    manifest_files_in_design = {f for f in manifest_files if not f.startswith('..') and not os.path.isabs(f)}
    unindexed_in_repo = repo_files - manifest_files_in_design

    print("--- Audit Results ---")
    
    if missing_from_disk:
        print(f"\n[MISSING] Files in manifest but not found on disk ({len(missing_from_disk)}):")
        for f in sorted(missing_from_disk):
            print(f"  - {f}")
    else:
        print("\n[OK] All manifest files found on disk.")

    if unindexed_in_repo:
        print(f"\n[UNINDEXED] Files in design/ but not in manifest ({len(unindexed_in_repo)}):")
        for f in sorted(unindexed_in_repo):
            print(f"  - {f}")
    else:
        print("\n[OK] All design/ files are indexed in manifest.")

if __name__ == "__main__":
    main()
