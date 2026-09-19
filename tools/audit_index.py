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
   - Frontmatter 'doc_type' matches index tags.
4. Dead link detection:
   - All paths declared in 'related_files' exist on disk.
5. Missing frontmatter tracking:
   - Identifies documents in required directories (research/synthesis, research/theory/readings)
     awaiting frontmatter. Use --strict to treat as fatal.
"""

import argparse
import os
import re
import subprocess
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

TYPE_MAP = {
    "synthesis": "Research Synthesis",
    "literature-note": "Literature Note",
    "report": "Research Report",
    "rules": "Game Rules",
    "iteration": "Design Exploration",
    "ideation": "Ideation",
    "meta": "Meta Document",
    "introductory-text": "Introductory Text",
}

DOC_TYPE_CANONICAL_TAGS = {
    "synthesis": "doc-type:research-synthesis",
    "literature-note": "doc-type:literature-note",
    "report": "doc-type:research-report",
    "rules": "doc-type:rules",
    "iteration": "doc-type:iteration",
    "ideation": "doc-type:ideation",
    "meta": "doc-type:meta",
    "introductory-text": "doc-type:introductory-text",
}

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
                    if node.get("type") == "Index" or rel_path.endswith("index.yaml") or "doc-type:index" in node.get("tags", []):
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
    try:
        res = subprocess.run(
            ["git", "ls-files", "."],
            capture_output=True,
            text=True,
            check=True,
            cwd=root_dir,
        )
        for line in res.stdout.splitlines():
            rel = line.strip().replace("\\", "/")
            if not rel or rel == "index.yaml" or rel.endswith("/index.yaml"):
                continue
            if not os.path.exists(os.path.join(root_dir, rel)):
                continue
            files.add(rel)
        return files, True
    except Exception:
        pass

    skip_dirs = {".git", ".gemini", "node_modules", "__pycache__", "sources"}
    for root, dirs, filenames in os.walk(root_dir):
        dirs[:] = [d for d in dirs if d not in skip_dirs]

        for filename in filenames:
            if filename == "index.yaml":
                continue

            full_path = os.path.join(root, filename)
            rel_path = os.path.relpath(full_path, root_dir)
            files.add(rel_path.replace("\\", "/"))

    return files, False

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
        if idx_type and idx_type in allowed_matchers:
            matched = True
        else:
            for tag in idx_tags:
                if tag in allowed_matchers:
                    matched = True
                    break

        if not matched:
            errors.append(
                f"Document type mismatch: frontmatter doc_type '{doc_type}' does not align with "
                f"index tags '{index_entry.get('tags')}'"
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

def extract_first_paragraph(file_path):
    try:
        with open(file_path, "r", encoding="utf-8") as f:
            lines = f.readlines()
    except Exception:
        return ""

    fm_count = 0
    body_lines = []
    for line in lines:
        if line.strip() == "---":
            fm_count += 1
            continue
        if fm_count >= 2 or fm_count == 0:
            body_lines.append(line)

    para = []
    for line in body_lines:
        s = line.strip()
        if not s:
            if para:
                break
            continue
        if s.startswith("#") or s.startswith("|") or s.startswith("```") or s.startswith(">"):
            if para:
                break
            continue
        para.append(s)

    full_text = " ".join(para).strip()
    if full_text:
        if len(full_text) > 200:
            idx = full_text.find(". ", 60)
            if idx != -1 and idx < 250:
                return full_text[: idx + 1]
            return full_text[:197] + "..."
        return full_text
    return ""

def scaffold_epistemic_frontmatter(rel_path, abs_file_path):
    try:
        with open(abs_file_path, "r", encoding="utf-8") as f:
            content = f.read()
    except Exception as e:
        return None, f"Could not read file for scaffolding: {e}"

    title = None
    for line in content.splitlines():
        s = line.strip()
        if s.startswith("# "):
            title = s[2:].strip()
            break

    if not title:
        stem = Path(rel_path).stem
        title = stem.replace("-", " ").replace("_", " ").title()

    if rel_path.startswith("research/synthesis/"):
        doc_type = "synthesis"
        track = "verisimilitude"
    elif rel_path.startswith("research/theory/readings/"):
        doc_type = "literature-note"
        track = "ludology"
    elif rel_path.startswith("research/reports/"):
        doc_type = "report"
        track = "verisimilitude"
    elif rel_path.startswith("rules/"):
        doc_type = "rules"
        track = "ludology"
    elif rel_path.startswith("iteration/"):
        doc_type = "iteration"
        track = "ludology"
    elif rel_path.startswith("philosophy/"):
        doc_type = "meta"
        track = "ludology"
    else:
        doc_type = "iteration"
        track = "ludology"

    fm_data = {
        "title": title,
        "doc_type": doc_type,
        "track": track,
        "origin": "AI drafted",
        "epistemic_status": {
            "confidence": "medium",
            "vetted_by_human": False,
        },
    }

    fm_yaml = yaml.dump(fm_data, sort_keys=False, default_flow_style=False).strip()
    new_content = f"---\n{fm_yaml}\n---\n\n{content.lstrip()}"

    try:
        with open(abs_file_path, "w", encoding="utf-8") as f:
            f.write(new_content)
        return fm_data, None
    except Exception as e:
        return None, f"Failed to write scaffolded frontmatter: {e}"

def resolve_index_target(rel_path, doc_type):
    if rel_path.startswith("research/"):
        if rel_path.startswith("research/synthesis/"):
            return "research/index.yaml", "research_synthesis"
        elif rel_path.startswith("research/theory/readings/"):
            return "research/index.yaml", "design_theory_and_readings"
        elif rel_path.startswith("research/reports/"):
            return "research/index.yaml", "research_reports"
        else:
            return "research/index.yaml", "research_synthesis"
    elif rel_path.startswith("iteration/"):
        return "iteration/index.yaml", "ideation_and_sketches"
    elif rel_path.startswith("archive/"):
        return "archive/index.yaml", "orientation"
    elif rel_path.startswith("rules/"):
        if rel_path.startswith("rules/modules/"):
            return "index.yaml", "modular_rules_modules"
        else:
            return "index.yaml", "core_framework"
    elif rel_path.startswith("philosophy/"):
        return "index.yaml", "philosophy"
    else:
        return "index.yaml", "core_framework"

def insert_entry_into_index(index_abs_path, section_key, entry):
    if not os.path.exists(index_abs_path):
        return False, f"Target index file {index_abs_path} does not exist"

    with open(index_abs_path, "r", encoding="utf-8") as f:
        lines = f.readlines()

    section_pattern = re.compile(rf"^(\s*){re.escape(section_key)}:\s*$")
    section_idx = -1
    section_indent = 0
    for i, line in enumerate(lines):
        m = section_pattern.match(line)
        if m:
            section_idx = i
            section_indent = len(m.group(1))
            break

    if section_idx == -1:
        return False, f"Could not find section '{section_key}:' in {index_abs_path}"

    insert_idx = len(lines)
    for i in range(section_idx + 1, len(lines)):
        line = lines[i]
        stripped = line.strip()
        if not stripped or stripped.startswith("#"):
            continue
        indent = len(line) - len(line.lstrip())
        if indent <= section_indent:
            insert_idx = i
            break

    item_indent = " " * (section_indent + 2)
    prop_indent = " " * (section_indent + 4)

    entry_lines = []
    entry_lines.append(f'{item_indent}- name: "{entry["name"]}"\n')
    entry_lines.append(f'{prop_indent}path: "{entry["path"]}"\n')
    clean_purpose = entry["purpose"].replace('"', '\\"')
    entry_lines.append(f'{prop_indent}purpose: "{clean_purpose}"\n')
    tags_formatted = ", ".join(f'"{t}"' for t in entry["tags"])
    entry_lines.append(f'{prop_indent}tags: [{tags_formatted}]\n')

    new_lines = lines[:insert_idx] + entry_lines + lines[insert_idx:]

    test_content = "".join(new_lines)
    try:
        yaml.safe_load(test_content)
    except Exception as e:
        return False, f"Generated YAML is invalid: {e}"

    with open(index_abs_path, "w", encoding="utf-8") as f:
        f.writelines(new_lines)

    return True, None

def auto_index_unindexed_files(unindexed_files, design_root):
    fixed_count = 0
    for rel_path in sorted(unindexed_files):
        if not rel_path.endswith(".md"):
            print(f"[SKIP] Cannot auto-index non-markdown file '{rel_path}'. Manual indexing required.")
            continue

        abs_path = os.path.join(design_root, rel_path)
        fm, err = extract_frontmatter(abs_path)
        if err:
            print(f"[SKIP] Cannot auto-index '{rel_path}': frontmatter error: {err}")
            continue

        if fm is None:
            fm, s_err = scaffold_epistemic_frontmatter(rel_path, abs_path)
            if s_err:
                print(f"[SKIP] Failed to scaffold frontmatter for '{rel_path}': {s_err}")
                continue
            print(f"[FIX] Scaffolding epistemic frontmatter in '{rel_path}'")

        schema_errs = validate_frontmatter_schema(fm, rel_path)
        if schema_errs:
            print(f"[SKIP] Frontmatter schema errors in '{rel_path}': {schema_errs}")
            continue

        doc_type = fm.get("doc_type", "iteration")
        target_idx_rel, section_key = resolve_index_target(rel_path, doc_type)
        target_idx_abs = os.path.join(design_root, target_idx_rel)

        stem = Path(rel_path).stem
        slug = re.sub(r"[^a-zA-Z0-9_-]", "", stem)
        if doc_type == "synthesis" and not slug.startswith("synthesis-"):
            entry_id = f"synthesis-{slug}"
        elif doc_type == "report" and not slug.startswith("report-"):
            entry_id = f"report-{slug}"
        else:
            entry_id = slug

        purpose = fm.get("purpose") or fm.get("description")
        if not purpose:
            purpose = extract_first_paragraph(abs_path)
        if not purpose:
            purpose = f"Documentation and design specifications for {fm.get('title')}."

        tags = []
        dt_tag = DOC_TYPE_CANONICAL_TAGS.get(doc_type, f"doc-type:{doc_type}")
        tags.append(dt_tag)
        if rel_path.startswith("rules/"):
            tags.append("audience:player-facing")
        else:
            tags.append("audience:designer-facing")
        if fm.get("track"):
            tags.append(f"track:{fm.get('track')}")
        for t in fm.get("tags", []):
            if t not in tags:
                tags.append(t)

        entry = {
            "name": fm.get("title"),
            "id": entry_id,
            "path": rel_path,
            "purpose": purpose,
            "tags": tags,
        }

        ok, ins_err = insert_entry_into_index(target_idx_abs, section_key, entry)
        if not ok:
            print(f"[ERROR] Failed to insert '{rel_path}' into {target_idx_rel} [{section_key}]: {ins_err}")
        else:
            print(f"[FIX] Auto-indexed '{rel_path}' -> {target_idx_rel} [{section_key}]")
            fixed_count += 1

    return fixed_count

def clean_desc(text, max_len=160):
    if not text:
        return ""
    s = text.replace("\n", " ").strip()
    if len(s) > max_len:
        idx = s.find(". ", 40)
        if idx != -1 and idx < max_len:
            return s[: idx + 1]
        return s[: max_len - 3] + "..."
    return s

def make_markdown_table(headers, rows):
    out = []
    out.append("| " + " | ".join(headers) + " |")
    out.append("| " + " | ".join([":---"] * len(headers)) + " |")
    for row in rows:
        out.append("| " + " | ".join(row) + " |")
    return "\n".join(out)

def compute_sub_index_tags(design_root, sub_index_rel_path):
    sub_index_abs = os.path.join(design_root, sub_index_rel_path)
    if not os.path.exists(sub_index_abs):
        return []

    try:
        data = load_index(sub_index_abs)
    except Exception:
        return []

    tags = set()

    def walk_tags(node):
        if isinstance(node, dict):
            if "tags" in node and isinstance(node["tags"], list):
                tags.update(node["tags"])
            if (node.get("type") == "Index" or node.get("path", "").endswith("index.yaml") or "doc-type:index" in node.get("tags", [])) and "path" in node:
                child_rel = node["path"]
                child_abs = os.path.join(design_root, child_rel)
                if os.path.exists(child_abs) and os.path.abspath(child_abs) != os.path.abspath(sub_index_abs):
                    tags.update(compute_sub_index_tags(design_root, child_rel))
            for k, v in node.items():
                if k != "tags":
                    walk_tags(v)
        elif isinstance(node, list):
            for item in node:
                walk_tags(item)

    walk_tags(data)
    return sorted(list(tags))

def generate_root_toc(design_root):
    root_data = load_index(os.path.join(design_root, "index.yaml"))
    foundations = []
    for sec_k in ["philosophy", "design_patterns", "methodology"]:
        for item in root_data.get("project_foundation", {}).get(sec_k, []):
            foundations.append([f"[{item['name']}]({item['path']})", clean_desc(item.get("purpose", ""))])
    for item in root_data.get("introductory_materials", []):
        if item.get("path") in ["AGENTS.md", "introduction.md"]:
            foundations.append([f"[{item['name']}]({item['path']})", clean_desc(item.get("purpose", ""))])

    rules = []
    for sec_k in ["core_rules_and_guides", "lexicons", "modules"]:
        for item in root_data.get("game_system_and_rules", {}).get(sec_k, []):
            rules.append([f"[{item['name']}]({item['path']})", clean_desc(item.get("purpose", ""))])

    domains = []
    for item in root_data.get("sub_indexes", []):
        name = item["name"].replace(" Index", "")
        dir_name = item["path"].split("/")[0]
        domains.append([f"**{name}**", f"[{dir_name}/]({dir_name}/README.md) ([Index]({item['path']}))", clean_desc(item.get("purpose", ""))])

    blocks = [
        "## Directory Catalog",
        "",
        "### Foundations & Philosophy",
        make_markdown_table(["Document", "Summary"], foundations),
        "",
        "### Rules & Mechanics",
        make_markdown_table(["Document", "Summary"], rules),
        "",
        "### Domain Catalogs",
        make_markdown_table(["Domain", "Directory / Sub-Index", "Focus & Scope"], domains),
        "",
        "*Last synced from `design/index.yaml` via `tools/audit_index.py`.*",
    ]
    return "\n".join(blocks)

def generate_iteration_toc(design_root):
    iter_data = load_index(os.path.join(design_root, "iteration/index.yaml"))
    constraints = []
    for item in iter_data.get("active_design_exploration", {}).get("mechanical_constraints", []):
        rel_p = item["path"].replace("iteration/", "")
        constraints.append([f"[{item['name']}]({rel_p})", clean_desc(item.get("purpose", ""))])

    proposals = []
    for sec_k in ["resolution_and_combat_proposals", "mechanics_and_resource_proposals"]:
        for item in iter_data.get("active_design_exploration", {}).get(sec_k, []):
            rel_p = item["path"].replace("iteration/", "")
            if rel_p.endswith("index.yaml"):
                rel_p = rel_p.replace("index.yaml", "README.md")
            proposals.append([f"[{item['name']}]({rel_p})", clean_desc(item.get("purpose", ""))])

    sketches = []
    for item in iter_data.get("active_design_exploration", {}).get("ideation_and_sketches", []):
        rel_p = item["path"].replace("iteration/", "")
        sketches.append([f"[{item['name']}]({rel_p})", clean_desc(item.get("purpose", ""))])

    blocks = [
        "## Active Iteration Catalog",
        "",
        "### Mechanical Constraints & Frameworks",
        make_markdown_table(["Document", "Summary"], constraints),
        "",
        "### Active Proposals & Mechanics",
        make_markdown_table(["Document", "Summary"], proposals),
        "",
        "### Ideation Sketches",
        make_markdown_table(["Document", "Summary"], sketches),
        "",
        "*Last synced from `iteration/index.yaml` via `tools/audit_index.py`.*",
    ]
    return "\n".join(blocks)

def generate_research_toc(design_root):
    res_data = load_index(os.path.join(design_root, "research/index.yaml")).get("design_process_and_research", {})
    bedrock = []
    for sec_k in ["factual_bedrock", "inspiration_library", "ludology_library"]:
        for item in res_data.get(sec_k, []):
            rel_p = item["path"].replace("research/", "")
            bedrock.append([f"[{item['name']}]({rel_p})", clean_desc(item.get("purpose", ""))])

    syntheses = []
    for item in res_data.get("research_synthesis", []):
        rel_p = item["path"].replace("research/", "")
        syntheses.append([f"[{item['name']}]({rel_p})", clean_desc(item.get("purpose", ""))])

    reports = []
    for item in res_data.get("research_reports", []):
        rep_f = item.get("components", {}).get("report_file", "")
        if rep_f.startswith("research/"):
            rep_f = rep_f[len("research/") :]
        reports.append([f"[{item['name']}]({rep_f})", clean_desc(item.get("purpose", ""))])

    theory = []
    for item in res_data.get("design_theory_and_readings", []):
        rel_p = item["path"].replace("research/", "")
        theory.append([f"[{item['name']}]({rel_p})", clean_desc(item.get("purpose", ""))])

    blocks = [
        "## Research Catalog",
        "",
        "### Bibliographies & Bedrock",
        make_markdown_table(["Document", "Summary"], bedrock),
        "",
        "### Living Research Syntheses (`synthesis/`)",
        make_markdown_table(["Document", "Summary"], syntheses),
        "",
        "### Empirical Reports (`reports/`)",
        make_markdown_table(["Report", "Summary"], reports),
        "",
        "### Game Design Theory (`theory/readings/`)",
        make_markdown_table(["Document", "Summary"], theory),
        "",
        "*Last synced from `research/index.yaml` via `tools/audit_index.py`.*",
    ]
    return "\n".join(blocks)

def generate_archive_toc(design_root):
    arch_data = load_index(os.path.join(design_root, "archive/index.yaml")).get("archive_and_legacy_materials", {})
    arch_items = []
    for item in arch_data.get("archived_playtest_spreadsheets", []):
        arch_items.append([f"[{item['name']}]({item['path']})", clean_desc(item.get("purpose", ""))])

    blocks = [
        "## Archived Content Catalog",
        "",
        "### Playtest Spreadsheets & Materials",
        make_markdown_table(["Item", "Summary"], arch_items),
        "",
        "*Last synced from `archive/index.yaml` via `tools/audit_index.py`.*",
    ]
    return "\n".join(blocks)

def normalize_markdown_block(text):
    lines = []
    for line in text.strip().splitlines():
        line = line.strip()
        if not line:
            continue
        if line in ("<!-- BEGIN AUTO-TOC -->", "<!-- END AUTO-TOC -->"):
            continue
        if line.startswith("|") and line.endswith("|"):
            cells = [c.strip() for c in line.split("|")]
            if all(c == "" or re.match(r"^:?-+:?$", c) for c in cells):
                lines.append("TABLE_SEP")
            else:
                lines.append("ROW:" + "|".join(cells))
        else:
            line = re.sub(r"^[\*_]Last synced(.*)[\*_]$", r"_Last synced\1_", line)
            lines.append(line)
    return lines

def update_or_verify_readme_toc(readme_abs_path, toc_body, fix=False):
    expected_block = f"<!-- BEGIN AUTO-TOC -->\n{toc_body.strip()}\n<!-- END AUTO-TOC -->"
    if not os.path.exists(readme_abs_path):
        if fix:
            with open(readme_abs_path, "w", encoding="utf-8") as f:
                f.write(expected_block + "\n")
            return True, None
        return False, f"README file {readme_abs_path} does not exist"

    with open(readme_abs_path, "r", encoding="utf-8") as f:
        content = f.read()

    pattern = re.compile(r"<!-- BEGIN AUTO-TOC -->.*?<!-- END AUTO-TOC -->", re.DOTALL)
    match = pattern.search(content)

    if not match:
        if fix:
            new_content = content.rstrip() + "\n\n" + expected_block + "\n"
            with open(readme_abs_path, "w", encoding="utf-8") as f:
                f.write(new_content)
            return True, None
        return False, "Missing <!-- BEGIN AUTO-TOC --> block"

    existing_block = match.group(0).strip()
    if normalize_markdown_block(existing_block) == normalize_markdown_block(expected_block):
        return True, None

    if fix:
        new_content = pattern.sub(expected_block.strip(), content)
        with open(readme_abs_path, "w", encoding="utf-8") as f:
            f.write(new_content)
        return True, None

    return False, "Table of contents is out of date"

def audit_and_sync_aggregated_tags(design_root, index_path, fix=False):
    root_data = load_index(index_path)
    sub_indexes = root_data.get("sub_indexes", [])
    errors = []

    tags_by_subindex = {}
    needs_update = False

    for item in sub_indexes:
        sub_name = item.get("name")
        sub_path = item.get("path")
        if not sub_path:
            continue
        actual_tags = compute_sub_index_tags(design_root, sub_path)
        existing_tags = item.get("aggregated_tags", [])
        if actual_tags != existing_tags:
            needs_update = True
            errors.append(f"Aggregated tags for '{sub_name}' ({sub_path}) out of date")
            tags_by_subindex[sub_name] = actual_tags

    if needs_update and fix:
        with open(index_path, "r", encoding="utf-8") as f:
            lines = f.readlines()

        new_lines = []
        curr_sub_name = None
        for line in lines:
            name_m = re.match(r'^\s*-\s*name:\s*"(.*?)"', line)
            if name_m:
                curr_sub_name = name_m.group(1)

            agg_m = re.match(r'^(\s*)aggregated_tags:\s*\[.*\]', line)
            if agg_m and curr_sub_name in tags_by_subindex:
                indent = agg_m.group(1)
                tags_str = ", ".join(f'"{t}"' for t in tags_by_subindex[curr_sub_name])
                new_lines.append(f"{indent}aggregated_tags: [{tags_str}]\n")
                continue

            new_lines.append(line)

        with open(index_path, "w", encoding="utf-8") as f:
            f.writelines(new_lines)
        return []

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
    parser.add_argument(
        "--fix",
        action="store_true",
        help="Automatically scaffold frontmatter and register unindexed markdown files in the appropriate index.",
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
    repo_files, is_git = get_repo_files(design_root)

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
        f
        for f in index_files
        if not f.startswith("..")
        and not os.path.isabs(f)
        and not f.endswith("index.yaml")
        and not f.startswith("http://")
        and not f.startswith("https://")
    }
    unindexed_in_repo = repo_files - index_files_in_design
    untracked_in_git = (
        {f for f in (index_files_in_design - repo_files) if f not in missing_from_disk}
        if is_git
        else set()
    )

    if args.fix and unindexed_in_repo:
        print(f"--- Auto-indexing {len(unindexed_in_repo)} unindexed file(s) ---\n")
        fixed = auto_index_unindexed_files(unindexed_in_repo, design_root)
        if fixed > 0:
            index_files, entries_by_path, missing_indexes = load_all_index_data(design_root, index_path)
            repo_files, is_git = get_repo_files(design_root)
            index_files_in_design = {
                f
                for f in index_files
                if not f.startswith("..")
                and not os.path.isabs(f)
                and not f.endswith("index.yaml")
                and not f.startswith("http://")
                and not f.startswith("https://")
            }
            unindexed_in_repo = repo_files - index_files_in_design
            untracked_in_git = (
                {f for f in (index_files_in_design - repo_files) if f not in missing_from_disk}
                if is_git
                else set()
            )

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

    # 3. Sub-index Tag Rollup Auditing
    tag_errors = audit_and_sync_aggregated_tags(design_root, index_path, fix=args.fix)

    # 4. Table of Contents (TOC) Auditing
    toc_generators = {
        "README.md": generate_root_toc,
        "iteration/README.md": generate_iteration_toc,
        "research/README.md": generate_research_toc,
        "archive/README.md": generate_archive_toc,
    }
    toc_errors = {}
    for rel_readme, gen_fn in toc_generators.items():
        readme_abs = os.path.join(design_root, rel_readme)
        toc_body = gen_fn(design_root)
        ok, err = update_or_verify_readme_toc(readme_abs, toc_body, fix=args.fix)
        if not ok:
            toc_errors[rel_readme] = err

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

    if untracked_in_git:
        has_fatal_error = True
        print(f"[UNTRACKED IN GIT] Files registered in index but not tracked by git ({len(untracked_in_git)}):")
        for f in sorted(untracked_in_git):
            print(f"  - {f}")
        print("  Run 'git add <file>' to track, or remove from index.")
    elif is_git:
        print("[OK] All indexed files are tracked by git.")

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

    if tag_errors:
        has_fatal_error = True
        print(f"\n[TAG ROLLUP ERRORS] Sub-index aggregated_tags out of date ({len(tag_errors)}):")
        for e in tag_errors:
            print(f"  - {e}")
        print("  Run 'python3 tools/audit_index.py --fix' to update.")
    else:
        print("[OK] Sub-index aggregated tags verified.")

    if toc_errors:
        has_fatal_error = True
        print(f"\n[TOC ERRORS] README tables of contents out of date ({len(toc_errors)}):")
        for f, e in sorted(toc_errors.items()):
            print(f"  - {f}: {e}")
        print("  Run 'python3 tools/audit_index.py --fix' to synchronize README maps.")
    else:
        print("[OK] All directory README tables of contents are up to date.")

    print("\n--- Audit Summary ---")
    if has_fatal_error:
        print("FAIL: Discrepancies detected. Please correct the errors above.")
        sys.exit(1)
    else:
        print("PASS: Index and frontmatter synchronization checks passed.")
        sys.exit(0)

if __name__ == "__main__":
    main()
