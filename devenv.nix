{ pkgs, lib, config, ... }:

{
  # https://devenv.sh/basics/
  env.GREET = "CardPG Environment";

  # https://devenv.sh/packages/
  languages.haskell = {
    enable = true;
    package = pkgs.haskell.compiler.ghc9103;
  };

  packages = [
    pkgs.git
    pkgs.cabal-install
    pkgs.haskell-language-server
    pkgs.hlint
    pkgs.fourmolu
    pkgs.haskellPackages.cabal-fmt
  ];

  languages.javascript = {
    enable = true;
    npm.enable = true;
    npm.install.enable = true;
  };

  # https://devenv.sh/processes/
  processes.backend.exec = "cabal run cardpg-server";
  processes.frontend.exec = "cd vtt-react && npm run dev";

  # https://devenv.sh/scripts/
  scripts.gen-types.exec = ''
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

  scripts.deploy-prod.exec = ''
    set -e
    
    # Configuration
    SERVER_HOST="tgd.me"
    ROOT_AT="root@tgd.me"
    SERVICE_FILE="deploy/cardpg-service.nix"
    LAST_SERVICE_FILE=".devenv/state/deploy/cardpg-service.nix.last"
    
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
    
    FORCE_REBUILD=''${1:-}
    SHOULD_REBUILD=0
    if [ "$CHANGED" -eq 1 ] || [ "$FORCE_REBUILD" = "true" ]; then
      SHOULD_REBUILD=1
    fi
    
    # 6. Update Symlink
    echo "Updating symlink..."
    TARGET_LINK="/sites/cardpg.tgd.me"
    ssh "$ROOT_AT" "mkdir -p /sites"
    ssh "$ROOT_AT" "ln -sfn $PACKAGE $TARGET_LINK"
    
    # Register GC Root
    GC_ROOT="/nix/var/nix/gcroots/cardpg-live"
    ssh "$ROOT_AT" "ln -sfn $TARGET_LINK $GC_ROOT"
    
    if [ "$SHOULD_REBUILD" -eq 1 ]; then
      echo "Service changed or rebuild forced. Rebuilding NixOS..."
      rsync -rav "$SERVICE_FILE" "$ROOT_AT:/etc/nixos/"
      ssh "$ROOT_AT" "nixos-rebuild switch"
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
  '';

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
