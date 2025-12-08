{ pkgs ? import <nixpkgs> {}, codegen, cardCompiler }:

pkgs.buildNpmPackage {
  pname = "cardpg-frontend";
  version = "0.0.0";

  src = ../vtt-react;

  npmDepsHash = "sha256-rbFS+T8tmcjhXkXwy3YuRg9AxLHFzRA/hwxEh3ZpcYg="; 
  
  nativeBuildInputs = [ 
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
    
    # Use card-compiler directly (replicating Shake logic)
    # Find all yaml files in relevant directories
    # We use 'find' to get the lists, assuming simple filenames without spaces for simplicity in this build env
    yaml_files=$(find data/cards/pc data/cards/monsters data/cards/status data/cards/consequences -name "*.yaml")
    
    # Run card-compiler export-vtt
    # We pass the list of files as arguments
    ${cardCompiler}/bin/card-compiler export-vtt src/data/generated_cards.json $yaml_files
    

  '';

  installPhase = ''
    mkdir -p $out
    cp -r dist/* $out/
  '';
}
