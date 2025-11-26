{ pkgs ? import <nixpkgs> {} }:

with pkgs;

mkShell {
  buildInputs = [
    pkgs.python313
    pkgs.uv
    pkgs.ruff
    pkgs.python313Packages.ipython
  ];
}
