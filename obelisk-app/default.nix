{ system ? builtins.currentSystem
, obelisk ? import ./.obelisk/impl {
    inherit system;
    iosSdkVersion = "13.2";

    config.android_sdk.accept_license = true;
    terms.security.acme.acceptTerms = true;
  }
}:
with obelisk;
project ./. ({ pkgs, hackGet,  ... }@args:
  let
    pythonScriptPackage = pkgs.callPackage ./python/default.nix {};
    scriptPath = "${pythonScriptPackage}/bin/sync-cards-gsheet.py";
    generatedDataDir = "generated_nix_config";
    pythonPathDataFileName = "python_script_path.txt";
    relativePathToDataFile = "${generatedDataDir}/${pythonPathDataFileName}";
  in
  {
  packages = {
    cardpg-core = ../cardpg-core;
  };
  overrides = pkgs.lib.composeExtensions
    (pkgs.callPackage (hackGet ./dep/rhyolite) args).haskellOverrides
    (self: super: with pkgs.haskell.lib; {
      reflex-gadt-api = self.callCabal2nix "reflex-gadt-api" (hackGet ./dep/reflex-gadt-api) {};
      aeson-gadt-th = doJailbreak (self.callHackageDirect {
        pkg = "aeson-gadt-th";
        ver = "0.2.5.1";
        sha256 = "sha256-pWIzmLMZ1EOgkV3D9qnVliZyhVKvPnRloUdjaYTob+Q=";
      } { });
      beam-automigrate = self.callCabal2nix "beam-automigrate" (hackGet ./dep/beam-automigrate) {};
      backend = super.backend.overrideAttrs (oldAttrs: {
        postPatch = (oldAttrs.postPatch or "") + ''
          echo "Generating Python script path data file for backend..."
          mkdir -p ./${generatedDataDir} # Create the directory in the source tree
          echo -n "${scriptPath}" > ./${relativePathToDataFile} # Use echo -n to avoid trailing newline
          echo "Generated ./${relativePathToDataFile} with content:"
          cat ./${relativePathToDataFile}
          echo "" # Newline for cleaner logs
        '';
        installPhase = (oldAttrs.installPhase or "cabalInstallPhase") + ''
          echo "adding python script"
          ln -s "${scriptPath}" $out/bin/
      '';
      });
      shells = super.shells // {
        ghc = super.shells.ghc.overrideAttrs (oldAttrs: {
          shellHook = (oldAttrs.shellHook or "") + ''
            echo "Attempting to set ${envVar} in GHC shell..."
            export ${builtins.toString envVar}=${scriptPath}
            echo "Value of ${envVar} should now be: $${envVar}"
          '';
        });
      };
    });
  android.applicationId = "systems.obsidian.obelisk.examples.minimal";
  android.displayName = "Obelisk Minimal Example";
  ios.bundleIdentifier = "systems.obsidian.obelisk.examples.minimal";
  ios.bundleName = "Obelisk Minimal Example";
})
