{ pkgs ? import <nixpkgs> {}, codegen, gameData }:

pkgs.buildNpmPackage {
  pname = "cardpg-frontend";
  version = "0.0.0";

  src = ../vtt-react;

  npmDepsHash = "sha256-rbFS+T8tmcjhXkXwy3YuRg9AxLHFzRA/hwxEh3ZpcYg="; 
  
  nativeBuildInputs = [ 
    codegen
    codegen
    gameData
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
    
    # Copy from gameData
    mkdir -p src/data
    cp ${gameData}/data/generated_cards.json src/data/generated_cards.json
  '';

  installPhase = ''
    mkdir -p $out
    cp -r dist/* $out/
  '';
}
