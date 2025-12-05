{ pkgs ? import <nixpkgs> {}, codegen, cardCompiler }:

pkgs.buildNpmPackage {
  pname = "cardpg-frontend";
  version = "0.0.0";

  src = ../vtt-react;

  npmDepsHash = "sha256-FDFgAZgc7fRDOr8CR+bXC1zYpt5GBR8gi3d5QvINT6M=";

  nativeBuildInputs = [ 
    pkgs.python3
    pkgs.python3Packages.pyyaml
    codegen
    cardCompiler
  ];

  preBuild = ''
    # Copy tools, data, and design into the build directory so generation scripts work
    # We do this in preBuild to ensure they are present in the current working directory
    cp -r ${../tools} tools
    cp -r ${../data} data
    cp -r ${../design} design
    chmod -R u+w tools data design

    # Generate Types
    echo "Generating types..."
    ${codegen}/bin/codegen $(pwd)/src/generated/types.ts
    
    # We need to run ts-to-zod. It should be in node_modules/.bin
    ./node_modules/.bin/ts-to-zod src/generated/types.ts src/generated/schemas.ts --skipValidation
    
    # Generate Data
    echo "Generating data..."
    cd tools
    
    # Patch run_pipeline.py to use card-compiler directly and fix output path
    substituteInPlace run_pipeline.py \
      --replace '["cabal", "run", "card-compiler", "--",' '["${cardCompiler}/bin/card-compiler",' \
      --replace '["cabal", "run", "card-compiler", "--", "export-vtt",' '["${cardCompiler}/bin/card-compiler", "export-vtt",' \
      --replace '"vtt-react/src/data/generated_cards.json"' '"src/data/generated_cards.json"'
    
    # Run pipeline
    python3 run_pipeline.py --skip-sync
    
    cd ..
  '';

  installPhase = ''
    mkdir -p $out
    cp -r dist/* $out/
  '';
}
