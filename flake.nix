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
    devenv.url = "github:cachix/devenv/v1.11.2";
  };

  outputs = inputs@{ flake-parts, ... }:
    flake-parts.lib.mkFlake { inherit inputs; } {
      imports = [ inputs.devenv.flakeModule ];
      systems = [ "x86_64-linux" ];

      perSystem = { config, self', inputs', pkgs, system, ... }:
        let
          # Haskell.nix pkgs
          hpkgs = import inputs.nixpkgs {
            inherit system;
            overlays = [ inputs.haskellNix.overlay ];
            config = inputs.haskellNix.config;
          };

          # Shared project configuration
          projectSrc = hpkgs.haskell-nix.haskellLib.cleanGit {
            name = "cardpg";
            src = ./.;
          };

          # SHA256 hashes for git dependencies in cabal.project
          commonSha256map = {
            "https://github.com/obsidiansystems/beam-automigrate.git"."3933b82b8affc1192638ab84fd3844991195b9cc" =
              "0fhwh5cy8h2z6mhkklym09njpw2mgz3ljg1pwp8gyfc46ksf2hrs";
            "https://github.com/reflex-frp/reflex-dom.git"."97f08ae82335b9645ffd9ca89bf1187033265a9f" =
              "0ryba2jpflh0hlq23sn53d95dyxjdbhdjj63vaj5qzbln0rrg023";
            "https://github.com/ghcjs/jsaddle.git"."0fb7260ad02592546c9f180078d770256fb1f0f6" =
              "0hcfyii6s7qb67rp2ixklk5n18lpl558fzm5gx5cd1hzjkxyaiar";
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
            modules = [{ }]; # Placeholder for future overrides
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
              devenv.nix \
              deploy/*.nix \
              tools/*.nix \
              "$@"
          '';

          # Checks for CI (`nix flake check`)
          checks = {
            # Uncomment when tests are stable:
            # cardpg-core-test = project.cardpg-core.checks.cardpg-core-test;
            # cardpg-server-test = project.cardpg-server.checks.cardpg-server-test;
          };

          # Deployable Packages
          packages = {
            default = self'.packages.cardpg-server-wrapped;

            # Raw server executable from haskell.nix
            cardpg-server-raw = project.cardpg-server.components.exes.cardpg-server;

            # Reflex Client (Native)
            reflex-client-native = project.cardpg-client-reflex.components.exes.cardpg-client-reflex;

            # Reflex Client (JS) 
            reflex-client-js = projectJS.cardpg-client-reflex.components.exes.cardpg-client-reflex;

            # GHC JS cross-compiler - run `root-ghcjs` to protect from GC
            js-ghc = projectJS.pkg-set.config.ghc.package;

            # Wrapped server with data paths
            cardpg-server-wrapped = pkgs.runCommand "cardpg-server"
              {
                buildInputs = [ pkgs.makeWrapper ];
              } ''
              mkdir -p $out/bin
              cp ${self'.packages.cardpg-server-raw}/bin/cardpg-server $out/bin/
             
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

            frontend = pkgs.buildNpmPackage {
              pname = "cardpg-frontend";
              version = "0.0.0";
              src = ./vtt-react;
              npmDepsHash = "sha256-4ngCSqVZZYHpWKG9S1WmeIE+oB2uECVuqQYb0eYvDNc=";

              # Use the project's executable for codegen
              nativeBuildInputs = [ project.cardpg-api.components.exes.codegen ];

              preBuild = ''
                cp -r ${./design} design
                chmod -R u+w design
                substituteInPlace src/App.tsx --replace-fail "../../../design" "../design"
              
                echo "Generating types..."
                mkdir -p src/generated
                codegen $(pwd)/src/generated/types.ts
                ./node_modules/.bin/ts-to-zod src/generated/types.ts src/generated/types.zod.ts --skipValidation
              '';

              installPhase = "mkdir -p $out && cp -r dist/* $out/";
            };

            bundle = pkgs.runCommand "cardpg-release" { } ''
              mkdir -p $out/backend/bin
              mkdir -p $out/frontend

              cp ${self'.packages.default}/bin/cardpg-server $out/backend/bin/
              cp -r ${self'.packages.frontend}/* $out/frontend/
            '';
          };

          devenv.shells.default = {
            imports = [ ./devenv.nix ];

            # Inject project tools
            packages = [
              project.tool
              "cabal"
              "latest"
              project.tool
              "haskell-language-server"
              "latest"
              project.tool
              "hlint"
              "latest"
              project.tool
              "fourmolu"
              "latest"
              pkgs.haskellPackages.cabal-fmt
            ];

            # Disable default haskell to avoid GHC conflict, we use the one from project
            languages.haskell.enable = false;

            # Fix for "devenv was not able to determine the current directory"
            devenv.root = let src = ./.; in toString src;
          };
        };
    };
}
