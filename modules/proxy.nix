{ config, lib, pkgs, ... }:

let
  domain = "allie.sh";

  forgejoHost = "git.netbird.allie.sh";
  netbirdHost = "host.netbird.allie.sh";
  haosHost = "haos.netbird.allie.sh";
in
{
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
    };
  };

  networking.firewall = {
    enable = true;
    allowedTCPPorts = [
      80
      443
    ];
  };

  environment.systemPackages = with pkgs; [
    caddy
  ];
}
