#!/usr/bin/env bash
set -e

# Configuration
SERVER_HOST="${SERVER_HOST:-tgd.me}"
ROOT_AT="${ROOT_AT:-root@tgd.me}"
SERVICE_FILE="deploy/cardpg-service.nix"
LAST_SERVICE_FILE=".deploy-cache/cardpg-service.nix.last"

# 1. Check for Key
if [ -z "$NIX_SIGNING_KEY" ]; then
  echo "Error: NIX_SIGNING_KEY must be set to deploy"
  exit 1
fi
echo "Deploying with key: $NIX_SIGNING_KEY"

# 2. Build Package
echo "Building release package..."
# Build the bundle which includes both server and frontend
# This matches the structure expected by the deployment logic
nix build .#bundle --print-build-logs
PACKAGE=$(readlink -f result)
echo "Built package: $PACKAGE"

# 3. Sign Package
echo "Signing package..."
nix store sign -r --key-file "$NIX_SIGNING_KEY" "$PACKAGE"

# 4. Copy to server
echo "Copying to server..."
nix copy --to "ssh://$ROOT_AT" --verbose "$PACKAGE"

# 5. Detect change in service file
mkdir -p "$(dirname "$LAST_SERVICE_FILE")"
CHANGED=0
if ! cmp -s "$SERVICE_FILE" "$LAST_SERVICE_FILE"; then
  CHANGED=1
fi

FORCE_REBUILD=${1:-}
SHOULD_REBUILD=0
if [ "$CHANGED" -eq 1 ] || [ "$FORCE_REBUILD" = "true" ]; then
  SHOULD_REBUILD=1
fi

# 6. Update Symlink
echo "Updating symlink..."
TARGET_LINK="/sites/cardpg.tgd.me"
ssh "$ROOT_AT" "mkdir -p /sites"
ssh "$ROOT_AT" ln -sfn "$PACKAGE" "$TARGET_LINK"

# Register GC Root
GC_ROOT="/nix/var/nix/gcroots/cardpg-live"
ssh "$ROOT_AT" ln -sfn "$TARGET_LINK" "$GC_ROOT"

if [ "$SHOULD_REBUILD" -eq 1 ]; then
  echo "Service changed or rebuild forced. Rebuilding NixOS..."
  rsync -rav "$SERVICE_FILE" "$ROOT_AT:/etc/nixos/"
  ssh "$ROOT_AT" "nixos-rebuild switch --flake /etc/nixos#tgd_me --impure"
  cp "$SERVICE_FILE" "$LAST_SERVICE_FILE"
else
  echo "Service file unchanged. Skipping nixos-rebuild."
fi

# 7. Restart Service
echo "Restarting service..."
ssh "$ROOT_AT" "systemctl restart cardpg"

# 8. Log Deployment
GITHASH=$(git rev-parse --verify HEAD)
GITMSG=$(git log -1 --pretty=%B)
echo "Deployed $GITHASH: $GITMSG"
