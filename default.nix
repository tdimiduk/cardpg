{ system ? builtins.currentSystem
, obelisk ? import ./.obelisk/impl {
    inherit system;
    iosSdkVersion = "13.2";

    # You must accept the Android Software Development Kit License Agreement at
    # https://developer.android.com/studio/terms in order to build Android apps.
    # Uncomment and set this to `true` to indicate your acceptance:
    # config.android_sdk.accept_license = false;

    # In order to use Let's Encrypt for HTTPS deployments you must accept
    # their terms of service at https://letsencrypt.org/repository/.
    # Uncomment and set this to `true` to indicate your acceptance:
    terms.security.acme.acceptTerms = false;
  }
}:
with obelisk;
project ./. ({ pkgs, hackGet,  ... }@args: {
  overrides = pkgs.lib.composeExtensions
    (pkgs.callPackage (hackGet ./dep/rhyolite) args).haskellOverrides
    (self: super:
      with pkgs.haskell.lib; {
        google-oauth2-jwt = self.callHackageDirect {
          pkg = "google-oauth2-jwt";
          ver = "0.3.3.1";
          sha256 = "sha256-DNAoxA455Vl14aa3jmq+KMDpy18HRSAjEh/B49Qm7HU=";
        } {  };
      }
    );
  android.applicationId = "systems.obsidian.obelisk.examples.minimal";
  android.displayName = "Obelisk Minimal Example";
  ios.bundleIdentifier = "systems.obsidian.obelisk.examples.minimal";
  ios.bundleName = "Obelisk Minimal Example";
})
