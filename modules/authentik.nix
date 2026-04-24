{ config, lib, pkgs, ... }:

let
  domain = "auth.allie.sh";
  listenPort = 9000;

  # Create this manually for now:
  # sudo mkdir -p /var/lib/secrets
  # sudo openssl rand -base64 60 | sudo tee /var/lib/secrets/authentik-env
  # sudo chmod 600 /var/lib/secrets/authentik-env
  #
  # Then edit the file so it contains:
  # AUTHENTIK_SECRET_KEY=<generated-secret>
  envFile = "/var/lib/secrets/authentik-env";
in
{
  services.authentik = {
    enable = true;

    environmentFile = envFile;

    settings = {
      disable_startup_analytics = true;
      avatars = "initials";

      web = {
        path = "https://${domain}/";
      };
    };
  };

  services.redis.servers.authentik = {
    enable = true;
  };

  services.postgresql = {
    enable = true;

    ensureDatabases = [
      "authentik"
    ];

    ensureUsers = [
      {
        name = "authentik";
        ensureDBOwnership = true;
      }
    ];
  };

  networking.firewall = {
    enable = true;

    # Expose only to your reverse proxy / internal LAN.
    allowedTCPPorts = [
      listenPort
    ];
  };

  environment.systemPackages = with pkgs; [
    authentik
    postgresql
    redis
  ];
}