{ pkgs, cardCompiler }:

pkgs.runCommand "cardpg-game-data" {
  buildInputs = [ cardCompiler ];
} ''
  mkdir -p $out/data/scenarios
  mkdir -p $out/data/cards
  
  # Copy scenarios and cards
  cp -r ${../data}/scenarios/* $out/data/scenarios/
  cp -r ${../data}/cards/* $out/data/cards/

  # Generate cards
  # We need to find all yaml files in the data directory and pass them to the compiler
  # The compiler expects paths to exist
  
  # Copy data to a writable temp dir so we can run the compiler against it if needed,
  # though card-compiler takes input files as args.
  # Let's verify what inputs card-compiler expects.
  # Based on frontend.nix:
  # card-compiler export-vtt src/data/generated_cards.json $yaml_files
  
  # We should use the raw source files from ../data
  # But we need to construct the list of files.
  
  # Find all relevant yaml files in the nix store path for ../data
  # We filter for specific variants as seen in frontend.nix
  DATA_DIR="${../data}"
  
  # Note: 'find' will output absolute store paths
  PC_CARDS=$(find $DATA_DIR/cards/pc -name "*.yaml")
  MONSTER_CARDS=$(find $DATA_DIR/cards/monsters -name "*.yaml")
  STATUS_CARDS=$(find $DATA_DIR/cards/status -name "*.yaml")
  CONSEQUENCE_CARDS=$(find $DATA_DIR/cards/consequences -name "*.yaml")
  
  ALL_CARDS="$PC_CARDS $MONSTER_CARDS $STATUS_CARDS $CONSEQUENCE_CARDS"
  
  echo "Generating VTT export..."
  card-compiler export-vtt $out/data/generated_cards.json $ALL_CARDS
''
