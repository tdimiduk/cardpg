# Python Tooling Guide

We use `uv` for Python dependency management and script execution.

## Running Scripts

Always use `uv run` to execute scripts. This ensures dependencies defined in `pyproject.toml` are available.

```bash
uv run tools/path/to/script.py [args]
```

## Dependencies

## Card Tools

### Card Compiler

Compiles YAML card definitions into VTT-compatible JSON.

```bash
# Compile specific file
uv run card_compiler/compiler.py ../design/data/cards/imported/swashbuckler.yaml -o ../vtt-react/data/generated_cards.json

# Compile directory (future support)
# uv run card_compiler/compiler.py ../design/data/cards/ -o ...
```

### Migration Script

Converts legacy Google Sheet JSON exports to Hybrid YAML.

```bash
uv run card_compiler/migrate.py ../scratch/Swashbuckler-sheet.json ../design/data/cards/imported
```
