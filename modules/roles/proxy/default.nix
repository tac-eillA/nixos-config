{ config, lib, pkgs, ... }:

let
  cfg = config.scylla.roles.proxy;
  credentialsFile = config.sops.secrets."cloudflare/tunnel-credentials".path;
in
{
  options.scylla.roles.proxy = {
    enable = lib.mkEnableOption "the Cloudflare tunnel proxy workload";

    tunnelId = lib.mkOption {
      type = lib.types.nonEmptyStr;
      default = "8eaa3da2-b2ae-4cbf-86f0-73bda6de85bd";
      description = "Cloudflare tunnel identifier.";
    };

    ingress = lib.mkOption {
      type = lib.types.attrsOf lib.types.nonEmptyStr;
      default = { };
      example = {
        "git.example.com" = "http://10.0.0.10:3000";
      };
      description = "Map of public domains to Cloudflare tunnel service URLs.";
    };

    defaultService = lib.mkOption {
      type = lib.types.nonEmptyStr;
      default = "http_status:404";
      description = "Cloudflare tunnel fallback service.";
    };

    warpRouting = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Whether to enable Cloudflare WARP routing.";
    };

    installAdminPackages = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Whether to install cloudflared globally.";
    };

    secretFile = lib.mkOption {
      type = lib.types.path;
      default = ../../../secrets/proxy.yaml;
      description = "SOPS file containing the Cloudflare tunnel credentials.";
    };
  };

  config = lib.mkIf cfg.enable {
    assertions = [
      {
        assertion = builtins.pathExists cfg.secretFile;
        message = "The proxy role secret file does not exist.";
      }
      {
        assertion = cfg.ingress != { };
        message = "The proxy role requires at least one ingress route.";
      }
    ];

    sops.age = {
      keyFile = "/var/lib/sops-nix/age-key.txt";
      generateKey = false;
    };

    sops.secrets."cloudflare/tunnel-credentials" = {
      sopsFile = cfg.secretFile;
      owner = "cloudflared";
      group = "cloudflared";
      mode = "0400";
      restartUnits = [ "cloudflared-tunnel-${cfg.tunnelId}.service" ];
    };

    services.cloudflared = {
      enable = true;
      tunnels.${cfg.tunnelId} = {
        inherit credentialsFile;
        warp-routing.enabled = cfg.warpRouting;
        ingress = lib.mapAttrs (_: service: { inherit service; }) cfg.ingress;
        default = cfg.defaultService;
      };
    };

    environment.systemPackages = lib.optionals cfg.installAdminPackages [ pkgs.cloudflared ];
  };
}
