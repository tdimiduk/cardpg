{ config, lib, pkgs, ... }:

with lib;

{
  options.services.cardpg = {
    enable = mkEnableOption "Enable CardPG service";

    port = mkOption {
      type = types.port;
      default = 8080;
      description = "The port CardPG service should listen on";
    };
  };

  config = mkIf config.services.cardpg.enable {
    users.users.cardpg = {
      group = "web_users";
      home = "/home/cardpg";
      isSystemUser = true;
    };
    # web_users group is assumed to exist on the shared server (defined in groupeng.nix)

    services.nginx = {
      virtualHosts = {
        "cardpg.tgd.me" = {
          forceSSL = true;
          enableACME = true;
          locations."/" = {
            root = "/sites/cardpg.tgd.me/frontend";
            tryFiles = "$uri $uri/ /index.html";
          };
          locations."/api" = {
            proxyPass = "http://127.0.0.1:${toString config.services.cardpg.port}";
            proxyWebsockets = true;
          };
        };
      };
    };

    systemd.services.cardpg = {
      after = [ "network.target" "postgresql.service" ];
      wantedBy = [ "multi-user.target" ];

      serviceConfig = {
        User = "cardpg";
        Restart = "on-failure";
        # LoadCredential = [
        #   "db-password:/run/keys/cardpg-db-password"
        #   "app-secret:/run/keys/cardpg-app-secret"
        # ];
      };

      environment = {
        PORT = toString config.services.cardpg.port;
      };

      script = ''
        /sites/cardpg.tgd.me/backend/bin/cardpg-server
      '';
    };
  };
}
