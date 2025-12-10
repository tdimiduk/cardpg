#!/usr/bin/env python3
import yaml
import os
import argparse
from pathlib import Path

def load_manifest(manifest_path):
    with open(manifest_path, 'r') as f:
        return yaml.safe_load(f)

def resolve_path(root_dir, rel_path):
    # Handle paths relative to the design directory
    return os.path.join(root_dir, 'design', rel_path)

def get_file_content(path):
    try:
        with open(path, 'r') as f:
            return f.read()
    except Exception as e:
        return f"[Error reading {path}: {e}]"

def filter_manifest(manifest_data, tags=None, query=None):
    selected_files = []
    
    def check_item(item):
        if not isinstance(item, dict):
            return
        
        # Check matching logic
        match = False
        if tags:
            item_tags = item.get('tags', [])
            # If any requested tag is in the item's tags
            if any(t in item_tags for t in tags):
                match = True
        
        if query:
            q = query.lower()
            if (q in item.get('name', '').lower() or 
                q in item.get('purpose', '').lower() or
                q in item.get('id', '').lower()):
                match = True
        
        # If no filters provided, default to NO MATCH (don't dump everything unless asked)
        if not tags and not query:
            match = False

        if match:
            # Add primary file
            if 'path' in item and item.get('source_type') == 'local_file':
                selected_files.append({
                    'path': item['path'],
                    'description': f"{item.get('name')} ({item.get('type')})"
                })
            
            # Add component files
            if 'components' in item and isinstance(item['components'], dict):
                # Only include the report file, ignore meta and prompt to save context
                if 'report_file' in item['components']:
                     selected_files.append({
                        'path': item['components']['report_file'],
                        'description': f"{item.get('name')} - Report"
                    })

        # Recurse
        for key, value in item.items():
            if isinstance(value, list):
                for sub_item in value:
                    check_item(sub_item)
            elif isinstance(value, dict):
                check_item(value)

    check_item(manifest_data)
    return selected_files

def main():
    parser = argparse.ArgumentParser(description='Pack design context for AI.')
    parser.add_argument('--tag', action='append', help='Filter by tag (can be used multiple times)')
    parser.add_argument('--file', action='append', help='Explicitly include a file (relative to design/ root).')
    parser.add_argument('--root', default='.', help='Root directory of the project (default: current dir).')
    parser.add_argument('--query', help='Filter content by search query.')
    
    args = parser.parse_args()
    
    root_dir = args.root
    # If we are running from root, design is in ./design
    # The manifest paths are relative to design/ usually, or we need to check audit_manifest.py logic
    # audit_manifest says: p = Path(data['path']) ... os.path.join(root, filename)
    # Let's assume paths in manifest are relative to `design/` if they don't start with ../
    
    manifest_path = os.path.join(root_dir, 'design', 'manifest.yaml')
    if not os.path.exists(manifest_path):
        # Try assuming we might be inside design dir?
        if os.path.exists('manifest.yaml'):
             root_dir = os.path.dirname(os.getcwd())
             manifest_path = 'manifest.yaml'
        else:
             print(f"Error: manifest.yaml not found at {manifest_path}")
             return

    manifest_data = load_manifest(manifest_path)
    
    # 1. Load Persona (Always Artificer)
    persona_path = os.path.join(root_dir, 'design/ai/personas/artificer.md')
    
    print("<SYSTEM_PROMPT>")
    print(get_file_content(persona_path))
    print("</SYSTEM_PROMPT>\n")
    
    # 2. Filter Content
    selected = []

    # 2a. Add Always-Included Context
    always_include = [
        {'path': 'rules/core-rules.md', 'description': 'Key Reference: Core Rules'},
        {'path': 'rules/players-guide.md', 'description': 'Key Reference: Player\'s Guide'},
        {'path': 'rules/keyword-glossary.md', 'description': 'Key Reference: Keyword Glossary'},
        {'path': 'philosophy/guiding-principles.md', 'description': 'Key Reference: Guiding Principles'}
    ]
    selected.extend(always_include)


    # 2b. Add Filtered Manifest Content
    selected.extend(filter_manifest(manifest_data, tags=args.tag, query=args.query))

    # 3. Add Explicit Files
    if args.file:
        for f in args.file:
            selected.append({
                'path': f,
                'description': os.path.basename(f)
            })
    
    # Resolve paths and Deduplicate
    final_items = []
    seen_paths = set()
    
    for item in selected:
        # Resolve path logic
        # 1. Try relative to design/ (standard manifest behavior)
        candidate_design = os.path.join(root_dir, 'design', item['path'])
        # 2. Try relative to project root (user arg behavior)
        candidate_root = os.path.join(root_dir, item['path'])
        
        full_path = candidate_design
        if os.path.exists(candidate_design):
            full_path = candidate_design
        elif os.path.exists(candidate_root):
            full_path = candidate_root
        
        # Get canonical absolute path for deduplication
        abs_path = os.path.abspath(full_path)
        
        # Exclude Artificer persona from manifest (it's in SYSTEM_PROMPT)
        if 'artificer.md' in abs_path:
             continue

        if abs_path not in seen_paths:
            seen_paths.add(abs_path)
            # Store the resolved full path
            item['full_path'] = full_path
            
            # Normalize display path: strip 'design/' if present at start
            # This makes paths relative to the design root which is cleaner
            display_path = item['path']
            if display_path.startswith('design/'):
                display_path = display_path[7:]
            elif display_path.startswith('./design/'):
                 display_path = display_path[9:]
            
            item['display_path'] = display_path
            final_items.append(item)
    
    print("<CONTEXT_MANIFEST>")
    for item in final_items:
        print(f"- {item['description']}: {item['display_path']}")
    print("</CONTEXT_MANIFEST>\n")
    
    print("<CONTEXT_CONTENT>")
    for item in final_items:
        print(f"## File: {item['display_path']}")
        print(get_file_content(item['full_path']))
        print("\n" + "="*40 + "\n")
    print("</CONTEXT_CONTENT>")

if __name__ == "__main__":
    main()
