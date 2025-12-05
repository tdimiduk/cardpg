{ pkgs ? import <nixpkgs> {} }:

let
  haskellPackages = pkgs.haskellPackages.override {
    overrides = self: super: {
      cardpg-core = pkgs.haskell.lib.dontCheck (self.callCabal2nix "cardpg-core" ../cardpg-core {});
      cardpg-server = self.callCabal2nix "cardpg-server" ../cardpg-server {};
      cardpg-codegen = self.callCabal2nix "cardpg-codegen" ../tools/codegen {};
      card-compiler = self.callCabal2nix "card-compiler" ../tools/card-compiler {};
    };
  };
in
  haskellPackages
