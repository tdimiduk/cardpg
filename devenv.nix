{ pkgs, lib, config, ... }:

{
  # https://devenv.sh/basics/
  env.GREET = "CardPG Environment";

  # https://devenv.sh/packages/
  packages = [
    pkgs.git
    pkgs.rsync
    pkgs.openssh
  ];

  # Create a persistent GC root to protect the JS cross-compiler from garbage collection
  scripts.root-ghcjs.exec = ''
    GC_ROOT="/nix/var/nix/gcroots/per-user/$USER/cardpg-ghcjs"
    mkdir -p "$(dirname "$GC_ROOT")"
    echo "Building and rooting JS cross-compiler..."
    nix build .#js-ghc -o "$GC_ROOT" --print-build-logs
    echo ""
    echo "✓ GC root created at: $GC_ROOT"
    echo "  The JS cross-compiler is now protected from garbage collection."
    echo ""
    echo "Verification:"
    ls -la "$GC_ROOT"
  '';

  languages.javascript = {
    enable = true;
    npm.enable = true;
    npm.install.enable = false;
  };

  enterShell = ''
    # Only install if node_modules is missing or outdated
    if [ -f vtt-react/package.json ]; then
      if [ ! -d vtt-react/node_modules ] || \
         [ vtt-react/package.json -nt vtt-react/node_modules ]; then
        echo "Installing frontend dependencies..."
        (cd vtt-react && npm install)
      fi
    fi

    # Warn about GC rooting for GHCJS compiler
    GC_ROOT="/nix/var/nix/gcroots/per-user/$USER/cardpg-ghcjs"
    if [ ! -L "$GC_ROOT" ]; then
      echo ""
      echo "⚠️  GHCJS cross-compiler is NOT GC-protected!"
      echo "   Run 'root-ghcjs' to prevent garbage collection."
      echo ""
    fi

    echo "${config.env.GREET}"
  '';

  # https://devenv.sh/processes/
  processes.backend.exec = "cabal run cardpg-server";
  processes.frontend.exec = "cd vtt-react && npm run dev";

  # https://devenv.sh/scripts/
  scripts.gen-types.exec = ''
    # Ensure we run from project root
    ROOT=$(git rev-parse --show-toplevel)
    cd "$ROOT"

    # Ensure target directory exists for codegen
    mkdir -p vtt-react/src/generated

    echo "Building codegen..."
    cabal build codegen
    
    # Extract binary path (robust way)
    BIN_PATH=$(cabal list-bin codegen)
    
    echo "Running codegen from $BIN_PATH..."
    $BIN_PATH vtt-react/src/generated/types.ts
    
    echo "Formatting and generating Zod schemas..."
    npm --prefix vtt-react run format
    npm --prefix vtt-react run gen:zod
  '';

  scripts.deploy-prod.exec = "./deploy/deploy-prod.sh \"$@\"";

  scripts.test-integration.exec = ''
    set -e
    echo "Starting integration tests..."
    
    # Needs generated types
    gen-types
    
    # Start server in background
    export PORT=3001
    export CARDPG_USE_IN_MEMORY_DB=true
    
    echo "Starting server on port $PORT..."
    cabal run cardpg-server &
    SERVER_PID=$!
    
    cleanup() {
      echo "Stopping server..."
      kill $SERVER_PID
    }
    trap cleanup EXIT
    
    # Wait for server to be ready
    echo "Waiting for server..."
    sleep 5
    
    echo "Running frontend integration tests..."
    npm --prefix vtt-react run test:integration
  '';

  scripts.run-client.exec = ''
    echo "Building Reflex client..."
    nix build .#reflex-client-js

    echo "Preparing distribution..."
    rm -rf client-dist
    mkdir -p client-dist

    # The output is a single node script in result/bin/exe-name
    # We need to find it, copy it, and strip the shebang
    EXE_PATH=$(find result/bin -type f | head -n 1)
    
    if [ -z "$EXE_PATH" ]; then
      echo "Error: Could not find output executable in result/bin"
      ls -R result
      exit 1
    fi

    echo "Found output at $EXE_PATH"
    
    # Remove the first line (#!/usr/bin/env node) and save as all.js
    tail -n +2 "$EXE_PATH" > client-dist/all.js

    # Generate index.html if missing
    if [ ! -f client-dist/index.html ]; then
      echo "Generating default index.html..."
      cat > client-dist/index.html <<EOF
<!DOCTYPE html>
<html>
  <head>
    <meta charset="utf-8">
    <title>CardPG Reflex Client</title>
    <script language="javascript" src="all.js" defer></script>
  </head>
  <body>
  </body>
</html>
EOF
    fi

    echo ""
    echo "Serving client at http://localhost:8000"
    echo "Press Ctrl+C to stop"
    python3 -m http.server 8000 --directory client-dist
  '';

  scripts.format.exec = ''
    pre-commit run --all-files
  '';


  # https://devenv.sh/pre-commit-hooks/
  git-hooks.hooks = {
    # Haskell
    fourmolu.enable = true;
    hlint.enable = true;
    cabal-fmt.enable = true;

    # Frontend
    prettier.enable = true;
    prettier.excludes = [ "^data/" "^design/" ];
    # Exclude generated files from prettier hook to avoid double-processing if desired,
    # or let it run. Prettier maps to the config in the repo.
  };
}
