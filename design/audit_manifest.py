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
    root_dir = os.getcwd()
    manifest_path = os.path.join(root_dir, 'manifest.yaml')
    
    if not os.path.exists(manifest_path):
        print("Error: manifest.yaml not found")
        return

    try:
        manifest_data = load_manifest(manifest_path)
    except Exception as e:
        print(f"Error parsing manifest.yaml: {e}")
        return

    manifest_files = get_manifest_files(manifest_data)
    repo_files = get_repo_files(root_dir)

    # Find discrepancies
    missing_from_repo = manifest_files - repo_files
    unindexed_in_repo = repo_files - manifest_files

    print("--- Audit Results ---")
    
    if missing_from_repo:
        print(f"\n[MISSING] Files in manifest but not found in repo ({len(missing_from_repo)}):")
        for f in sorted(missing_from_repo):
            print(f"  - {f}")
    else:
        print("\n[OK] All manifest files exist in repo.")

    if unindexed_in_repo:
        print(f"\n[UNINDEXED] Files in repo but not in manifest ({len(unindexed_in_repo)}):")
        for f in sorted(unindexed_in_repo):
            print(f"  - {f}")
    else:
        print("\n[OK] All repo files are indexed in manifest.")

if __name__ == "__main__":
    main()
