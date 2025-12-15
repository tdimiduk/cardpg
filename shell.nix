{ pkgs ? import <nixpkgs> {} }:

let
  backendPkgs = import ./nix/backend.nix { inherit pkgs; };
in
backendPkgs.shellFor {
  packages = p: [
    p.cardpg-core
    p.cardpg-server
    p.cardpg-codegen
    p.card-compiler
  ];

  buildInputs = with pkgs; [
    # Haskell tools
    cabal-install
    haskell-language-server
    hlint
    fourmolu

    # Python environment
    (python313.withPackages (ps: with ps; [
      ipython
      pyyaml
      google-genai
      gspread
    ]))
    uv
    ruff

    # JS/TS environment
    nodejs

    # Task runner
    just
    
    # System Libs
    postgresql
  ];

  # Enables Hoogle for the packages in the shell
  withHoogle = true;
}
