#!/usr/bin/env bash

# 1. Safety Checks
set -e

# Ensure the script is being run from the root of the cardpg monorepo
if [[ ! -d "design" || ! -d "data" ]]; then
    echo "Error: This script must be run from the root of the cardpg monorepo."
    exit 1
fi

# 2. Setup Temp Directory
TEMP_DIR=$(mktemp -d)
trap 'rm -rf "$TEMP_DIR"' EXIT

echo "Created temporary directory: $TEMP_DIR"

# 3. Clone Shadow Repo
SHADOW_REPO_URL="git@github.com:tdimiduk/cardpg-design.git"
echo "Cloning shadow repo: $SHADOW_REPO_URL"
git clone --depth 1 "$SHADOW_REPO_URL" "$TEMP_DIR/shadow"

# 4. Clean Existing Mirror
echo "Cleaning existing mirror directories..."
rm -rf "$TEMP_DIR/shadow/design"
rm -rf "$TEMP_DIR/shadow/data"

# 5. Sync Directories
echo "Syncing design/ and data/ directories..."
rsync -av design/ "$TEMP_DIR/shadow/design/"
rsync -av data/ "$TEMP_DIR/shadow/data/"

# 6. Commit and Push
cd "$TEMP_DIR/shadow"

# Add changes
git add design/ data/

# Check for changes
if git diff-index --quiet HEAD --; then
    echo "Success: No changes to sync."
    exit 0
fi

echo "Changes detected, committing and pushing..."
git commit -m "chore: automatic sync from monorepo"
git push origin main

echo "Successfully synced to shadow repo."
