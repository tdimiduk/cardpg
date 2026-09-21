#!/usr/bin/env python3
"""
Keyword Normalization and Wikilink Standardization Utility

Normalizes game mechanical keywords across documentation to use double-bracket
wikilinks (`[[Keyword]]`). Extracts canonical terms and aliases directly from
`design/rules/keyword-glossary.md`.
"""

import argparse
import re
import sys
from pathlib import Path
from collections.abc import Iterator

PROJECT_ROOT = Path(__file__).resolve().parents[2]
GLOSSARY_PATH = PROJECT_ROOT / "design" / "rules" / "keyword-glossary.md"
DEFAULT_TARGET_DIRS = [
    PROJECT_ROOT / "design" / "rules",
    PROJECT_ROOT / "design" / "philosophy",
]


def ignore_path(p: Path) -> bool:
    """Filter to ignore code, tooling, git, scratch, and research archives."""
    try:
        parts = p.relative_to(PROJECT_ROOT).parts
    except ValueError:
        return True

    if parts[0] in ["code", ".git", "ai", "export", "tools", "client", ".venv", "scratch"]:
        return True
    if p.name in [
        "inspiration-sources.yaml",
        "verisimilitude-sources.yaml",
        "ludology-sources.yaml",
    ]:
        return True
    if parts[0] == "design" and len(parts) > 1 and parts[1] == "research":
        return True
    return False


def walk_markdown_files(targets: list[Path]) -> Iterator[Path]:
    """Recursively yield markdown files in specified target directories, skipping ignored paths."""
    for target in targets:
        if not target.exists():
            continue
        if target.is_file() and target.suffix == ".md":
            if target.resolve() != GLOSSARY_PATH.resolve():
                yield target
            continue
        for path in target.rglob("*.md"):
            if ignore_path(path):
                continue
            if path.resolve() == GLOSSARY_PATH.resolve():
                continue
            yield path


def parse_glossary(glossary_path: Path = GLOSSARY_PATH) -> dict[str, list[str]]:
    """
    Parse keyword-glossary.md to extract canonical keywords and their aliases.
    Returns a dict mapping canonical keyword -> list of aliases.
    """
    if not glossary_path.exists():
        print(f"Warning: Glossary not found at {glossary_path}", file=sys.stderr)
        return {}

    text = glossary_path.read_text(encoding="utf-8")
    keywords: dict[str, list[str]] = {}
    current_kw: str | None = None

    for line in text.splitlines():
        heading_match = re.match(r"^(?:###|####)\s+([A-Za-z0-9 ]+)", line)
        if heading_match:
            current_kw = heading_match.group(1).strip()
            keywords[current_kw] = []
        elif current_kw and re.match(r"^[_*]Aliases:\s*(.+)[_*]", line):
            alias_match = re.match(r"^[_*]Aliases:\s*(.+)[_*]", line)
            if alias_match:
                alias_str = alias_match.group(1)
                aliases = [a.strip() for a in alias_str.split(",") if a.strip()]
                keywords[current_kw].extend(aliases)

    return keywords


def get_all_terms(keywords: dict[str, list[str]]) -> list[str]:
    """Return all canonical keywords and aliases, sorted longest first."""
    all_terms = set()
    for kw, aliases in keywords.items():
        all_terms.add(kw)
        for a in aliases:
            all_terms.add(a)
    return sorted(all_terms, key=lambda x: -len(x))


def transform_line(line: str, terms: list[str]) -> str:
    """
    Safely normalize keywords on a single line of markdown.
    Protects markdown links, existing wikilinks, multi-backtick spans, and headings.
    """
    # Don't touch Markdown headings
    if line.strip().startswith("#"):
        return line

    placeholders: list[str] = []

    def mask(match: re.Match[str]) -> str:
        idx = len(placeholders)
        placeholders.append(match.group(0))
        return f"___KW_MASK_{idx}___"

    # 1. Mask multi-backtick spans (`` `code` ``) to protect meta-documentation / code literals
    masked = re.sub(r"`{2,}.*?`{2,}", mask, line)
    # 2. Mask markdown links [text](url)
    masked = re.sub(r"\[[^\]]+\]\([^)]+\)", mask, masked)
    # 3. Mask existing wikilinks [[term]]
    masked = re.sub(r"\[\[[^\]]+\]\]", mask, masked)

    # Transform trailing 's' on existing or backticked keywords (e.g. `Color`s -> [[Colors]])
    for t in terms:
        if t.endswith("s") and t[:-1] in terms:
            singular = t[:-1]
            masked = re.sub(rf"\`{re.escape(singular)}\`s\b", f"[[{t}]]", masked)

    # Transform backticked keywords: `Term` -> [[Term]]
    for t in terms:
        masked = re.sub(rf"\`{re.escape(t)}\`", f"[[{t}]]", masked)

    # Transform bolded keywords: **Term** -> [[Term]] (only exact keyword matches)
    for t in terms:
        masked = re.sub(rf"\*\*{re.escape(t)}\*\*", f"[[{t}]]", masked)

    # Unmask protected spans
    for i, original in enumerate(placeholders):
        masked = masked.replace(f"___KW_MASK_{i}___", original)

    return masked


def transform_content(content: str, terms: list[str]) -> tuple[str, int]:
    """
    Transforms markdown content, avoiding code blocks.
    Returns (new_content, number_of_changed_lines).
    """
    in_code_block = False
    new_lines = []
    changes = 0

    for line in content.splitlines():
        if line.strip().startswith("```"):
            in_code_block = not in_code_block
            new_lines.append(line)
            continue
        if in_code_block:
            new_lines.append(line)
            continue

        new_line = transform_line(line, terms)
        if new_line != line:
            changes += 1
        new_lines.append(new_line)

    trailing_newline = "\n" if content.endswith("\n") else ""
    return "\n".join(new_lines) + trailing_newline, changes


def normalize_file(path: Path, terms: list[str], dry_run: bool = False) -> int:
    """Normalizes keywords in a single file."""
    try:
        content = path.read_text(encoding="utf-8")
    except UnicodeDecodeError:
        return 0

    new_content, changes = transform_content(content, terms)
    if changes > 0:
        rel_path = path.relative_to(PROJECT_ROOT)
        if dry_run:
            print(f"[DRY RUN] Would update {changes} lines in {rel_path}")
        else:
            path.write_text(new_content, encoding="utf-8")
            print(f"Updated {changes} lines in {rel_path}")
    return changes


def normalize_all(targets: list[Path], dry_run: bool = False) -> None:
    """Normalize all keywords from keyword-glossary.md across target paths."""
    glossary = parse_glossary()
    terms = get_all_terms(glossary)
    print(f"Loaded {len(terms)} terms/aliases from {GLOSSARY_PATH.relative_to(PROJECT_ROOT)}")
    total_changes = 0
    file_count = 0
    for md_file in walk_markdown_files(targets):
        c = normalize_file(md_file, terms, dry_run=dry_run)
        if c > 0:
            total_changes += c
            file_count += 1

    mode_str = "Previewed" if dry_run else "Completed"
    print(f"{mode_str} normalization: {total_changes} line changes across {file_count} files.")


def normalize_keyword(keyword: str, targets: list[Path], dry_run: bool = False) -> None:
    """Normalize a specific keyword and its common plural across target paths."""
    terms = [keyword]
    if not keyword.endswith("s"):
        terms.append(keyword + "s")
    terms.sort(key=lambda x: -len(x))

    total_changes = 0
    for md_file in walk_markdown_files(targets):
        total_changes += normalize_file(md_file, terms, dry_run=dry_run)
    mode_str = "Previewed" if dry_run else "Completed"
    print(f"{mode_str} normalization for '{keyword}': {total_changes} changes.")


def rename_keyword(old_kw: str, new_kw: str, targets: list[Path], dry_run: bool = False) -> None:
    """Rename a keyword (matching [[old]] or `old` or **old**) to [[new]]."""
    total_changes = 0
    for md_file in walk_markdown_files(targets):
        try:
            content = md_file.read_text(encoding="utf-8")
        except UnicodeDecodeError:
            continue

        # Match [[Old]], `Old`, or **Old**
        pattern = rf"(\[\[|\`|\*\*){re.escape(old_kw)}(\]\]|\`|\*\*)"
        new_content, count = re.subn(pattern, f"[[{new_kw}]]", content)
        if count > 0:
            rel = md_file.relative_to(PROJECT_ROOT)
            if dry_run:
                print(f"[DRY RUN] Would rename {count} instances in {rel}")
            else:
                md_file.write_text(new_content, encoding="utf-8")
                print(f"Renamed {count} instances in {rel}")
            total_changes += count

    mode_str = "Previewed" if dry_run else "Completed"
    print(f"{mode_str} rename: {total_changes} instances of '{old_kw}' -> '[[{new_kw}]]'.")


def resolve_targets(paths: list[str] | None) -> list[Path]:
    if not paths:
        return DEFAULT_TARGET_DIRS
    resolved = []
    for p in paths:
        path_obj = Path(p)
        if not path_obj.is_absolute():
            path_obj = PROJECT_ROOT / path_obj
        resolved.append(path_obj)
    return resolved


def main() -> None:
    parser = argparse.ArgumentParser(
        description="Normalize and rename game keywords across markdown documentation."
    )
    parser.add_argument(
        "--dry-run",
        action="store_true",
        help="Preview changes without modifying files.",
    )
    parser.add_argument(
        "--path",
        action="append",
        dest="paths",
        help="Specific file or directory to process (can be specified multiple times; defaults to design/rules and design/philosophy).",
    )

    subparsers = parser.add_subparsers(dest="command", required=True)

    # Subcommand: normalize-all
    subparsers.add_parser(
        "normalize-all",
        help="Normalize all keywords defined in keyword-glossary.md",
    )

    # Subcommand: normalize
    norm_parser = subparsers.add_parser(
        "normalize",
        help="Normalize a single keyword across files",
    )
    norm_parser.add_argument("keyword", help="The keyword to normalize")

    # Subcommand: rename
    rename_parser = subparsers.add_parser(
        "rename",
        help="Rename a keyword across files",
    )
    rename_parser.add_argument("old", help="Old keyword name")
    rename_parser.add_argument("new", help="New keyword name")

    args = parser.parse_args()
    targets = resolve_targets(args.paths)

    if args.command == "normalize-all":
        normalize_all(targets, dry_run=args.dry_run)
    elif args.command == "normalize":
        normalize_keyword(args.keyword, targets, dry_run=args.dry_run)
    elif args.command == "rename":
        rename_keyword(args.old, args.new, targets, dry_run=args.dry_run)


if __name__ == "__main__":
    main()
