{ config, lib, ... }:

let
  cfg = config.scylla.roles.vaultwarden;
  roleLib = import ../lib.nix { inherit config lib; };
  secretsFile = config.sops.secrets."vaultwarden/env".path;
in
{
  options.scylla.roles.vaultwarden = {
    enable = lib.mkEnableOption "the Vaultwarden workload";

    domain = lib.mkOption {
      type = lib.types.nonEmptyStr;
      default = "vault.allie.sh";
      description = "Public Vaultwarden domain.";
    };

    listenAddress = lib.mkOption {
      type = lib.types.nonEmptyStr;
      default = "0.0.0.0";
      description = "Address on which Vaultwarden listens.";
    };

    port = lib.mkOption {
      type = lib.types.port;
      default = 8222;
      description = "Vaultwarden HTTP port.";
    };

    oidcIssuer = lib.mkOption {
      type = lib.types.nonEmptyStr;
      default = "https://auth.allie.sh/application/o/vaultwarden/";
      description = "OIDC issuer used for Vaultwarden SSO.";
    };

    oidcClientId = lib.mkOption {
      type = lib.types.nonEmptyStr;
      default = "vaultwarden";
      description = "OIDC client identifier.";
    };

    openFirewall = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Whether to allow the Vaultwarden port through the firewall.";
    };

    permittedSources = roleLib.permittedSourcesOption;

    secretFile = lib.mkOption {
      type = lib.types.path;
      default = ../../../secrets/vaultwarden.yaml;
      description = "SOPS file containing the Vaultwarden environment.";
    };
  };

  config = lib.mkIf cfg.enable (
    lib.mkMerge [
      {
        assertions = [
          {
            assertion = builtins.pathExists cfg.secretFile;
            message = "The Vaultwarden role secret file does not exist.";
          }
        ];

        sops.age = {
          keyFile = "/var/lib/sops-nix/age-key.txt";
          generateKey = false;
        };

        sops.secrets."vaultwarden/env" = {
          sopsFile = cfg.secretFile;
          mode = "0400";
          restartUnits = [ "vaultwarden.service" ];
        };

        services.vaultwarden = {
          enable = true;
          dbBackend = "sqlite";
          domain = cfg.domain;
          environmentFile = [ secretsFile ];

          config = {
            ROCKET_ADDRESS = cfg.listenAddress;
            ROCKET_PORT = cfg.port;
            SIGNUPS_ALLOWED = false;
            INVITATIONS_ALLOWED = true;
            WEBSOCKET_ENABLED = true;
            ROCKET_LOG = "critical";

            # Keep password login enabled during rollout while adding OIDC.
            SSO_ENABLED = true;
            SSO_ONLY = false;
            SSO_SIGNUPS_MATCH_EMAIL = true;
            SSO_AUTHORITY = cfg.oidcIssuer;
            SSO_SCOPES = "openid profile email offline_access";
            SSO_CLIENT_ID = cfg.oidcClientId;
          };
        };
      }
      (roleLib.mkRoleFirewall {
        inherit (cfg) openFirewall permittedSources;
        tcpPorts = [ cfg.port ];
      })
    ]
  );
}
