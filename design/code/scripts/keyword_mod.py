# Purpose: CLI tool for normalizing and renaming keywords across the project.

import re
import sys
from pathlib import Path
from collections.abc import Iterator
from functools import partial

import clifun

# --- PATH RESOLUTION ---
# Parents: 0=scripts, 1=code, 2=PROJECT_ROOT
PROJECT_ROOT = Path(__file__).parents[2]

def ignore_path(p: Path) -> bool:
    """
    Filter to ignore infrastructure and generated files.
    """
    # Relative to project root for consistent filtering
    try:
        parts = p.relative_to(PROJECT_ROOT).parts
    except ValueError:
        return True

    if parts[0] in ["code", ".git", "ai", "export"]: # Added 'export' to ignore list
        return True
    if p.name in ["inspiration-sources.yaml", "verisimilitude-sources.yaml"]:
        return True
    if parts[0] == "research":
        if len(parts) > 1 and parts[1] == "reports":
            return True
    return False

def walk_directories(p: Path) -> Iterator[Path]:
    """Recursively yield file paths, skipping ignored directories."""
    for x in p.iterdir():
        if ignore_path(x):
            continue
        elif x.is_dir():
            yield from walk_directories(x)
        else:
            yield x

def mutate_file_subn(target: str, replacement: str, p: Path) -> int:
    with p.open("r", encoding="utf-8") as f:
        contents = f.read()
    
    (new_contents, n_replacements) = re.subn(target, replacement, contents)
    
    if n_replacements > 0:
        with p.open("w", encoding="utf-8") as f:
            f.write(new_contents)
    return n_replacements

def fenced_keyword(keyword: str) -> str:
    return f"`{keyword}`"

def mutate_file_normalize_keyword(p: Path, keyword: str) -> int:
    # Normalize occurrences where the keyword is not already fenced
    return mutate_file_subn(rf"[^ ()\n]\**`?{keyword}`?\**", fenced_keyword(keyword), p)

def mutate_file_rename_keyword(p: Path, old: str, new: str) -> int:
    return mutate_file_subn(fenced_keyword(old), fenced_keyword(new), p)

def mutating_walk(f, root=PROJECT_ROOT):
    for p in walk_directories(root):
        try:
            r = f(p)
            if r:
                print(f"Updated {r} occurrences in {p.relative_to(PROJECT_ROOT)}")
        except UnicodeDecodeError:
            print(f"Skipping binary or non-utf8 file: {p}")

def normalize_main(target: str) -> None:
    """Normalize a specific keyword to be backtick-fenced."""
    mutating_walk(partial(mutate_file_normalize_keyword, keyword=target))

def rename_main(old: str, new: str) -> None:
    """Rename a specific keyword across the project."""
    mutating_walk(partial(mutate_file_rename_keyword, old=old, new=new))

def main(mode: str, *args) -> None:
    if mode == "normalize":
        # clifun passes args as list, we need to unpack or handle
        # simple clifun usage usually wraps the function directly.
        # Re-mapping based on original script intent.
        if len(args) != 1:
            print("Usage: normalize <keyword>")
            return
        normalize_main(args[0])
    elif mode == "rename":
        if len(args) != 2:
            print("Usage: rename <old> <new>")
            return
        rename_main(args[0], args[1])
    else:
        print("Available commands are: normalize, rename")

if __name__ == "__main__":
    clifun.call(main)
