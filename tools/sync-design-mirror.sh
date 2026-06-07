#!/usr/bin/env bash

# 1. Safety Checks
set -e

# Ensure the script is being run from the root of the cardpg monorepo
if [[ ! -d "design" ]]; then
    echo "Error: This script must be run from the root of the cardpg monorepo."
    exit 1
fi

TARGET_DIR="${1:-../cardpg-design}"

# Ensure target directory exists and is a git repository
if [[ ! -d "$TARGET_DIR" || ! -d "$TARGET_DIR/.git" ]]; then
    echo "Error: Target directory '$TARGET_DIR' does not exist or is not a git repository."
    exit 1
fi

echo "Syncing design/ to $TARGET_DIR/..."

# 2. Sync Directories
rsync -rauv --delete --exclude '.git' design/ "$TARGET_DIR/"

# 3. Commit and Push
cd "$TARGET_DIR"

# Add changes
git add .

# Check for changes
if git diff-index --quiet HEAD --; then
    echo "Success: No changes to sync."
    exit 0
fi

echo "Changes detected in $TARGET_DIR, committing and pushing..."
git commit -m "chore: automatic sync from monorepo"
git push origin main

echo "Successfully synced to shadow repo."

