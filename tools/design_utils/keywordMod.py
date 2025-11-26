#!/usr/bin/env python3

import re
from pathlib import Path
from collections.abc import Iterator
from functools import partial

import clifun


PROJECT_ROOT = Path(__file__).parents[1]

def ignorePath(p):
    parts = p.relative_to(PROJECT_ROOT).parts
    if parts[0] in ["code", ".git", "ai"]:
        return True
    if p.name in ["inspiration-sources.yaml", "verisimilitude-sources.yaml"]:
        return True
    if parts[0] == "research":
        if len(parts) > 1 and parts[1] == "reports":
            return True
    return False

def walkDirectories(p: Path) -> Iterator[Path]:
    for x in p.iterdir():
        if ignorePath(x):
            pass
        elif x.is_dir():
            yield from walkDirectories(x)
        else:
            yield x


def mutateFileSubn(target: str, replacement: str, p: Path) -> int:
    with p.open() as f:
        contents = f.read()
        (newContents, nReplacements) = re.subn(target, replacement, contents)
    if nReplacements > 0:
        with p.open("w") as f:
            f.write(newContents)
    return nReplacements


def fencedKeyword(keyword: str) -> str:
    return f"`{keyword}`"


def mutateFileNormalizeKeyword(p: Path, keyword: str) -> int:
    mutateFileSubn(rf"[^ ()\n]\**`?{keyword}`?\**", fencedKeyword(keyword), p)


def mutateFileRenameKeyword(p: Path, old: str, new: str) -> None:
    mutateFileSubn(fencedKeyword(old), fencedKeyword(new), p)


def mutatingWalk(f, root=PROJECT_ROOT):
    for p in walkDirectories(root):
        r = f(p)
        if r:
            print(f"Updated {r} occurances in {p}")


def normalizeMain(target: str) -> None:
    mutatingWalk(partial(mutateFileNormalizeKeyword, keyword=target))


def renameMain(old: str, new: str) -> None:
    mutatingWalk(partial(mutateFileRenameKeyword, old=old, new=new))


def main(mode: str) -> None:
    if mode == "normalize":
        clifun.call(normalizeMain)
    if mode == "rename":
        clifun.call(renameMain)
    else:
        print("Available commands are normalize and rename")


if __name__ == "__main__":
    clifun.call(normalizeMain)
