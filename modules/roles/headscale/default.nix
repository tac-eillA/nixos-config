{ config, lib, pkgs, ... }:

let
  cfg = config.scylla.roles.headscale;
  oidcClientSecretFile = config.sops.secrets."headscale/authentik-client-secret".path;
in
{
  options.scylla.roles.headscale = {
    enable = lib.mkEnableOption "the Headscale workload";

    domain = lib.mkOption {
      type = lib.types.nonEmptyStr;
      default = "headscale.allie.sh";
      description = "Public Headscale domain.";
    };

    listenAddress = lib.mkOption {
      type = lib.types.nonEmptyStr;
      default = "0.0.0.0";
      description = "Address on which the Headscale reverse proxy listens.";
    };

    port = lib.mkOption {
      type = lib.types.port;
      default = 80;
      description = "Public reverse-proxy port.";
    };

    backendAddress = lib.mkOption {
      type = lib.types.nonEmptyStr;
      default = "127.0.0.1";
      description = "Address on which Headscale itself listens.";
    };

    backendPort = lib.mkOption {
      type = lib.types.port;
      default = 8080;
      description = "Internal Headscale HTTP port.";
    };

    tailnetDomain = lib.mkOption {
      type = lib.types.nonEmptyStr;
      default = "tailnet.allie.sh";
      description = "MagicDNS base domain.";
    };

    oidcIssuer = lib.mkOption {
      type = lib.types.nonEmptyStr;
      default = "https://auth.allie.sh/application/o/headscale/";
      description = "OIDC issuer URL.";
    };

    oidcClientId = lib.mkOption {
      type = lib.types.nonEmptyStr;
      default = "headscale";
      description = "OIDC client identifier.";
    };

    installAdminPackages = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Whether to install the Headscale CLI globally.";
    };

    secretFile = lib.mkOption {
      type = lib.types.path;
      default = ../../../secrets/headscale.yaml;
      description = "SOPS file containing the Headscale OIDC client secret.";
    };
  };

  config = lib.mkIf cfg.enable {
    assertions = [
      {
        assertion = builtins.pathExists cfg.secretFile;
        message = "The Headscale role secret file does not exist.";
      }
      {
        assertion = cfg.backendAddress != cfg.listenAddress || cfg.backendPort != cfg.port;
        message = "Headscale's backend and public listener cannot use the same socket.";
      }
    ];

    sops.age = {
      keyFile = "/var/lib/sops-nix/age-key.txt";
      generateKey = false;
    };

    sops.secrets."headscale/authentik-client-secret" = {
      sopsFile = cfg.secretFile;
      owner = "headscale";
      group = "headscale";
      mode = "0400";
      restartUnits = [ "headscale.service" ];
    };

    services.headscale = {
      enable = true;
      address = cfg.backendAddress;
      port = cfg.backendPort;

      settings = {
        server_url = "https://${cfg.domain}";

        dns = {
          magic_dns = true;
          base_domain = cfg.tailnetDomain;
          override_local_dns = false;
        };

        oidc = {
          issuer = cfg.oidcIssuer;
          client_id = cfg.oidcClientId;
          client_secret_path = oidcClientSecretFile;
          pkce.enabled = true;
        };
      };
    };

    services.nginx = {
      enable = true;

      virtualHosts.${cfg.domain} = {
        listen = [
          {
            addr = cfg.listenAddress;
            port = cfg.port;
          }
        ];

        locations."/" = {
          proxyPass = "http://${cfg.backendAddress}:${toString cfg.backendPort}";
          proxyWebsockets = true;
          recommendedProxySettings = true;
          extraConfig = ''
            proxy_set_header X-Forwarded-Proto https;
          '';
        };
      };
    };

    environment.systemPackages = lib.optionals cfg.installAdminPackages [ pkgs.headscale ];
  };
}
