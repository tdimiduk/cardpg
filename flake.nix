{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    devenv.url = "github:cachix/devenv/v1.11.2";
    beam-automigrate = {
      url = "github:obsidiansystems/beam-automigrate";
      flake = false;
    };
  };

  outputs = inputs@{ flake-parts, beam-automigrate, ... }:
    flake-parts.lib.mkFlake { inherit inputs; } {
      imports = [ inputs.devenv.flakeModule ];
      systems = [ "x86_64-linux" "aarch64-darwin" "x86_64-darwin" ];

      perSystem = { config, self', inputs', pkgs, system, ... }:
        let
          # Haskell Overlay
          haskellOverlay = self: super: {
            # Use specific GHC version
            haskell = super.haskell // {
              packages = super.haskell.packages // {
                ghc9103 = super.haskell.packages.ghc9103.override {
                  overrides = hfinal: hprev: {
                    # Project Packages
                    cardpg-core = pkgs.haskell.lib.dontCheck (hfinal.callCabal2nix "cardpg-core" ./cardpg-core {});
                    cardpg-api = pkgs.haskell.lib.dontCheck (hfinal.callCabal2nix "cardpg-api" ./cardpg-api {});

                    # Beam Automigrate from Input
                    beam-automigrate = pkgs.haskell.lib.doJailbreak (hfinal.callCabal2nix "beam-automigrate" beam-automigrate {});

                    # Game Data Wrapper
                    cardpg-server = pkgs.haskell.lib.overrideCabal (hfinal.callCabal2nix "cardpg-server" ./cardpg-server {}) (old: {
                      testToolDepends = (old.testToolDepends or []) ++ [ self'.packages.game-data ];
                      preCheck = ''
                        export CARDPG_CARDS_DIR="${self'.packages.game-data}/data/cards"
                        export CARDPG_SCENARIO_FILE="${self'.packages.game-data}/data/scenarios/starter.yaml"
                      '';
                      buildTools = (old.buildTools or []) ++ [ pkgs.makeWrapper ];
                      postInstall = (old.postInstall or "") + ''
                         wrapProgram $out/bin/cardpg-server \
                           --set CARDPG_CARDS_DIR "${self'.packages.game-data}/data/cards" \
                           --set CARDPG_SCENARIO_FILE "${self'.packages.game-data}/data/scenarios/starter.yaml"
                      '';
                    });
                  };
                };
              };
            };
          };

          _pkgs = import inputs.nixpkgs {
             inherit system;
             overlays = [ haskellOverlay ];
          };
          
          hsPkgs = _pkgs.haskell.packages.ghc9103;

        in {
        
        # Deployable Packages
        packages = {
          default = pkgs.haskell.lib.justStaticExecutables hsPkgs.cardpg-server;
          
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
            
            nativeBuildInputs = [ hsPkgs.cardpg-api ]; # Logic for codegen

            preBuild = ''
              cp -r ${./design} design
              chmod -R u+w design
              substituteInPlace src/App.tsx --replace-fail "../../../design" "../design"
              
              echo "Generating types..."
              mkdir -p src/generated
              ${hsPkgs.cardpg-api}/bin/codegen $(pwd)/src/generated/types.ts
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
        };
      };
    };
}
