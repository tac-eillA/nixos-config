{ config, lib, pkgs, ... }:

let
  cfg = config.scylla.roles.proxy;
in
{
  options.scylla.roles.proxy = {
    enable = lib.mkEnableOption "the Caddy reverse proxy workload";

    ingress = lib.mkOption {
      type = lib.types.attrsOf lib.types.nonEmptyStr;
      default = { };
      example = {
        "git.example.com" = "http://forgejo:3000";
      };
      description = "Map of public domains to upstream URLs reachable over Tailscale.";
    };

    acmeEmail = lib.mkOption {
      type = lib.types.nullOr lib.types.nonEmptyStr;
      default = null;
      example = "admin@example.com";
      description = "Optional email address for Caddy's ACME account.";
    };

    installAdminPackages = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Whether to install the Caddy CLI globally.";
    };
  };

  config = lib.mkIf cfg.enable {
    assertions = [
      {
        assertion = cfg.ingress != { };
        message = "The proxy role requires at least one ingress route.";
      }
    ];

    services.caddy = {
      enable = true;
      email = cfg.acmeEmail;
      openFirewall = false;
      virtualHosts = lib.mapAttrs
        (_: upstream: {
          extraConfig = ''
            encode zstd gzip
            reverse_proxy ${upstream}
          '';
        })
        cfg.ingress;
    };

    systemd.services.caddy = {
      wants = [ "tailscaled.service" ];
      after = [ "tailscaled.service" ];
    };

    environment.systemPackages = lib.optionals cfg.installAdminPackages [ pkgs.caddy ];
  };
}
