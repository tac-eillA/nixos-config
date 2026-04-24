{ config, lib, pkgs, ... }:

let
  domain = "allie.sh";

  forgejoHost = "10.254.1.75";
  netbirdHost = "10.254.1.170";
  haosHost = "10.254.1.251";
  authHost = "10.254.1.163";
in
{
  services.qemuGuest.enable = true;
  servuces.cloudflared.enable = true;
  services.caddy = {
    enable = true;

    # Optional, but useful for ACME / Let's Encrypt account notices.
    email = "email@allie.is";

    virtualHosts = {
      "git.${domain}" = {
        extraConfig = ''
          encode gzip zstd

          reverse_proxy http://${forgejoHost}:3000 {
            header_up X-Real-IP {remote_host}
            header_up X-Forwarded-Proto {scheme}
          }
        '';
      };

      "netbird.${domain}" = {
        extraConfig = ''
          encode gzip zstd

          reverse_proxy http://${netbirdHost}:80 {
            header_up X-Real-IP {remote_host}
            header_up X-Forwarded-Proto {scheme}
          }
        '';
      };

      "haos.${domain}" = {
        extraConfig = ''
          encode gzip zstd

          reverse_proxy http://${haosHost}:8123 {
            header_up X-Real-IP {remote_host}
            header_up X-Forwarded-Proto {scheme}
          }
        '';
      };

      "auth.${domain}" = {
        extraConfig = ''
          encode gzip zstd

          reverse_proxy http://${authHost}:9000 {
            header_up X-Real-IP {remote_host}
            header_up X-Forwarded-Proto {scheme}
          }
        '';
      };
    };
  };

  networking.firewall = {
    enable = true;
    allowedTCPPorts = [
      443
    ];
  };

  environment.systemPackages = with pkgs; [
    caddy
    cloudflared
  ];
}
