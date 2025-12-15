{ pkgs ? import <nixpkgs> {} }:

let
  backendPkgs = import ./nix/backend.nix { inherit pkgs; };
  frontend = import ./nix/frontend.nix { 
    inherit pkgs; 
    codegen = backendPkgs.cardpg-codegen;
    gameData = backendPkgs.game-data;
  };
in
  pkgs.runCommand "cardpg-release" {} ''
    mkdir -p $out/backend/bin
    mkdir -p $out/frontend

    cp ${backendPkgs.cardpg-server}/bin/cardpg-server $out/backend/bin/
    cp -r ${frontend}/* $out/frontend/
  ''
