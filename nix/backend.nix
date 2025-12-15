{ pkgs ? import <nixpkgs> {} }:

let
  haskellPackages = pkgs.haskellPackages.override {
    overrides = self: super: {
      cardpg-core = pkgs.haskell.lib.dontCheck (self.callCabal2nix "cardpg-core" ../cardpg-core {});
      cardpg-server = pkgs.haskell.lib.justStaticExecutables (pkgs.haskell.lib.overrideCabal (self.callCabal2nix "cardpg-server" ../cardpg-server {}) (old: {
        testToolDepends = (old.testToolDepends or []) ++ [ self.game-data ];
        # We need to set env vars for tests
        preCheck = ''
          export CARDPG_CARDS_FILE="${self.game-data}/data/generated_cards.json"
          export CARDPG_SCENARIO_FILE="${self.game-data}/data/scenarios/starter.yaml"
        '';
        
        buildTools = (old.buildTools or []) ++ [ pkgs.makeWrapper ];
        postInstall = (old.postInstall or "") + ''
          wrapProgram $out/bin/cardpg-server \
            --set CARDPG_CARDS_FILE "${self.game-data}/data/generated_cards.json" \
            --set CARDPG_SCENARIO_FILE "${self.game-data}/data/scenarios/starter.yaml"
        '';
      }));
      cardpg-codegen = self.callCabal2nix "cardpg-codegen" ../tools/codegen {};
      card-compiler = self.callCabal2nix "card-compiler" ../tools/card-compiler {};
      game-data = pkgs.callPackage ./game-data.nix {
        cardCompiler = self.card-compiler;
      };
    };
  };
in
  haskellPackages
