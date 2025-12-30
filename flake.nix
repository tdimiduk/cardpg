{
  nixConfig = {
    extra-substituters = [
      "https://cache.iog.io"
    ];
    extra-trusted-public-keys = [
      "hydra.iohk.io:f/Ea+s+dFdN+3Y/G+FDgSq+a5NEWhJGzdjvKNGv0/EQ="
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

          project = hpkgs.haskell-nix.project {
            src = hpkgs.haskell-nix.haskellLib.cleanGit {
              name = "cardpg";
              src = ./.;
            };
            compiler-nix-name = "ghc9103";
            
            sha256map = {
              "https://github.com/obsidiansystems/beam-automigrate.git" = {
                "3933b82b8affc1192638ab84fd3844991195b9cc" = "0fhwh5cy8h2z6mhkklym09njpw2mgz3ljg1pwp8gyfc46ksf2hrs";
              };
            };

            # Module overrides if needed
            modules = [{
              # Example: fix broken dependencies if any
            }];

            inputMap = {
               "https://input-output-hk.github.io/hackage.nix" = inputs.hackage;
               "https://input-output-hk.github.io/stackage.nix" = inputs.stackage;
            };
          };

        in {
       
        # Deployable Packages
        packages = {
          default = self'.packages.cardpg-server-wrapped;
          
          # Raw server executable from haskell.nix
          cardpg-server-raw = project.cardpg-server.components.exes.cardpg-server;

          # Reflex Client (Native)
          reflex-client-native = project.cardpg-client-reflex.components.exes.cardpg-client-reflex;

          # Wrapped server with data paths
          cardpg-server-wrapped = pkgs.runCommand "cardpg-server" {
             buildInputs = [ pkgs.makeWrapper ];
          } ''
             mkdir -p $out/bin
             cp ${self'.packages.cardpg-server-raw}/bin/cardpg-server $out/bin/
             
             wrapProgram $out/bin/cardpg-server \
               --set CARDPG_CARDS_DIR "${self'.packages.game-data}/data/cards" \
               --set CARDPG_SCENARIO_FILE "${self'.packages.game-data}/data/scenarios/starter.yaml"
          '';
          
          game-data = pkgs.runCommand "cardpg-game-data" {} ''
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

          bundle = pkgs.runCommand "cardpg-release" {} ''
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
            project.tool "cabal" "latest"
            project.tool "haskell-language-server" "latest"
            project.tool "hlint" "latest"
            project.tool "fourmolu" "latest"
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
