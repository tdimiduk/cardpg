#!/usr/bin/env python3
"""
tools/audit_index.py

Validates consistency between physical files on disk, index.yaml (and sub-indexes),
and epistemic YAML frontmatter on Markdown documents.

Key checks:
1. Directory consistency:
   - All indexed files exist on disk (no broken file pointers).
   - All design/ files are indexed in index.yaml or its sub-indexes (no orphaned files).
2. Epistemic frontmatter schema validation:
   - Required fields: title, doc_type, track, origin, epistemic_status: { confidence, vetted_by_human }.
   - Valid values for track (verisimilitude, ludology) and confidence (speculative, medium-low, medium, high).
   - Deprecation alert if legacy 'status' is present.
3. Metadata alignment:
   - Frontmatter 'title' matches index 'name'.
   - Frontmatter 'doc_type' matches index 'type' or tags.
4. Dead link detection:
   - All paths declared in 'related_files' exist on disk.
5. Missing frontmatter tracking:
   - Identifies documents in required directories (research/synthesis, research/theory/readings)
     awaiting frontmatter. Use --strict to treat as fatal.
"""

import argparse
import os
import sys
from pathlib import Path
import yaml

FRONTMATTER_REQUIRED_DIRS = [
    "research/synthesis",
    "research/theory/readings",
]

DOC_TYPE_COMPATIBILITY = {
    "synthesis": {
        "research synthesis",
        "synthesis",
        "doc-type:research-synthesis",
        "doc-type:synthesis",
    },
    "literature-note": {
        "literature note",
        "literature-note",
        "doc-type:literature-note",
    },
    "report": {
        "research report",
        "report",
        "doc-type:research-report",
        "doc-type:report",
    },
    "card-database": {
        "card database",
        "cards",
        "doc-type:card-database",
        "doc-type:content-library",
    },
    "meta": {
        "meta document",
        "doc-type:meta",
    },
    "introductory-text": {
        "introductory text",
        "doc-type:introductory-text",
    },
    "rules": {
        "game rules",
        "game rules module",
        "rules",
        "doc-type:rules",
        "doc-type:rules-framework",
        "doc-type:rules-module",
    },
    "iteration": {
        "design constraints",
        "design exploration",
        "design exploration suite",
        "ideation",
        "doc-type:iteration",
        "doc-type:ideation",
    },
}

VALID_TRACKS = {"verisimilitude", "ludology"}
VALID_CONFIDENCE_TIERS = {"speculative", "medium-low", "medium", "high"}

def load_index(index_path):
    with open(index_path, "r", encoding="utf-8") as f:
        return yaml.safe_load(f)

def load_all_index_data(root_dir, index_path, loaded_paths=None, entries_by_path=None):
    if loaded_paths is None:
        loaded_paths = set()
    if entries_by_path is None:
        entries_by_path = {}

    abs_index_path = os.path.abspath(index_path)
    if abs_index_path in loaded_paths:
        return set(), entries_by_path, []

    loaded_paths.add(abs_index_path)

    if not os.path.exists(index_path):
        return set(), entries_by_path, [index_path]

    try:
        index_data = load_index(index_path)
    except Exception as e:
        print(f"Error parsing index file at {index_path}: {e}")
        return set(), entries_by_path, []

    files = set()
    sub_indexes_to_load = []

    def extract_entries(node, parent_entry=None):
        if isinstance(node, dict):
            current_entry = parent_entry
            if "name" in node or "id" in node or "path" in node:
                current_entry = node

            if "path" in node:
                p = Path(node["path"])
                if node.get("source_type", "local_file") == "local_file":
                    rel_path = str(p).replace("\\", "/")
                    files.add(rel_path)
                    entries_by_path[rel_path] = current_entry
                    if node.get("type") == "Index":
                        sub_indexes_to_load.append(rel_path)

            if "components" in node:
                comps = node["components"]
                if isinstance(comps, dict):
                    for comp_key, comp_path in comps.items():
                        if isinstance(comp_path, str):
                            rel_p = str(Path(comp_path)).replace("\\", "/")
                            files.add(rel_p)
                            entries_by_path[rel_p] = current_entry
                elif isinstance(comps, list):
                    for item in comps:
                        extract_entries(item, current_entry)

            for k, v in node.items():
                if k != "components":
                    extract_entries(v, current_entry)
        elif isinstance(node, list):
            for item in node:
                extract_entries(item, parent_entry)

    extract_entries(index_data)

    all_files = set(files)
    missing_indexes = []
    for sub_path in sub_indexes_to_load:
        full_sub_path = os.path.join(root_dir, sub_path)
        sub_files, _, sub_missing = load_all_index_data(
            root_dir, full_sub_path, loaded_paths, entries_by_path
        )
        all_files.update(sub_files)
        missing_indexes.extend(sub_missing)

    return all_files, entries_by_path, missing_indexes

def get_repo_files(root_dir):
    files = set()
    skip_dirs = {".git", ".gemini", "node_modules", "__pycache__"}

    for root, dirs, filenames in os.walk(root_dir):
        dirs[:] = [d for d in dirs if d not in skip_dirs]

        for filename in filenames:
            if filename == "index.yaml":
                continue

            full_path = os.path.join(root, filename)
            rel_path = os.path.relpath(full_path, root_dir)
            files.add(rel_path.replace("\\", "/"))

    return files

def extract_frontmatter(file_path):
    try:
        with open(file_path, "r", encoding="utf-8") as f:
            lines = f.readlines()
    except Exception as e:
        return None, f"Could not read file: {e}"

    if not lines or lines[0].strip() != "---":
        return None, None

    fm_lines = []
    found_end = False
    for line in lines[1:]:
        if line.strip() == "---":
            found_end = True
            break
        fm_lines.append(line)

    if not found_end:
        return None, "Unterminated frontmatter (missing closing ---)"

    try:
        data = yaml.safe_load("".join(fm_lines))
        if not isinstance(data, dict):
            return None, "Frontmatter must parse into a YAML mapping / dictionary"
        return data, None
    except Exception as e:
        return None, f"YAML parse error: {e}"

def validate_frontmatter_schema(fm, rel_path):
    errors = []

    # Required top-level fields
    for field in ["title", "doc_type", "track", "origin", "epistemic_status"]:
        if field not in fm or fm[field] is None:
            errors.append(f"Missing required field: '{field}'")

    title = fm.get("title")
    if title is not None and not str(title).strip():
        errors.append("Field 'title' cannot be empty")

    doc_type = fm.get("doc_type")
    if doc_type is not None and not str(doc_type).strip():
        errors.append("Field 'doc_type' cannot be empty")

    track = fm.get("track")
    if track is not None and track not in VALID_TRACKS:
        errors.append(f"Invalid 'track': '{track}' (must be one of: {sorted(VALID_TRACKS)})")

    origin = fm.get("origin")
    if origin is not None and not str(origin).strip():
        errors.append("Field 'origin' cannot be empty")

    ep_status = fm.get("epistemic_status")
    if ep_status is not None:
        if not isinstance(ep_status, dict):
            errors.append("Field 'epistemic_status' must be a dictionary")
        else:
            if "status" in ep_status:
                errors.append(
                    "Obsolete field 'status' found in 'epistemic_status'. "
                    "The lifecycle status classification has been removed."
                )

            if "confidence" not in ep_status:
                errors.append("Missing required field 'confidence' in 'epistemic_status'")
            elif ep_status["confidence"] not in VALID_CONFIDENCE_TIERS:
                errors.append(
                    f"Invalid 'confidence': '{ep_status['confidence']}' "
                    f"(must be one of: {sorted(VALID_CONFIDENCE_TIERS)})"
                )

            if "vetted_by_human" not in ep_status:
                errors.append("Missing required field 'vetted_by_human' in 'epistemic_status'")
            else:
                v = ep_status["vetted_by_human"]
                if not isinstance(v, bool) and not (isinstance(v, str) and v.strip()):
                    errors.append("'vetted_by_human' must be a boolean or non-empty string identifier")

    related_files = fm.get("related_files")
    if related_files is not None and not isinstance(related_files, list):
        errors.append("'related_files' must be a list of paths")

    return errors

def validate_metadata_alignment(fm, index_entry, rel_path):
    errors = []
    if not index_entry:
        return errors

    fm_title = str(fm.get("title", "")).strip().lower()
    idx_name = str(index_entry.get("name", "")).strip().lower()

    if fm_title and idx_name and fm_title != idx_name:
        errors.append(
            f"Title mismatch: frontmatter '{fm.get('title')}' != index entry name '{index_entry.get('name')}'"
        )

    doc_type = fm.get("doc_type")
    if doc_type:
        dt_str = str(doc_type).strip().lower()
        idx_type = str(index_entry.get("type", "")).strip().lower()
        idx_tags = [str(t).strip().lower() for t in index_entry.get("tags", [])]

        allowed_matchers = DOC_TYPE_COMPATIBILITY.get(dt_str, {dt_str})
        matched = False
        if idx_type in allowed_matchers:
            matched = True
        else:
            for tag in idx_tags:
                if tag in allowed_matchers:
                    matched = True
                    break

        if not matched:
            errors.append(
                f"Document type mismatch: frontmatter doc_type '{doc_type}' does not align with "
                f"index type '{index_entry.get('type')}' or tags '{index_entry.get('tags')}'"
            )

    return errors

def validate_related_files(fm, repo_root, design_root, abs_file_path):
    errors = []
    related_files = fm.get("related_files")
    if not related_files or not isinstance(related_files, list):
        return errors

    for rel_link in related_files:
        if not isinstance(rel_link, str):
            continue

        candidates = [
            os.path.join(repo_root, rel_link),
            os.path.join(design_root, rel_link),
            os.path.join(os.path.dirname(abs_file_path), rel_link),
        ]

        if not any(os.path.exists(c) for c in candidates):
            errors.append(f"Dead link in related_files: '{rel_link}' not found on disk")

    return errors

def main():
    parser = argparse.ArgumentParser(
        description="Audit CardPG design index synchronization and frontmatter validation."
    )
    parser.add_argument(
        "--strict",
        action="store_true",
        help="Treat missing frontmatter in required directories as a fatal error.",
    )
    args = parser.parse_args()

    script_dir = os.path.dirname(os.path.abspath(__file__))
    repo_root = os.path.abspath(os.path.join(script_dir, ".."))
    design_root = os.path.join(repo_root, "design")

    index_path = os.path.join(design_root, "index.yaml")

    if not os.path.exists(index_path):
        print(f"Error: index.yaml not found at {index_path}")
        sys.exit(1)

    index_files, entries_by_path, missing_indexes = load_all_index_data(design_root, index_path)
    repo_files = get_repo_files(design_root)

    # 1. Directory Consistency
    missing_from_disk = set()
    for file_path in index_files:
        full_path = os.path.join(design_root, file_path)
        if not os.path.exists(full_path):
            missing_from_disk.add(file_path)

    for missing_idx in missing_indexes:
        rel_missing = os.path.relpath(missing_idx, design_root).replace("\\", "/")
        missing_from_disk.add(rel_missing)

    index_files_in_design = {
        f for f in index_files if not f.startswith("..") and not os.path.isabs(f)
    }
    unindexed_in_repo = repo_files - index_files_in_design

    # 2. Frontmatter Auditing
    frontmatter_checked = 0
    schema_errors = {}
    alignment_errors = {}
    dead_link_errors = {}
    missing_frontmatter = []

    for rel_path in sorted(repo_files):
        if not rel_path.endswith(".md"):
            continue

        abs_path = os.path.join(design_root, rel_path)
        is_required_dir = any(
            rel_path.startswith(req_dir + "/") or rel_path == req_dir
            for req_dir in FRONTMATTER_REQUIRED_DIRS
        )

        fm, err = extract_frontmatter(abs_path)
        if err:
            schema_errors[rel_path] = [err]
            continue

        if fm is None:
            if is_required_dir:
                missing_frontmatter.append(rel_path)
            continue

        frontmatter_checked += 1

        # Validate schema
        s_errs = validate_frontmatter_schema(fm, rel_path)
        if s_errs:
            schema_errors[rel_path] = s_errs

        # Validate alignment
        idx_entry = entries_by_path.get(rel_path)
        a_errs = validate_metadata_alignment(fm, idx_entry, rel_path)
        if a_errs:
            alignment_errors[rel_path] = a_errs

        # Validate dead links
        d_errs = validate_related_files(fm, repo_root, design_root, abs_path)
        if d_errs:
            dead_link_errors[rel_path] = d_errs

    # Print Results
    print("--- Design Index & Frontmatter Audit ---\n")

    has_fatal_error = False

    if missing_from_disk:
        has_fatal_error = True
        print(f"[MISSING] Files registered in index but missing on disk ({len(missing_from_disk)}):")
        for f in sorted(missing_from_disk):
            print(f"  - {f}")
    else:
        print("[OK] All index files found on disk.")

    if unindexed_in_repo:
        has_fatal_error = True
        print(f"[UNINDEXED] Files in design/ but not registered in index ({len(unindexed_in_repo)}):")
        for f in sorted(unindexed_in_repo):
            print(f"  - {f}")
    else:
        print("[OK] All design/ files are indexed.")

    if schema_errors:
        has_fatal_error = True
        print(f"\n[SCHEMA ERRORS] Frontmatter schema violations ({len(schema_errors)}):")
        for f, errs in sorted(schema_errors.items()):
            print(f"  - {f}:")
            for e in errs:
                print(f"      * {e}")
    else:
        print(f"[OK] Frontmatter schema valid across all {frontmatter_checked} documented files.")

    if alignment_errors:
        has_fatal_error = True
        print(f"\n[ALIGNMENT ERRORS] Frontmatter vs. index mismatches ({len(alignment_errors)}):")
        for f, errs in sorted(alignment_errors.items()):
            print(f"  - {f}:")
            for e in errs:
                print(f"      * {e}")
    else:
        print("[OK] Metadata alignment verified between frontmatter and index.")

    if dead_link_errors:
        has_fatal_error = True
        print(f"\n[DEAD LINKS] Invalid links in related_files ({len(dead_link_errors)}):")
        for f, errs in sorted(dead_link_errors.items()):
            print(f"  - {f}:")
            for e in errs:
                print(f"      * {e}")
    else:
        print("[OK] All related_files references exist on disk.")

    if missing_frontmatter:
        if args.strict:
            has_fatal_error = True
            print(f"\n[STRICT ERROR] Files missing required frontmatter ({len(missing_frontmatter)}):")
        else:
            print(
                f"\n[PENDING WP2 BACKFILL] Active synthesis files awaiting epistemic frontmatter ({len(missing_frontmatter)}):"
            )
        for f in sorted(missing_frontmatter):
            print(f"  - {f}")
    else:
        print("[OK] All required directories contain epistemic frontmatter.")

    print("\n--- Audit Summary ---")
    if has_fatal_error:
        print("FAIL: Discrepancies detected. Please correct the errors above.")
        sys.exit(1)
    else:
        print("PASS: Index and frontmatter synchronization checks passed.")
        sys.exit(0)

if __name__ == "__main__":
    main()
