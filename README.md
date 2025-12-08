# CardPG

## design

The rules of the game, plus backing research, design philosophy and various things.

## cardpg-core

The core types for cards of the game.

## tools

Various scripts for managing data and automatic tasks. Most of these are python scripts intended to be run with `uv run` from the `tools` directory.

## Build System

The project uses a [Shake](https://shakebuild.com/) build system to orchestrate data processing and compilation.

### Usage

Use the `just` command runner:

```bash
just [target]
```

### Targets

- `card-data`: (Default) Compiles all card data to `vtt-react/src/data/generated_cards.json`.
- `sync`: Syncs card data from Google Sheets using the python tools.
- `clean`: (Standard Shake) Cleans build artifacts.
