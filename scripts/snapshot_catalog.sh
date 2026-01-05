#!/bin/bash
set -e

# ensure we are in the project root
cd "$(dirname "$0")/.."

echo "Building static catalog..."
cabal run exe:cardpg-client-reflex -- --static > /dev/null

echo "Taking screenshot..."
# --window-size width,height : Sets the initial window size.
# --screenshot=file : Saves the screenshot to the specified file.
# --headless : Runs without a visible UI.
# --hide-scrollbars : Clean screenshot.
chromium --headless --disable-gpu --hide-scrollbars --window-size=1920,2000 --screenshot=catalog.png "file://$(pwd)/catalog.html"

echo "Snapshot saved to $(pwd)/catalog.png"
