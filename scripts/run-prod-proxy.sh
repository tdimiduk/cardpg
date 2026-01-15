#!/usr/bin/env bash
set -e

if [ ! -d "result" ]; then
    echo "Error: ./result directory not found. Please run 'nix build .#reflex-client-prod' first."
    exit 1
fi

echo "Starting Caddy proxy on port 3000..."
echo "Serving static files from ./result"
echo "Proxying /api/* to localhost:3001"
echo ""

caddy run
