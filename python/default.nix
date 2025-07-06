{ pkgs? import <nixpkgs> {},  }:
let
  pythonEnv = pkgs.python310.withPackages (ps: [
    ps.gspread
  ]);
in
pkgs.stdenv.mkDerivation {
  name = "cardpg-gsheets-python-env";
  version = "0.1.0";
  src = ./.;
  buildInputs = [ pythonEnv ];
  installPhase = ''
    mkdir -p $out/bin
    cp sync-cards-gsheet.py $out/bin/
    chmod +x $out/bin/sync-cards-gsheet.py
    patchShebangs $out/bin/sync-cards-gsheet.py
  '';
  makeWrapperArgs = [
    "--prefix" "PATH" ":" "{${pkgs.lib.makeBinPath [ pythonEnv ]}}"
  ];
}
