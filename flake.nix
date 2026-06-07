{
  nixConfig = {
    extra-substituters = [
      "https://cache.iog.io"
      "https://nixcache.reflex-frp.org"
    ];
    extra-trusted-public-keys = [
      "hydra.iohk.io:f/Ea+s+dFdN+3Y/G+FDgSq+a5NEWhJGzdjvKNGv0/EQ="
      "ryantrinkle.com-1:JJiAKaRv9mWgpVAz8dwewnZe0AzzEAzPkagE9SP5NWI="
    ];
  };
  inputs = {
    haskellNix.url = "github:input-output-hk/haskell.nix";
    nixpkgs.follows = "haskellNix/nixpkgs-unstable";
    hackage = {
      url = "github:input-output-hk/hackage.nix";
      flake = false;
    };
    stackage = {
      url = "github:input-output-hk/stackage.nix";
      flake = false;
    };
    pre-commit-hooks.url = "github:cachix/git-hooks.nix";
  };

  outputs = inputs@{ flake-parts, ... }:
    flake-parts.lib.mkFlake { inherit inputs; } {
      imports = [ inputs.pre-commit-hooks.flakeModule ];
      systems = [ "x86_64-linux" "aarch64-linux" "aarch64-darwin" "x86_64-darwin" ];

      perSystem = { config, self', pkgs, system, ... }:
        let
          # Haskell.nix pkgs
          hpkgs = import inputs.nixpkgs {
            inherit system;
            overlays = [ inputs.haskellNix.overlay ];
            inherit (inputs.haskellNix) config;
          };

          # Shared project configuration
          # We clean git tracked files and apply a custom source filter to prevent non-Haskell files 
          # (like templates, static assets, docs, and notes) from invalidating the Nix build cache.
          projectSrc = pkgs.lib.cleanSourceWith {
            src = hpkgs.haskell-nix.haskellLib.cleanGit {
              name = "cardpg";
              src = ./.;
            };
            filter = name: type:
              let baseName = baseNameOf name; in
              # Exclude directories that do not contain code compiled by Nix/cabal
              !(type == "directory" && (
                baseName == "docs" ||
                baseName == "design" ||
                baseName == "deploy" ||
                baseName == "static" ||
                baseName == "tests" ||
                baseName == "vtt-react" ||
                baseName == ".agent"
              )) &&
              # Exclude flake files to prevent re-evaluation compilation of the dev shell
              !(baseName == "flake.nix" || baseName == "flake.lock" || baseName == "README.md");
          };

          # SHA256 hashes for git dependencies in cabal.project
          commonSha256map = {
            "https://github.com/obsidiansystems/beam-automigrate.git"."3933b82b8affc1192638ab84fd3844991195b9cc" =
              "0fhwh5cy8h2z6mhkklym09njpw2mgz3ljg1pwp8gyfc46ksf2hrs";
            "https://github.com/reflex-frp/reflex-dom.git"."97f08ae82335b9645ffd9ca89bf1187033265a9f" =
              "0ryba2jpflh0hlq23sn53d95dyxjdbhdjj63vaj5qzbln0rrg023";
            "https://github.com/ghcjs/jsaddle.git"."0fb7260ad02592546c9f180078d770256fb1f0f6" =
              "0hcfyii6s7qb67rp2ixklk5n18lpl558fzm5gx5cd1hzjkxyaiar";
            "https://github.com/reflex-frp/reflex-gadt-api.git"."45dcf247ba90490bd1d88c7a714a156e2051f109" =
              "1hil1vlm6cs4lbdxwgb3av8568zv2x752xcb5p087sb28ik6j88b";
          };

          # Pin hackage/stackage inputs for reproducibility
          commonInputMap = {
            "https://input-output-hk.github.io/hackage.nix" = inputs.hackage;
            "https://input-output-hk.github.io/stackage.nix" = inputs.stackage;
          };

          # Helper to create haskell.nix projects with shared config
          mkProject = hpkgs': hpkgs'.haskell-nix.project {
            src = projectSrc;
            compiler-nix-name = "ghc9122";
            sha256map = commonSha256map;
            inputMap = commonInputMap;
            modules = [{
              # Enable parallel compilation for all local packages
              packages = {
                core.ghcOptions = [ "-j" "+RTS" "-A128m" "-n4m" "-RTS" "-fexpose-all-unfoldings" "-fspecialise-aggressively" ];
                api.ghcOptions = [ "-j" "+RTS" "-A128m" "-n4m" "-RTS" "-fexpose-all-unfoldings" ];
                server.ghcOptions = [ "-j" "+RTS" "-A128m" "-n4m" "-RTS" ];
                client-reflex.ghcOptions = [ "-j" "+RTS" "-A128m" "-n4m" "-RTS" "-O2" "-fexpose-all-unfoldings" "-fspecialise-aggressively" ];
              };
            }];
          };

          # Native project (for server, tools, native reflex client)
          project = mkProject hpkgs;

          # JavaScript cross-compilation project (for web frontend)
          # Note: GHC 9.12 GHCJS is not in public caches - run `root-ghcjs` after first build
          projectJS = mkProject hpkgs.pkgsCross.ghcjs;

        in
        {

          # Formatter for `nix fmt` - only formats main project files
          # (excludes generated .devenv.flake.nix and scratch/)
          formatter = pkgs.writeShellScriptBin "nixpkgs-fmt" ''
            ${pkgs.nixpkgs-fmt}/bin/nixpkgs-fmt \
              flake.nix \
              deploy/*.nix \
              tools/*.nix \
              "$@"
          '';

          # Checks for CI (`nix flake check`)
          checks = {
            # Uncomment when tests are stable:
            # core-test = project.core.checks.core-test;
            # server-test = project.server.checks.server-test;
          };

          # Deployable Packages
          packages = {
            default = self'.packages.cardpg-server-wrapped;

            # Raw server executable from haskell.nix
            cardpg-server-raw = project.server.components.exes.server;

            # Reflex Client (Native)
            reflex-client-native = project.client-reflex.components.exes.client-reflex;

            # Reflex Client (JS) 
            reflex-client-js = projectJS.client-reflex.components.exes.client-reflex;

            # Production bundle for Reflex Client (JS + CSS + HTML)
            reflex-client-prod = pkgs.runCommand "reflex-client-prod" { } ''
              mkdir -p $out
              
              # Copy JS and strip shebang
              tail -n +2 ${self'.packages.reflex-client-js}/bin/client-reflex > $out/all.js
              
              # Copy static assets
              cp -r ${./client-reflex/static}/* $out/ || true
              
              # Generate atomic.css dynamically using gen-css
              mkdir -p temp
              cd temp
              cp -r ${./client-reflex} ./client-reflex
              chmod -R +w ./client-reflex
              ${project.client-reflex.components.exes.gen-css}/bin/gen-css
              cp client-reflex/static/atomic.css $out/atomic.css
            '';


            # GHC JS cross-compiler - run `root-ghcjs` to protect from GC
            js-ghc = projectJS.pkg-set.config.ghc.package;

            # Wrapped server with data paths
            cardpg-server-wrapped = pkgs.runCommand "cardpg-server"
              {
                buildInputs = [ pkgs.makeWrapper ];
              } ''
              mkdir -p $out/bin
              cp ${self'.packages.cardpg-server-raw}/bin/server $out/bin/cardpg-server
             
              wrapProgram $out/bin/cardpg-server \
                --set CARDPG_CARDS_DIR "${self'.packages.game-data}/data/cards" \
                --set CARDPG_SCENARIO_FILE "${self'.packages.game-data}/data/scenarios/starter.yaml"
            '';

            game-data = pkgs.runCommand "cardpg-game-data" { } ''
              mkdir -p $out/data/scenarios
              mkdir -p $out/data/cards
              cp -r ${./data}/scenarios/* $out/data/scenarios/
              cp -r ${./data}/cards/* $out/data/cards/
            '';


          };

          # Pre-commit hooks configuration
          pre-commit.settings = {
            excludes = [
              "data/cards/.*"
              "design/research/reports/.*"
            ];
            hooks = {
              fourmolu.enable = true;
              hlint.enable = true;
              cabal-fmt.enable = true;
              prettier.enable = true;
              shellcheck.enable = true;
              nixpkgs-fmt.enable = true;
              deadnix.enable = true;
              statix.enable = true;
            };
          };

          # Development shell using haskell.nix - guarantees correct GHC 9.12
          devShells.default = project.shellFor {
            name = "cardpg-dev";

            packages = p: [
              p.core
              p.server
              p.api
              p.client-reflex
            ];

            withHoogle = false;

            # Tools built with the project's GHC
            tools = {
              cabal = "latest";
              haskell-language-server = "latest";
              hlint = "latest";
              fourmolu = "latest";
              ghcid = "latest";
              apply-refact = "latest";
              weeder = "latest";
              hoogle = "latest";
            };

            # Additional packages from nixpkgs (not GHC-dependent)
            buildInputs = [
              pkgs.process-compose
              pkgs.haskellPackages.cabal-fmt # cabal-fmt doesn't support GHC 9.12 yet
              pkgs.nodejs
              pkgs.git
              pkgs.rsync
              pkgs.openssh
              pkgs.python3 # for run-client http server
              pkgs.ghciwatch
              pkgs.caddy
              pkgs.postgresql
              pkgs.pkg-config
              config.pre-commit.settings.package # pre-commit hooks
            ] ++ pkgs.lib.optionals pkgs.stdenv.isLinux [
              pkgs.playwright-test
            ];

            # Development shell setup
            shellHook = ''
              echo "CardPG Development Shell (GHC 9.12)"
              
              # Add project scripts to PATH
              export PATH="$PWD/scripts:$PATH"
              
              # Install pre-commit hooks
              ${config.pre-commit.settings.installationScript}
              


              # npm install if needed for client-reflex (Browser Sync)
              if [ -f client-reflex/package.json ]; then
                if [ ! -d client-reflex/node_modules ] || \
                   [ client-reflex/package.json -nt client-reflex/node_modules ]; then
                  echo "Installing client-reflex dependencies..."
                  (cd client-reflex && npm install)
                fi
              fi

              # Warn about GC rooting for GHCJS compiler
              GC_ROOT="/nix/var/nix/gcroots/per-user/$USER/cardpg-ghcjs"
              if [ ! -L "$GC_ROOT" ]; then
                echo ""
                echo "⚠️  GHCJS cross-compiler is NOT GC-protected!"
                echo "   Run: root-ghcjs"
                echo ""
              fi

              echo ""
              echo "Available commands: gen-types, deploy-prod, run-client, root-ghcjs, hoogle"

              # Playwright Configuration
              ${pkgs.lib.optionalString pkgs.stdenv.isLinux ''
              export PLAYWRIGHT_BROWSERS_PATH="${pkgs.playwright-driver.browsers}"
              export PLAYWRIGHT_SKIP_BROWSER_DOWNLOAD=1
              ''}
            '';
          };
        };
    };
}
