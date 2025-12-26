{ pkgs ? import <nixpkgs> {} }:

let
  haskellPackages = pkgs.haskellPackages.override {
    overrides = self: super: {
      cardpg-core = pkgs.haskell.lib.dontCheck (self.callCabal2nix "cardpg-core" ../cardpg-core {});
      cardpg-api = pkgs.haskell.lib.dontCheck (self.callCabal2nix "cardpg-api" ../cardpg-api {});
      
      # Simple data derivation for server usage
      game-data = pkgs.runCommand "cardpg-game-data" {} ''
        mkdir -p $out/data/scenarios
        mkdir -p $out/data/cards
        cp -r ${../data}/scenarios/* $out/data/scenarios/
        cp -r ${../data}/cards/* $out/data/cards/
      '';

      cardpg-server = pkgs.haskell.lib.overrideCabal (self.callCabal2nix "cardpg-server" ../cardpg-server {}) (old: {
        testToolDepends = (old.testToolDepends or []) ++ [ self.game-data ];
        # We need to set env vars for tests
        preCheck = ''
          export CARDPG_CARDS_DIR="${self.game-data}/data/cards"
          export CARDPG_SCENARIO_FILE="${self.game-data}/data/scenarios/starter.yaml"
        '';
        
        buildTools = (old.buildTools or []) ++ [ pkgs.makeWrapper ];
        postInstall = (old.postInstall or "") + ''
          wrapProgram $out/bin/cardpg-server \
            --set CARDPG_CARDS_DIR "${self.game-data}/data/cards" \
            --set CARDPG_SCENARIO_FILE "${self.game-data}/data/scenarios/starter.yaml"
        '';
      });
      beam-automigrate = pkgs.haskell.lib.doJailbreak (self.callCabal2nix "beam-automigrate" ../../beam-automigrate {});
    };
  };
in
  haskellPackages
