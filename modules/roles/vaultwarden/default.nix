{ config, ... }:

let
  authDomain = "auth.allie.sh";
  authentikApplication = "vaultwarden";
  domain = "vault.allie.sh";
  port = 8222;
  secretsFile = config.sops.secrets."vaultwarden/env".path;
in
{
  imports = [ ../../secrets/runtime-age.nix ];

  sops.secrets."vaultwarden/env" = {
    sopsFile = ../../../secrets/vaultwarden.yaml;
    mode = "0400";
  };

  services.vaultwarden = {
    enable = true;
    dbBackend = "sqlite";
    inherit domain;
    environmentFile = [ secretsFile ];

    config = {
      ROCKET_ADDRESS = "0.0.0.0";
      ROCKET_PORT = port;
      SIGNUPS_ALLOWED = false;
      INVITATIONS_ALLOWED = true;
      WEBSOCKET_ENABLED = true;
      ROCKET_LOG = "critical";

      # Keep password login enabled during rollout while adding Authentik OIDC.
      SSO_ENABLED = true;
      SSO_ONLY = false;
      SSO_SIGNUPS_MATCH_EMAIL = true;
      SSO_AUTHORITY = "https://${authDomain}/application/o/${authentikApplication}/";
      SSO_SCOPES = "openid profile email offline_access";
      SSO_CLIENT_ID = authentikApplication;
    };
  };

  networking.firewall = {
    allowedTCPPorts = [
      22
      port
    ];
  };
}
