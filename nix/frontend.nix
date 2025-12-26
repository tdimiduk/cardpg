{ pkgs ? import <nixpkgs> {}, codegen }:

pkgs.buildNpmPackage {
  pname = "cardpg-frontend";
  version = "0.0.0";

  src = ../vtt-react;

  npmDepsHash = "sha256-4ngCSqVZZYHpWKG9S1WmeIE+oB2uECVuqQYb0eYvDNc="; 
  
  nativeBuildInputs = [ 
    codegen
  ];

  preBuild = ''
    # Copy design into the build directory so generation scripts work
    # We do this in preBuild to ensure they are present in the current working directory
    cp -r ${../design} design
    chmod -R u+w design

    # Patch App.tsx to point to the correct design directory location in the build environment
    # In dev: ../../../design (repo root sibling)
    # In nix build: ../design (build root sibling)
    substituteInPlace src/App.tsx \
      --replace-fail "../../../design" "../design"

    # Generate Types
    echo "Generating types..."
    ${codegen}/bin/codegen $(pwd)/src/generated/types.ts
    
    # We need to run ts-to-zod. It should be in node_modules/.bin
    ./node_modules/.bin/ts-to-zod src/generated/types.ts src/generated/schemas.ts --skipValidation
    
  '';

  installPhase = ''
    mkdir -p $out
    cp -r dist/* $out/
  '';
}
