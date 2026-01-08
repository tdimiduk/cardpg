#!/usr/bin/env python3
import argparse
import os
import shutil
import subprocess
import sys
from pathlib import Path

def setup_output_dir(output_dir: Path):
    """Ensures output directory exists and has necessary symlinks."""
    if not output_dir.exists():
        output_dir.mkdir(parents=True)
    
    # Symlink config
    # Symlink config
    link_name = "client-reflex"
    target = Path("..") / "client-reflex"
    link_path = output_dir / link_name

    if link_path.exists() or link_path.is_symlink():
        link_path.unlink()
    
    link_path.symlink_to(target)

def run_cabal(args):
    """Runs the cabal command."""
    cmd = ["cabal", "run", "exe:cardpg-static", "--"] + args
    subprocess.run(cmd, check=True, stdout=subprocess.DEVNULL)

def snapshot_catalog(args):
    """Generates the catalog snapshot."""
    output_dir = Path("output")
    setup_output_dir(output_dir)
    
    print("Building static catalog...")
    run_cabal(["--static"])

    # Move generated HTML
    src_html = Path("catalog.html")
    dest_html = output_dir / "catalog.html"
    if src_html.exists():
        src_html.rename(dest_html)
    else:
        print("Error: catalog.html not found", file=sys.stderr)
        sys.exit(1)

    print("Taking screenshot...")
    output_png = output_dir / "catalog.png"
    # Chromium flags
    cmd = [
        "chromium",
        "--headless",
        "--disable-gpu",
        "--hide-scrollbars",
        "--window-size=1920,2000",
        f"--screenshot={output_png}",
        f"file://{dest_html.resolve()}"
    ]
    subprocess.run(cmd, check=True)
    print(f"Snapshot saved to {output_png.resolve()}")

def snapshot_deck(args):
    """Generates deck snapshots for one or more input files."""
    output_dir = Path("output")
    setup_output_dir(output_dir)

    for input_file_str in args.input_files:
        input_file = Path(input_file_str)
        if not input_file.exists():
            print(f"Error: Input file {input_file} not found", file=sys.stderr)
            continue

        basename = input_file.stem

        print(f"Building deck for {basename}...")
        run_cabal(["--deck", str(input_file)])

        # Move generated HTML
        src_html = Path(f"{basename}.html")
        dest_html = output_dir / f"{basename}.html"
        if src_html.exists():
            src_html.rename(dest_html)
        else:
            print(f"Error: {basename}.html not found", file=sys.stderr)
            continue # Skip to next file if HTML wasn't generated

        # PDF Generation
        print(f"Generating PDF to output/{basename}.pdf...")
        output_pdf = output_dir / f"{basename}.pdf"
        
        cmd_pdf = [
            "chromium",
            "--headless",
            "--disable-gpu",
            f"--print-to-pdf={output_pdf}",
            "--no-pdf-header-footer",
            f"file://{dest_html.resolve()}"
        ]
        subprocess.run(cmd_pdf, check=True)
        print(f"PDF saved to {output_pdf.resolve()}")

        # PNG Generation (for visual diffing)
        print(f"Generating PNG to output/{basename}.png...")
        output_png = output_dir / f"{basename}.png"
        
        cmd_png = [
            "chromium",
            "--headless",
            "--disable-gpu",
            "--hide-scrollbars",
            "--window-size=1920,2000", # Approximate decent size for a deck view
            f"--screenshot={output_png}",
            f"file://{dest_html.resolve()}"
        ]
        subprocess.run(cmd_png, check=True)
        print(f"PNG saved to {output_png.resolve()}")

def main():
    # Ensure we are in the project root
    script_dir = Path(__file__).resolve().parent
    project_root = script_dir.parent
    os.chdir(project_root)

    parser = argparse.ArgumentParser(description="Generate snapshots for CardPG catalog and decks.")
    subparsers = parser.add_subparsers(dest="command", required=True)

    # Catalog subcommand
    parser_catalog = subparsers.add_parser("catalog", help="Generate catalog snapshot")
    parser_catalog.set_defaults(func=snapshot_catalog)

    # Deck subcommand
    parser_deck = subparsers.add_parser("deck", help="Generate deck snapshot")
    parser_deck.add_argument("input_files", nargs='+', help="Path to actor YAML file(s)")
    parser_deck.set_defaults(func=snapshot_deck)

    args = parser.parse_args()
    args.func(args)

if __name__ == "__main__":
    main()
